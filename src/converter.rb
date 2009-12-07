
begin
  require 'hpricot'
rescue LoadError
  begin
    require 'rubygems' and retry
  rescue LoadError
  end

  puts "You need the Hpricot library to run seal-convert."
  puts "Get it at http://code.whytheluckystiff.net/hpricot/"
  exit( 1 )
end

if not Hpricot::Elem.method_defined?( :inner_text )
  # Hpricot 0.4, which is included in the One-Click installler for
  # Windows, doesn't seem to have inner_text. Code taken from
  # http://merb.devjavu.com/browser/apps/merki/trunk/framework/merb/test/hpricot.rb?rev=939
  class Hpricot::Elem
    # courtesy of 'thomas' from the comments
    # of _whys blog - get in touch if you want a better credit!
    def inner_text
      self.children.collect do |child|
        child.is_a?(Hpricot::Text) ? child.content : ((child.respond_to?("inner_text") && child.inner_text) || "")
      end.join.strip
    end
  end
end

class Converter

  class Error < StandardError
  end

  attr_reader :song_title
  
  def initialize( seal )
    @seal = seal
    
    @out = nil
    @song_title = nil
  end

  def convert( in_stream, out_stream )
    @seal.current_input_path = in_stream.path
    @seal.current_input = File.basename( @seal.current_input_path )
    
    data = in_stream.read
    @out = out_stream

    @song_title = nil

    # Yes, we do that now!
    data.gsub!( "\\", "\\textbackslash{}" )
    data.gsub!( /([~$%_^])/, '\\\\\1{}' )
    entities_to_TeX( data )
    data.gsub!( /([&#])/, '\\\\\1' )

    doc = Hpricot( data )

    begin
      if not block_given?
        body( doc.at( "body" ) )
      else
        yield doc
      end
    rescue Converter::Error => e
      if $DEBUG
        raise
      else
        @seal.err << e
      end
    end
  end

  def body( element )
    element.each_child do |child|
      if child.elem?
        case child.name
        when 'pre'
          pre( child )
        when 'p'
          @out << "\n\n"
          text( child )
          @out << "\n\n"
        when 'hr'
          @out << "\n\\bobrule\n"
        when 'h1'
          if child.classes.include?( 'songtitle' )
            # We assume this <h1> contains no further elements
            child.each_child { |c| raise Converter::Error if c.elem? }
            #puts child.methods.sort
            @song_title = child.inner_text
            simple = @song_title.downcase.gsub( /\\?[#&~]|\\ss/, '' )
            @out << "\\songlbl{" << @song_title.gsub( '!', "\\textexclaim{}" ) \
                                 << "}{" << simple << "}"
          else
            @out << "\\section*{"
            text( child )
            @out << '}'
          end
        when 'h2'
          if child.classes.include?( 'songversion' )
            @out << "\\songversion{"
          else
            @out << "\\subsection*{"
          end
          text( child )
          @out << '}'
        when 'h3', 'h4'
          @out << "\\subsubsection*{"
          text( child )
          @out << '}'
        when 'a' # anchor for internal links
          if child.has_attribute?( 'name' )
            name = child.attributes[ 'name' ]
            if name[1] == ?#
              name.slice!( 0 ) # Remove the \ we inserted there
              @seal.err << "\n#{@seal.current_input_path}: illegal anchor " \
                           "name \"#{name}\" (shouldn't start with an #)"
              name.slice!( 0 )
            end
            @out << "\\label{anchor:#{@seal.current_input}:#{name}}"
          end
        when 'ul'
          @out << "\\begin{itemize}"
          child.each_child do |item|
            if item.elem?
              raise Converter::Error if item.name != 'li'
              @out << "\\item "
              text( item )
            end # ignore text and comments
          end
          @out << "\\end{itemize}"
	when 'ol'
	  @out << "\\begin{enumerate}"
          child.each_child do |item|
            if item.elem?
              raise Converter::Error if item.name != 'li'
              @out << "\\item "
              text( item )
            end # ignore text and comments
          end
          @out << "\\end{enumerate}"
        when 'div'
          body( child )
        when 'blockquote'
          @out << "\\begin{quote}"
          text( child )
          @out << "\\end{quote}"
        when 'img'
          image = child.attributes['src']
          @seal.err << "\nIgnored image at #{image}"
        when 'script' # we totally ignore this one
        else
          raise Converter::Error, "unknown tag <#{child.name}> in #{@seal.current_input_path}"
        end
        #elsif child.text?
        #  text = child.to_html
        #  if text =~ /\S/
        #    puts "Text in <body> tag in #{@seal.current_input_path}: #{text.dump}"
        #  end
      end # ignore comments
    end
  end

  def text( element )
    element.each_child do |child|
      if child.elem?
        case child.name
        when 'br'
          @out << "\\\\"
        when 'a'
          case child.attributes['class']
          # We assume <a> tags have no child elements
          when 'recordlink'
            record = child.inner_html
            #simple = record.upcase.gsub( "\\&", '' )
            #@out << "\\textit{#{record}} (p \\pageref{album:#{simple}})"
            @out << "\\textit{#{record}}"
          when 'songlink'
            song = child.inner_html
            simple = song.downcase.gsub( /\\?[#&~]|\\ss/, '' )
            @out << "\\textit{#{song}}"
          when 'url'
            @out << "\\emph{"
            text( child )
            @out << "}"
          else
            #if child.classes.empty?
            #  href = child.attributes['href'] || ""
            #  puts "<a> without CSS, href=#{href.gsub('\\_{}', '_')} for #{@out.path}"
            #end
            @out << "\\emph{"
            text( child )
            @out << "}"
          end
        when 'em' # ,  'i'
          @out << "\\emph{"
          text( child )
          @out << "}"
        when 'i'
          @out << "\\textit{"
          text( child )
          @out << "}"
        when 'b', 'strong'
          @out << "\\textbf{"
          text( child )
          @out << "}"
        when 'pre'
          pre( child )
        when 'tt'
          @out << "\\texttt{"
          text( child )
          @out << "}"
        # when 'u', 'small', 'big', 'abbr'
        when 'div'
          text( child )
        when 'img'
          image = child.attributes['src']
          url = File.join( 'graphics', File.basename( image ) )
          url = url[0...url.rindex('.')]
          @out << "\\input{#{url}}"
        when 'script' # we totally ignore this one
        else
          raise Converter::Error, "unknown tag <#{child.name}> in " \
                                  "#{@seal.current_input_path}"
        end

      elsif child.text?
        # using to_html to preserve entities
        text = child.to_html
        text.gsub!( ' - ', ' -- ' )
        text.gsub!( /\.\.\.|\. \. \./, '\\ldots{}' )
        # text.gsub!( '.~.~.', '\\ldots{}' )
        text.gsub!( /\b([ACDFG])\\#(?=\W|m|\d)/i, "\\1$\\sharp$" )
        text.gsub!( /(\b[ABDFG])b(?=\W|m)/, "\\1$\\flat$" )

        @out << text
      end
    end
  end

  def pre( element )
    classes = element.classes

    if classes.empty?
      pre_misc( element )
    else
      if classes[1]
        @out << "\\begin{#{classes[1]}}"
        extra = "\\end{#{classes[1]}}"
      end

      case classes[0]
      when 'verse', 'refrain', 'bridge', 'bridge2', 'bridge3', 'spoken'
        @out << "\\begin{#{classes[0]}}\n\\begin{pre}"
        @out << '\\slshape' if classes[0] == 'spoken'
        @out << "%\n"
        pre_text( element )
        @out << "\\end{pre}\n\\end{#{classes[0]}}"
      when 'tab'
        pre_tab( element )
      when 'chords'
        pre_misc( element )
      when 'quote'
        @out << "\\begin{quote}"
        pre_misc( element )
        @out << "\\end{quote}"
      else
        raise Converter::Error, "unknown pre CSS class #{classes[0]}"
      end

      @out << extra
    end
  end

  protected
  
  def pre_misc( element )
    @out << "\\begin{alltt}"
    text = read_text( element )
    text.gsub!( '[', "{\\relax}[" )
    text.gsub!( "\t", ' '*8 )
    @out << text << "\\end{alltt}"
  end

  CHORDLINE_REGEX =
    %r{ ^                      # Beginning
        [~.]*                  # any number of spaces or dots
        (?:                    # optionally: 
          (?: \|[:*]? | \[ )   # "|" or "|:" or "|*" or "["
          [~.]*                # followed by any number of spaces or dots
        )?
        [("]?[A-G][")]?        # a key (optionally with decoration)
        (?: b | \# )?          # optionally a flat or sharp, like C#, Ab
        m?                     # minor key, like Am
        (?: maj | add | sus | dim | o )?
        (?:\d\d?)?             # like Fmaj7,  Dm7, D11
        (?: /[a-gB][b#]? )?    # like C/g or Am/f# or C/Bb (!)
        '?                     # like Dm'
        # Now: Exclude lines like "A~lot~of~ ..." or "A~~~~~handle~hid ..."
        #      but not "D~~~~~~~~Riff~3"
        (?! [-~]{1,5}[a-zH-QS-Z] )

        (?: [^\w'] | $ )        # don't match "And~watch~...", "Go~'way~..."
                                # but match "~~~~~Am"
      }x
  def pre_text( element )
    text = read_text( element )

    text.slice!( 0 ) if text[0] == ?\n
    text.chomp!

    text.gsub!( ' ', '~' )
    text.gsub!( '--','{-}{-}' )

    text.each_line do |line|
      line.chomp!
      if line.empty?
        # the \relax after the \\ is to have the \\
        # not complain about brackets [] on the next line
        @out << "~\\\\ \\relax\n"
      elsif line =~ CHORDLINE_REGEX  or
            line =~ %r{^ [~.]* \(? /[a-gB]}x or
            line =~ /^\W*$/          or
            line =~ /^ ~+ [*0-9x]/x  or
            line =~ /[^a].\briff\b/i or
            line =~ /-\}\{-\}\{?-/   or
            line =~ /n\.c\./
        @out << line << "\\\\*\\relax\n"
      else
        @out << line << "\\\\ \\relax\n"
      end
    end
  end

  def pre_tab( element )
    @out << "\\begin{pre}%\n"

    tab = read_text( element )

    tab.rstrip!
    tab.slice!( 0 ) while tab[0] == ?\n
    tab.gsub!( '[', "{\\relax}[" )
    tab.gsub!( "\t", '~'*8 )
    tab.gsub!( '--', '{-}{-}' )
    tab.gsub!( ' ', '~' )

    tab.gsub!( "\n\n\n", "\n\n" ) # for a_change_is_gonna_come

    # For String#(g)sub(!), \\\\\\ (six backslashes) is the smallest code
    # that produces \\ as output. See
    # http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-core/11037
    tab.gsub!( "\n\n", "\\\\\\*[\\baselineskip]" )
    tab.gsub!( "\n",   "\\\\\\*\n" )
    @out << tab << "\n\\end{pre}"
  end

  # For the pre_* methods
  def read_text( element )
    result = ""

    element.each_child do |child|
      if child.text?
        result << child.to_s
      elsif child.elem?
        case child.name
        when 'span'
          child.classes.each do |c|
            case c
            when 'red'
              result << "\\textcolor{red}{" << read_text( child ) << "}"
            when 'spoken'
              result << "\\textsl{"         << read_text( child ) << "}"
            else
              result << "{" << read_text( child ) << "}"
            end
          end
        when 'em'
          result << "\\emph{"   << read_text( child ) << "}"
        when 'strong'
          result << "\\textbf{" << read_text( child ) << "}"
        end
      else
        # write out
      end
    end

    result
  end

  def entities_to_TeX( text )
    text.gsub!( /&\#?\w+;/ ) do |entity|
      case entity[1...-1]

      when 'Oslash' then '\\O{}'
      when 'quot'   then '"'
      when 'ldquo', '#8220' then '``'
      when 'rdquo', '#8221' then "''"
      when 'ndash', '#8211' then '--'
      when 'nbsp' then '~'
      when 'lsquo',  '#8216' then '`'
      when 'rsquo', '#146', '#8217' then "'"
      when 'ntilde' then '\\~n'
      when 'uuml' then '\\"u'
      when 'eacute' then '\\\'e'
      when 'szlig' then '\\ss{}'
      when 'bull' then '$\\bullet$'
      when 'ouml' then '\\"o'
      when 'mdash', '#8212' then '---'
      when 'auml' then '\\"a'
      when 'Aring' then '\\AA{}'
      when 'euml' then '\\"e'
      when 'egrave' then '\\`e'
      when 'hellip' then '\\ldots{}'
      when 'oacute' then '\\\'o'
      when 'amp'    then '&' # escaped later
      when 'lt'     then '\\lt{}'
      when 'gt'     then '\\gt{}'

      # rest doesn't occur (yet)
#       when 'acirc' then '\\^a'
#       when 'agrave' then '\\`a'
#       when 'aacute' then '\\\'a'
#       when 'ecirc' then '\\^e'
#       when 'icirc' then '\\^i'
#       when 'igrave' then '\\`i'
#       when 'iacute' then '\\\'i'
#       when 'iuml' then '\\"i'
#       when 'ocirc' then '\\^o'
#       when 'ograve' then '\\`o'
#       when 'ucirc' then '\\^u'
#       when 'ugrave' then '\\`u'
#       when 'uacute' then '\\\'u'
#       when 'ycirc' then '\\^y'
#       when 'ygrave' then '\\`y'
#       when 'yacute' then '\\\'y'
#       when 'yuml' then '\\"y'
#       when 'Acirc' then '\\^A'
#       when 'Agrave' then '\\`A'
#       when 'Aacute' then '\\\'A'
#       when 'Auml' then '\\"A'
#       when 'Ecirc' then '\\^E'
#       when 'Egrave' then '\\`E'
#       when 'Eacute' then '\\\'E'
#       when 'Euml' then '\\"E'
#       when 'Icirc' then '\\^I'
#       when 'Igrave' then '\\`I'
#       when 'Iacute' then '\\\'I'
#       when 'Iuml' then '\\"I'
#       when 'Ocirc' then '\\^O'
#       when 'Ograve' then '\\`O'
#       when 'Oacute' then '\\\'O'
       when 'Ouml' then '\\"O'
#       when 'Ucirc' then '\\^U'
#       when 'Ugrave' then '\\`U'
#       when 'Uacute' then '\\\'U'
#       when 'Uuml' then '\\"U'
#       when 'Ycirc' then '\\^Y'
#       when 'Ygrave' then '\\`Y'
#       when 'Yacute' then '\\\'Y'
#       when 'Yuml' then '\\"Y'
#       when 'atilde' then '\\~a'
#       when 'otilde' then '\\~o'
#       when 'Atilde' then '\\~A'
#       when 'Ntilde' then '\\~N'
#       when 'Otilde' then '\\~O'
#       when 'oslash' then '{\\o}'
#       when 'aring' then '{\\aa}'
#       when 'aelig' then '{\\ae}'
#       when 'AElig' then '{\\AE}'
#       when 'ccedil' then '{\\c c}'
#       when 'Ccedil' then '{\\c C}'
      else
        @seal.err << "Unknown entity #{entity} in #{@seal.current_input_path}. Ignored.\n"
        return ''
      end
    end
  end

end


if $0 == __FILE__
  require 'test/unit'

  class Converter::Tests < Test::Unit::TestCase
    require 'ostruct'
    require 'stringio'

    def setup
      @seal = OpenStruct.new
      @converter = Converter.new( @seal )
    end

    def test_simple_html
      istream = StringIO.new( "<html><body><p>Test #1</p></body></html>" )

      StringIO.open do |ostream|
        @converter.convert( istream, ostream )
        assert_equal( "\n\nTest \\#1\n\n", ostream.string )
      end
    end

  end
end
