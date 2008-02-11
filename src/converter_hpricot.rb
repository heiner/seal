#!/usr/bin/env ruby

require 'hpricot'

module States

  class State
    def startElement( converter, name, attr )
    end
    def endElement( converter, name )
    end
    def character( converter, data )
    end
    def skippedEntity( converter, name )
    end
  end
  
  PreTextState = State.new
  class <<PreTextState

    def chordline?( line )
      line.rstrip!
      rate = 0
      rate += line.count(' ').to_f.quo(line.length)
      rate += line.count('~').to_f.quo(line.length)
      rate += 0.6 if line.length < 4
      rate += 0.2 if line.include?( '#' )
      rate += line.count('/')/4.0
      rate += line.count('.')/10.0
      rate += 0.1  if line.count('[') + line.count(']') >= 3
      rate >= 0.6
    end

    def endElement( converter, name )
      if name == "pre"
        converter.buffer.slice!( 0 ) if converter.buffer[0] == ?\n
        converter.buffer.chomp!

        converter.buffer.gsub!( '[', '{\\relax}[' )
        converter.buffer.gsub!( '$', '\\$' )
        converter.buffer.gsub!( '%', '\\%' )
        converter.buffer.gsub!( '_', '\\_' )
        converter.buffer.gsub!( '#', '\\#' )
        converter.buffer.gsub!( '^', '\\^' )
        converter.buffer.gsub!( ' ', '~' )
        converter.buffer.gsub!('--','{-}{-}')

        converter.buffer.each_line do |line|
          line.chomp!
          if line.empty?
            converter.out << "~\\\\\n"
          elsif chordline?( line )
            converter.out << line << "\\\\*\\relax\n"
          else
            converter.out << line << "\\\\ \\relax\n"
          end
        end

        converter.out << "\\end{pre}"
        converter.buffer = ""
        converter.endState
      end
    end

    def character( converter, data )
      data.gsub!( '\\', '{\\bs}' )
      data.gsub!( '~', '\\~{}' )
      converter.buffer << data
    end

    def to_s
      'PreTextState'
    end
  end

  TabState = State.new
  class <<TabState
    
    def endElement( converter, name )
      if name == "pre"
        converter.buffer.rstrip!
        converter.buffer.slice!( 0 ) while converter.buffer[0] == ?\n
        converter.buffer.gsub!( '~', '\\~{}' )
        converter.buffer.gsub!( '\\', '{\\bs}' )
        converter.buffer.gsub!( '$', '\\$' )
        converter.buffer.gsub!( '%', '\\%' )
        converter.buffer.gsub!( '_', '\\_' )
        converter.buffer.gsub!( '[', "{\\relax}[" )
        converter.buffer.gsub!( '#', '\\#' )
        converter.buffer.gsub!( '^', '\\^' )
        converter.buffer.gsub!( "\t", '~'*8 )
        converter.buffer.gsub!( '--', '{-}{-}' )
        converter.buffer.gsub!( ' ', '~' )
        converter.buffer.gsub!( "\n\n\n", "\\\\\\~\n" )
        converter.buffer.gsub!( "\n\n", "\\\\\\~\n" )
        converter.buffer.gsub!( "\n", "\\\\\\*\n" )
        converter.out << converter.buffer << "\n" << '\\end{pre}'
        converter.buffer = ""
        converter.endState
      end
    end
    
    def character( converter, data )
      converter.buffer << data
    end

    def to_s
      'TabState'
    end
  end

  MiscPreState = State.new
  class <<MiscPreState
    def endElement( converter, name )
      if name == "pre"
        converter.out << '\\end{alltt}'
        converter.endState
      end
    end

    def character( converter, data )
      data.gsub!( '~', '\\~{}' )
      data.gsub!( '\\', '{\\bs}' )
      data.gsub!( '$', '\\$' )
      data.gsub!( '%', '\\%' )
      data.gsub!( '_', '\\_' )
      data.gsub!( '[', "{\\relax}[" )
      data.gsub!( '#', '\\#' )
      data.gsub!( '^', '\\^' )
      data.gsub!( "\t", '~'*8 )
      converter.out << data
    end

    def to_s
      'MiscPreStates'
    end
  end

  SongTitleState = State.new
  class <<SongTitleState

    def endElement( converter, name )
      if name == "h1"
        simple = converter.buffer.downcase.gsub( /\\?[#&~]|\\ss/, '' )

        converter.buffer.gsub!( '#', '\\#' )
        converter.buffer.gsub!( '&', '\\\\&' )
        converter.title = converter.buffer

        converter.out << converter.buffer.gsub( '!', '\\protect\\excl{}' ) \
                      << '}{' << simple << "}"

        converter.buffer = ""
        converter.endState
      else
        raise Converter::Error
      end
    end

    def character( converter, data )
      converter.buffer << data
    end

    def to_s
      'SongTitleState'
    end
  end

  RootState = State.new
  class <<RootState
    def startElement( converter, name, attr )
      if name == 'body'
        converter.newState( BodyState )
      end
    end

    def endElement( converter, name )
      if name == 'html'
        converter.endState
      end
    end

    def to_s
      'RootState'
    end
  end

  module PreHandler
    def handle_pre( converter, attributes )
      if not attributes[ 'class' ]
        converter.out << '\\begin{alltt}'
        converter.newState( MiscPreState )
      else
        classes = attributes[ 'class' ].split
        if classes[1]
          converter.out << "\\begin{#{classes[1]}}"
          converter.extra = '\\end{' + classes[1] + '}' + converter.extra
          classes.delete_at( 1 )
        end

        case classes[0]
        when 'verse', 'refrain', 'bridge', 'bridge2', 'bridge3', 'spoken'
          converter.out << '\\begin{' << classes[0] << '}\\begin{pre}'
          converter.out << '\\slshape' if classes[0] == 'spoken'
          converter.out << "%\n"
          converter.extra = '\\end{' + classes[0] + '}' + converter.extra
          converter.newState( PreTextState )
        when 'tab'
          converter.out << '\\begin{pre}%' << "\n"
          converter.buffer = ""
          converter.newState( TabState )
        when 'chords'
          converter.out << '\\begin{alltt}'
          converter.newState( MiscPreState )
        when 'quote'
          converter.out << '\\begin{quote}\\begin{alltt}'
          converter.extra = '\\end{quote}' + converter.extra
          converter.newState( MiscPreState )
        else
          #raise Converter::Error, "unexpected pre attribute #{classes[0]}"          
        end
      end
    end
  end

  BodyState = State.new
  class <<BodyState

    include PreHandler

    def startElement( converter, name, attributes )
      case name
      when 'pre'
        handle_pre( converter, attributes )
      when 'p'
        converter.out << "\n\n"
        converter.newState( TextState )
      when 'hr'
        converter.out << "\n\\bobrule\n"
      when 'h1'
        if attributes[ 'class' ] == 'songtitle'
          converter.out << "\\songlbl{"
          converter.newState( SongTitleState )
        else
          converter.out << '\\section*{'
          converter.newState( TextState )
        end
      when 'h2'
        if attributes[ 'class' ] == 'songversion'
          converter.out << '\\songversion{'
        else
          converter.out << '\\subsection*{'
        end
        converter.newState( TextState )
      when 'h3', 'h4'
        converter.out << '\\subsubsection*{'
        converter.newState( TextState )
      when 'li'
        converter.out << '\\item '
        converter.newState( TextState )
      when 'ul'
        converter.out << '\\begin{itemize}'
      when 'div'
        converter.newState( BodyState )
      when 'blockquote'
        converter.out << '\\begin{quote}'
        converter.newState( TextState )
      else
        raise Converter::Error, "unexpected tag <#{name}>"
      end
    end

    def endElement( converter, name )
      case name
      when 'ul'
        converter.out << '\\end{itemize}'
      when 'div'
        converter.endState
      when 'body'
        converter.endState
      end
    end

    def character( converter, data )
      #converter.out << data.gsub( "\n", "%\n" )
    end

    def to_s
      'BodyState'
    end
  end

  TextState = State.new
  class <<TextState

    include PreHandler

    def startElement( converter, name, attr )
      case name
      when 'br'
        converter.out << '\\\\'
      when 'em', 'a', 'i'
        converter.out << '\\emph{'
      when 'b', 'strong'
        converter.out << '\\textbf{'
      when 'pre'
        handle_pre( converter, attr )
      when 'tt'
        converter.out << '\\texttt{'
      # when 'u', 'small', 'big', 'abbr'
      when 'div'
        converter.newState( TextState )
      when 'img'
        image = attr[ 'src' ]
        url = File.join( 'graphics', File.basename( image ) )
        url = url[0...url.rindex('.')]
        converter.out << "\\input{#{url}}"
      else
        raise Converter::Error, "unexpected tag <#{name}>"
      end
    end

    def endElement( converter, name )
      case name
      when 'p'
        converter.out << "\n\n"
        converter.endState
      when 'em', 'a', 'strong', 'b', 'tt', 'i'
        converter.out << '}'
      when 'li'
        converter.endState
      when 'h1', 'h2', 'h3', 'h4'
        converter.out << '}'
        converter.endState
      when 'div'
        converter.endState
      when 'blockquote'
        converter.out << '\\end{quote}'
        converter.endState
      end
    end

    REPLACEMENTS = [
                    [ '\\', '{\\bs}' ],
                    [ "\303\230", '{\\O}' ],

                    [ "\302\222", "'" ],       # &#146;
                    [ "\342\200\223", '--' ],  # &#8211;
                    [ "\342\200\224", '---' ], # &#8212;
                    [ "\342\200\234", '``' ],  # &#8220
                    [ "\342\200\235", "''" ],  # &#8221;

                    [ '~', '\\~{}' ], [ '$', '\\$'], [ '%', '\\%'],
                    [ '_', '\\_'],    [ '#', '\\#'], [ '^', '\\^'],
                    [ "\342\231\257", "$\\sharp$" ], # 0x266F == 9839 == `#'
                    [ "\342\231\255", "$\\flat$" ],  # 0x266D == 9837 == `b'
                    [ '&', '\\\\&' ],
                    [ ' - ', ' -- ' ],
                    [ '...', '\\ldots{}' ],
                    [ '. . .', '\\ldots{}' ],
                  # [ '.~.~.', '\\ldots{}' ],
                    [ /(^|\W)'((?:[^']|\w'\w)+)'(\W|\Z)/,
                      "\\1`{}\\2'{}\\3" ], # "
                    [ /"([^"]+)"/, "``{}\\1''{}" ], # "
                    [ /(\W[ACDFG])\\#(?=\W|m)/i, "\\1$\\sharp$" ],
                    [ /(\W[ABDFG])b(?=\W|m)/, "\\1$\\flat$" ]
                   ]
    def character( converter, data )
      REPLACEMENTS.each do |pattern, replacement|
        data.gsub!( pattern, replacement )
      end
      converter.out << data
    end

    def to_s
      'TextState'
    end
  end
end


class Converter

  class Error < RuntimeError
  end

  attr_accessor :out, :buffer, :extra, :title

  #def initialize
  #end
  
  def reset( *args )
    super( *args )
    unless @out.nil?
      @out.close
      @out = nil
    end
    @states = [States::RootState]
    @buffer = ""
    @extra = ""
    @title = nil
  end

  def startElement( name, attr )
    @states.last.startElement( self, name, attr )
  end

  def endElement( name )
    @states.last.endElement( self, name )
  end

  def character( data )
    data.gsub!( /&[A-Za-z];/ ) do |entity|
      case entity[1...-1]
      when 'Oslash' then '{\\O}'
      when 'rdquo' then '\'\''
      when 'ldquo' then '``'
      when 'ndash' then '--'
      when 'nbsp' then '~'
      when 'rsquo' then '\''
      when 'ntilde' then '\\~n'
      when 'uuml' then '\\"u'
      when 'eacute' then '\\\'e'
      when 'szlig' then '{\\ss}'
      when 'bull' then '$\\bullet$'
      when 'ouml' then '\\"o'
      when 'mdash' then '---'
      when 'auml' then '\\"a'
      when 'Aring' then '{\\AA}'
      when 'euml' then '\\"e'
      when 'egrave' then '\\`e'
      when 'hellip' then '\\ldots{}'
      when 'oacute' then '\\\'o'

      # rest doesn't occur
      when 'lsquo' then '`'
      when 'acirc' then '\\^a'
      when 'agrave' then '\\`a'
      when 'aacute' then '\\\'a'
      when 'ecirc' then '\\^e'
      when 'icirc' then '\\^i'
      when 'igrave' then '\\`i'
      when 'iacute' then '\\\'i'
      when 'iuml' then '\\"i'
      when 'ocirc' then '\\^o'
      when 'ograve' then '\\`o'
      when 'ucirc' then '\\^u'
      when 'ugrave' then '\\`u'
      when 'uacute' then '\\\'u'
      when 'ycirc' then '\\^y'
      when 'ygrave' then '\\`y'
      when 'yacute' then '\\\'y'
      when 'yuml' then '\\"y'
      when 'Acirc' then '\\^A'
      when 'Agrave' then '\\`A'
      when 'Aacute' then '\\\'A'
      when 'Auml' then '\\"A'
      when 'Ecirc' then '\\^E'
      when 'Egrave' then '\\`E'
      when 'Eacute' then '\\\'E'
      when 'Euml' then '\\"E'
      when 'Icirc' then '\\^I'
      when 'Igrave' then '\\`I'
      when 'Iacute' then '\\\'I'
      when 'Iuml' then '\\"I'
      when 'Ocirc' then '\\^O'
      when 'Ograve' then '\\`O'
      when 'Oacute' then '\\\'O'
      when 'Ouml' then '\\"O'
      when 'Ucirc' then '\\^U'
      when 'Ugrave' then '\\`U'
      when 'Uacute' then '\\\'U'
      when 'Uuml' then '\\"U'
      when 'Ycirc' then '\\^Y'
      when 'Ygrave' then '\\`Y'
      when 'Yacute' then '\\\'Y'
      when 'Yuml' then '\\"Y'
      when 'atilde' then '\\~a'
      when 'otilde' then '\\~o'
      when 'Atilde' then '\\~A'
      when 'Ntilde' then '\\~N'
      when 'Otilde' then '\\~O'
      when 'oslash' then '{\\o}'
      when 'aring' then '{\\aa}'
      when 'aelig' then '{\\ae}'
      when 'AElig' then '{\\AE}'
      when 'ccedil' then '{\\c c}'
      when 'Ccedil' then '{\\c C}'
      else
        Seal::err << "Unkown entity #{name}"
      end
    end
    @states.last.character( self, data )
  end

  def newState( state )
    @states.push( state )
  end

  def endState
    self.out << extra
    @extra = ""
    @states.pop
  end

  def convert( filename )
    @out << "%%% Converted by seal on #{Time.now}\n"
    begin
      doc = Hpricot.parse( File.read( filename ) )
      traverse( doc )
    rescue Hpricot::Error => e
      puts e
      exit 1
    end
  end

  def finished?
    @states.empty?
  end

  private

  def traverse( elem )
    elem.each_child do |child|
      if child.elem?
        startElement( child.name, child.attributes )
        traverse( child )
        endElement( child.name )
      elsif child.text?
        character( child.to_s )
      else
        p child
      end
    end
  end

end

if __FILE__ == $0

  def File::chopext( path )
    path[0...path.rindex('.')]
  end
  
  converter = Converter.new

  require 'yaml'
  residence = File.dirname(__FILE__)
  songshash = YAML.load_file( File.join( residence, '../data', 'songs.yaml' ) )

  counter = 0
  dircount = 0

  $stdout.sync = true
  
  songshash.each_pair do |dir, songs|
    dircount += 1
    print "%2i" % dircount
    songs.each do |song|
      converter.reset
      if not dir && song
        print " "
        next
      end
      next if song.include?( "@" ) or song.include?( "/" )
      if dir.include?( "#" )
        dir = dir.split( '#' )[0]
      end
      song.sub!( '*', '' )
      counter += 1
      begin
        input = '/home/heiner/tmp/dylanchords/' + dir + "/" + song
        $stdout << '.'
        converter.out = open( "/tmp/" + song + '.tex', 'w' )
        begin
          converter.convert( input )
        rescue XML::Parser::Error
          print "#{$0}: #{$!} (in line #{converter.line}, file #{song})\n"
          exit 1
        end
      rescue Errno::ENOENT => e
        puts e
        print 'x'
      end
    end
    print "\n"
  end

  puts counter
end
