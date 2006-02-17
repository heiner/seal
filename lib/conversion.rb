
require 'rexml/document'

def File::chopext( path )
  path[0...path.rindex('.')]
end

module Converting

  attr_accessor :quiet
  
  class ConversionError < RuntimeError
  end

  include REXML

  def convert( istream, ostream )
    @istream, @ostream = istream, ostream

    self << "% Converted by seal on #{Time.now}\n\n"
    document = get_document
    document.root.elements[ 'body' ].elements.each do |tag|
      # thus we're ignoring any non-tag directly in <body>
      next_tag( tag )
    end
  end

  def convert_file( src, dest_dir )
    src_ext  = File::extname( src )
    basename = File::basename( src, src_ext )
    dest = File::join( dest_dir, basename + '.tex' )

    unless quiet
      $stdout << "Convert #{Converting::nicepath(src)} ... "
    end
    begin
      # maybe we want a zip file?
      ifile = File::new( src,  'r' )
      ofile = File::new( dest, 'w' )
      convert( ifile, ofile )
    ensure
      ifile.close unless ifile.nil?
      ofile.close unless ofile.nil?
    end
    $stdout << "done\n" unless quiet
  end

  def write( string )
    @ostream << Converting::texify( string )
    self
  end

  def write_raw( string )
    @ostream << string
    self
  end
  alias :<< :write_raw

  def next_tag( tag )
    case tag.name
    when 'h1'
      self << "\\section*{" << convert_paragraph( tag ) << "}\n"
    when 'h2'
      self << "\\subsection*{" << convert_paragraph( tag ) << "}\n"
    when 'h3', 'h4'
      self << "\\subsubsection*{" << convert_paragraph( tag ) << "}\n"
    when 'p'
      self << "\n" << convert_paragraph( tag ) << "\n"
    when 'hr'
      self << "\n\\bobrule\n\n"
    when 'pre'
      self << convert_preformatted( tag )
    when 'ul'
      self << "\\begin{itemize}\n"

      tag.each do |child|
        if child.node_type == :text
          write( child.value )
        elsif child.node_type == :comment
          self << "% Skipping comment\n"
        elsif child.name == 'li'
          self << "\\item " << convert_paragraph( child )
        else
          raise ConversionError, "Unexpected <#{tag.name}> in <ul>"
        end
      end
      self << "\\end{itemize}\n"

    when 'div'
      tag.each do |child|
        case child.node_type
        when :text
          write( child.value )
          next
        when :comment
          self << "% Skipping comment\n"
          next
        else
          next_tag( child )
        end
      end
    when 'blockquote'
      self << "\\begin{quote}\n"
      tag.each do |child|
        if child.node_type == :text
          write( child.value )
        elsif child.node_type == :comment
          self << "% Skipping comment\n"
        else
          self << convert_paragraph( child )
        end
      end
      self << "\\end{quote}\n"
    else
      raise ConversionError, "Unexpected tag <#{tag.name}>"
    end
  end

  protected

  def get_document
    begin
      doc = Document.new( @istream, {:raw => :all} )
    rescue ParseException
      raise ConversionError, "<#{@istream}> not valid XML"
    end
    return doc
  end

  private

  def convert_paragraph( tag )
    ostring = ""
    tag.each do |child|
      case child.node_type
      when :text
        ostring << Converting::texify( child.value )
        next
      when :comment
        ostring << "% Skipping comment\n"
        next
      end

      case child.name
      when 'br'
        ostring << "\\\\"
      when 'a'
        if child.attributes['class'] == 'recordlink'
          ostring << '\\emph{' << Converting::texify(child.text) << '}'
        else
          # unhandled link
          ostring << Converting::texify( child.text )
        end
      when 'i', 'em'
        ostring << '\\emph{' << Converting::texify(child.text) << '}'
      when 'b', 'strong'
        ostring << '\\textbf{' << Converting::texify( child.text ) << '}'
      when 'pre'
        ostring << convert_preformatted( child )
      when 'img'
        image = child.attributes['src']
        url_pdf = File::join( 'graphics', File::basename( image ) )
        url_ps  = File::chopext( url_pdf ) + '.eps'
        ostring << "\\image{#{url_pdf}}{#{url_ps}}"
      else
        raise ConversionError, "Unexpected tag #{child.name}"
      end
    end
    return ostring
  end

  # Helper method for convert_preformatted
  def flatten( tag )
    if tag.node_type == :text
      return Converting::texify( tag.value, false )
    end

    flat_children = ""
    tag.each_child { |child| flat_children += flatten( child ) }
      
    case tag.name
    when 'b', 'strong'
      # es gibt kein boldface cmtt!
      '\\textbf{' + flat_children.strip + '}'
    when 'em', 'i'
      '\\textsl{' + flat_children.strip + '}'
    when 'br'
      "\\\\"
    else
      flat_children
    end
  end

  def convert_preformatted( pre_tag )
    # We get called with a <pre> tag that could have
    # one of these CSS classes:
    # refrain, bridge, bridge2, 'bridge3, verse,
    # spoken, or chords (or more?)

    # However, this <pre> tag can have children, too.
    # We gotta `flatten' them.
    content = flatten( pre_tag )
    ostring = ""

    case pre_tag.attributes[ 'class' ]
    when 'refrain', 'bridge', 'bridge2', 'bridge3', 'verse', 'spoken'
      # lyric with or without tabs
      ostring << "\\begin{#{pre_tag.attributes['class']}}" \
              << "\\begin{pre}"
      if pre_tag.attributes['class'] == 'spoken'
        ostring << "\\slshape"
      end
      ostring << "%\n"

      content.lstrip!
      content.chomp!
      content.gsub!( ' ', '~' )
      content.gsub!( "[", "{\\relax}[" )

      content.each_line do |line|
        line.chomp!
        if line.empty?
          ostring << "~\\\\\n"
        elsif Converting::chordline?( line )
          ostring << line << "\\\\*\\relax\n"
        else
          ostring << line << "\\\\ \\relax\n"
        end
      end
      
      ostring << "\\end{pre}\\end{#{pre_tag.attributes['class']}}"

    when 'tab'
      # a tab with all the numbers and dashes
      ostring << "\n\\begin{pre}%\n"

      content.strip!
      content.gsub!('--','{-}{-}')  #.split( "\n" )
      content.gsub!(' ', '~')
      content.gsub!( "\t", '~'*8 )
      if content.include?( "\n\n" )
        $stderr << "\nWARNING: empty line in tab.\nFile #{@istream.path}\n"
        content.gsub!( /\n\n+/, "\\end{pre}\\begin{pre}" )
      end
      content.gsub!( "\n", "\\\\\\*\n" ) # SIX backslashes needed

      ostring << content << "\n" << "\\end{pre}"
    when 'quote'
      ostring << "\\begin{quote}" << content << "\\end{quote}"
    else
      # no class, or class='chords'
      ostring << "\\begin{alltt}" << content.strip << "\\end{alltt}\n"
    end

    return ostring
  end

  def Converting::chordline?( line )
    line.rstrip!
    rate = 0
    rate += line.count(' ').quo(line.length)
    rate += line.count('~').quo(line.length)
    rate += 0.6 if line.length < 4
    rate += 0.2 if line.include?( '#' )
    rate += line.count('/')/4
    rate += line.count('.')/10
    rate += 0.1  if line.count('[') + line.count(']') >= 3
    rate >= 0.6
  end

  REPLACEMENTS = [
    # non-entity replacements
    [ '\\', '\\bs' ],
    #[ /^\[/, "{\\relax}[" ],
    #[ /\]\Z/, "{\\relax}]" ],
    [ "\303\230", '{\\O}' ],
    
    [ "\302\222", "'" ],       # &#146;
    [ "\342\200\223", '--' ],  # &#8211;
    [ "\342\200\224", '---' ], # &#8212;
    [ "\342\200\234", '``' ],  # &#8220
    [ "\342\200\235", "''" ],  # &#8221;

    [ '~', '\\~{}' ], [ '$', '\\$'], [ '%', '\\%'],
    [ '_', '\\_'],    [ '#', '\\#'], [ '^', '\\^'],

    # entities
    ['&ndash;', '--'], ['&nbsp;', '~'], ['&ldquo;', '``'], ['&rdquo;', "''"],
    ['&acirc;', '\\^a'], ['&agrave;', '\\`a'], ['&aacute;', "\\'a"],
    ['&auml;', '\\"a'], ['&ecirc;', '\\^e'], ['&egrave;', '\\`e'],
    ['&eacute;', "\\'e"], ['&euml;', '\\"e'], ['&icirc;', '\\^i'],
    ['&igrave;', '\\`i'], ['&iacute;', "\\'i"], ['&iuml;', '\\"i'],
    ['&ocirc;', '\\^o'], ['&ograve;', '\\`o'], ['&oacute;', "\\'o"],
    ['&ouml;', '\\"o'], ['&ucirc;', '\\^u'], ['&ugrave;', '\\`u'],
    ['&uacute;', "\\'u"], ['&uuml;', '\\"u'], ['&ycirc;', '\\^y'],
    ['&ygrave;', '\\`y'], ['&yacute;', "\\'y"], ['&yuml;', '\\"y'],
    ['&Acirc;', '\\^A'], ['&Agrave;', '\\`A'], ['&Aacute;', "\\'A"],
    ['&Auml;', '\\"A'], ['&Ecirc;', '\\^E'], ['&Egrave;', '\\`E'],
    ['&Eacute;', "\\'E"], ['&Euml;', '\\"E'], ['&Icirc;', '\\^I'],
    ['&Igrave;', '\\`I'], ['&Iacute;', "\\'I"], ['&Iuml;', '\\"I'],
    ['&Ocirc;', '\\^O'], ['&Ograve;', '\\`O'], ['&Oacute;', "\\'O"],
    ['&Ouml;', '\\"O'], ['&Ucirc;', '\\^U'], ['&Ugrave;', '\\`U'],
    ['&Uacute;', "\\'U"], ['&Uuml;', '\\"U'], ['&Ycirc;', '\\^Y'],
    ['&Ygrave;', '\\`Y'], ['&Yacute;', "\\'Y"], ['&Yuml;', '\\"Y'],
    ['&atilde;', '\\~a'], ['&ntilde;', '\\~n'], ['&otilde;', '\\~o'],
    ['&Atilde;', '\\~A'], ['&Ntilde;', '\\~N'], ['&Otilde;', '\\~O'],
    ['&oslash;', '{\\o}'], ['&Oslash;', '{\\O}'], ['&aring;', '{\\aa}'],
    ['&Aring;', '{\\AA}'], ['&aelig;', '{\\ae}'], ['&AElig;', '{\\AE}'],
    ['&szlig;', '{\\ss}'], ['&ccedil;', '{\\c c}'], ['&Ccedil;', '{\\c C}'],

    [ "\342\231\257", "$\\sharp$" ], # 0x266F == 9839 == `#'
    [ "\342\231\255", "$\\flat$" ],  # 0x266D == 9837 == `b'

    # special (don't know why, but four backslashes are required!)
    [ '&', '\\\\&' ]
  ]

  # Seperated, because we don't want this in <pre> tags
  TYPOGRAPHIC_CLEANUP = [ [ "\n", ' ' ],
                          [ ' - ', ' -- ' ],
                          [ '...', '\\ldots{}' ],
                          [ '. . .', '\\ldots{}' ],
                          [ /(^|\W)'((?:[^']|\w'\w)+)'(\W|\Z)/,
                            "\\1`{}\\2'{}\\3" ], # "
                          [ /"([^"]+)"/, "``{}\\1''{}" ], # "
                          [ /(\W[ACDFG])\\#(?=\W|m)/i, "\\1$\\sharp$" ],
                          [ /(\W[ABDFG])b(?=\W|m)/, "\\1$\\flat$" ]
                        ]
  
  def Converting::texify( string, cleanup=true )
    return "" if string.nil?
    list = REPLACEMENTS
    list += TYPOGRAPHIC_CLEANUP if cleanup
    
    list.each do |pattern, replacement|
      string.gsub!( pattern, replacement )
    end
    
    return string
  end

  def Converting::nicepath( path )
    # return something like 22_slowtrain/i_believe_in_you.tex
    dir, file = File::split( path )
    dir = File::basename( dir )
    File::join( dir, file )
  end
end


class SongConverter

  include Converting
  attr_reader :songtitle

  def next_tag( tag )
    case tag.name
    when 'h1'
      if not tag.attributes['class'] == 'songtitle'
        raise ConversionError, '<h1> tag without songtitle'
      end

      @songtitle = Converting::texify( tag.text )

      # makeindex doesn't allow '!', so we have to use \excl
      self << "\\songlbl{" << \
        @songtitle.gsub('!', "\\protect\\excl{}") << '}{' +
        SongConverter::simplify( @songtitle ) << "}\n"
    when 'h2'
      if tag.attributes['class'] == 'songversion'
        self << "\\songversion{" << convert_paragraph( tag ) << "}\n"
      else
        super( tag )
      end
    else
      super( tag )
    end
  end

  # No special characters in labels (i.e., no #, &, ~ or sharp s)
  def SongConverter::simplify( title )
    title.downcase.gsub( /\\?[#&~]|\\ss/,'' )
  end

  def SongConverter::song_type( path )
    case path[-1]
    when ?@
      :reference
    when ?*
      :outtake
    else
      :normal
    end
  end
end


class AlbumBuilder

  include Converting

  attr_reader :albumtitle

  def initialize( quiet=false )
    @quiet = true
    @songconverter = SongConverter.new
    @songconverter.quiet = quiet
  end

  def convert_album( index_html, destination, number, songs )
    @source = File::dirname( index_html )
    @destination = destination
    @number = number
    @songs = songs
    @songtitles = {}

    convert_file( index_html, destination )
  end

  protected

  def convert( istream, ostream )
    @istream, @ostream = istream, ostream

    @ostream << "% Converted by seal on #{Time.now}\n\n"

    doc = get_document

    title = doc.root.elements['head'].elements['title'].text
    if title =~ /(?:Bob Dylan:\s*)?(.*)\(\S+(?:, live)?\)/
      title = $1
    end
    title_latex = format_title( title.strip )

    release = XPath::first( doc, "//p[ @class='recdate' ]" )
    unless release.nil?
      release = format_release( release.texts )
    else
      release = "Various"
    end

    self << <<EOS
\\def\\thesong{}
\\cleardoublepage
\\def\\thealbum{#{@albumtitle}}
\\thispagestyle{album}
\\label{album:#{@number}}

\\begin{flushright}
\\scalebox{6}{\\Huge #{@number}}

\\vspace{5ex}
#{title_latex}

{\\footnotesize #{release}}

\\vspace{10ex}

\\begin{tabular}{rl}
EOS

    # @songs_tag = REXML::XPath::first( @document, "//div[ @id='songs' ]" )
    # (we could try to parse the index file by ourselves and find
    # out the songs, but we don't (Right now).)

    outtake = false
    @songs.each do |song|
      src = File::expand_path( File::join( @source, song ) )
      song_type = SongConverter::song_type( song )
      already_converted = @songtitles.has_key?( src )

      case song_type
      when :normal
        if already_converted
          $stderr << "WARNING: #{song} is multiply addressed!"
        else
          convert_song( song )
        end
      when :outtake
        if not outtake
          self << "&\\tabularnewline\n"
          outtake = true
        end
        if already_converted
          self << format_songentry( src, "\\referencearrow" )
        else
          convert_song( song.chop )
        end
      when :reference
        if already_converted
          self << format_songentry( src )
        else
          convert_song( song.chop, "\\referencearrow" )
        end
      end
    end
    self << "\\end{tabular}\n\\end{flushright}\n\n\\newpage"

    intro_tag = REXML::XPath::first( doc, "//div[ @id='intro' ]" )
    if not intro_tag.nil?
      self << "\\vspace*\\fill\n"
      next_tag( intro_tag ) # from module Converting, writes to self
    end

    self << "\\cleardoublepage\n"
    @songs.each do |song|
      path = File::join( File::basename( @destination ),
                         File::chopext( song ) )
      self << "\\input{#{path}}\n"
    end
  end

  def convert_song( song, prefix="" )
    src = File::join( @source, song )
    # we can't take simply @destination, because we have
    # paths like 17_basement/../00_misc/trail_of_the_buffalo.tex
    dest = File::dirname( File::join( @destination, song ) )
    @songconverter.convert_file( src, dest )
    title = @songconverter.songtitle
    ref = SongConverter::simplify( title )

    song_path = File::expand_path( src )
    @songtitles[ song_path ] = title
    self << format_songentry( song_path, prefix )
  end

  def format_songentry( song_path, prefix="" )
    title = @songtitles[ song_path ]
    ref = SongConverter::simplify( title )
    "#{prefix}\\pageref{song:#{ref}} & \\textsc{#{title}}\\tabularnewline\n"
  end

  def format_release( strings )
    string = strings.join.strip
    
    string.gsub!( /Jan(?!\w)/i, "January" )
    string.gsub!( /Feb(?!\w)/i, "February" )
    string.gsub!( /Mar(?!\w)/i, "March" )
    string.gsub!( /Apr(?!\w)/i, "April" )
    # May, June, July
    string.gsub!( /Aug(?!\w)/i, "August" )
    string.gsub!( /Sep[t]?(?!\w)/i, "September" )
    string.gsub!( /Oct?(?!\w)/i, "October" )
    string.gsub!( /Nov?(?!\w)/i, "November" )
    string.gsub!( /Dec?(?!\w)/i, "December" )

    string.gsub!( "-", "--" )
    string.gsub!( "&ndash;", "--" )

    string.gsub!( "&amp;", "\\\\&" )

    string.sub!( "\n", " --- " )
    string.sub!( /,\s* ---/, " ---" )

    string.sub!( /recorded/i, "Recorded" )
    string.sub!( /released/i, "Released" )

    string.gsub!( "\n", "\\\\\\" )
    string
  end

  def format_title( title )
    case title
    when "Freewheelin'"
      title_latex = "\\scalebox{1.5}{\\Huge The Freewheelin'}\n\n" \
        "\\vspace{1ex}\n\\scalebox{1.5}{\\Huge Bob Dylan}\n"
      title = "The Freewheelin' Bob Dylan"
    when "The Times They Are A-Changin'"
      title_latex = "\\scalebox{1.5}{\\Huge The Times}\n\n" \
        "\\vspace{1ex}\n\\scalebox{1.5}{\\Huge They Are A-Changin'}\n"
      title = "The Times The Are A-Changin'"
    when 'Live 1966'
      title_latex = "{\\Large Bootleg Series vol. 4: Live 1966}\n\n" \
        "\\vspace{1ex}\n{\\Huge The ``Royal Albert Hall'' Concert}\n"
      title = "Live 1966"
    when 'Bootleg Series vol. 5: Live 1975 (The Rolling Thunder Revue)'
      title_latex = "{\\Large Bootleg Series vol. 5: Live 1975}\n\n" \
        "\\vspace{1ex}\n{\\Huge The Rolling Thunder Revue}\n"
      title = "Live 1975"
    when 'Bootleg Series vol. 6: Live 1964 (The Philharmonic Hall)'
      title_latex = "{\\Large Bootleg Series vol. 6: Live 1964}\n\n" \
        "\\vspace{1ex}\n{\\Huge Concert at Philharmonic Hall}\n"
      title = "Live 1964"
    when 'Bootleg Series vol. 7: No Direction Home'
      title_latex = "{\\Large Bootleg Series vol. 7}\n\n" \
        "\\vspace{1ex}\n{\\Huge No Direction Home: The Soundtrack}\n"
      title = "No Direction Home"
    when 'Miscellaneous'
      title_latex = "\\scalebox{1.5}{\\Huge Miscellaneous}\n"
      title = 'Miscellaneous'
    else
      title.gsub!("&", "\\\\&")
      title.gsub!( /"([^"]*)"/, "``\\1''" ) # "

      title_latex = "\\scalebox{1.5}{\\Huge #{title}}\n"
    end

    @albumtitle = title
    return title_latex
  end
  
end
