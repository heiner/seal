#!/usr/bin/env ruby

require 'xml/parser'

module States

  class State
    def startElement( converter, name, attr )
    end
    def endElement( converter, name )
    end
    def character( converter, data )
    end
  end

  PreTextState = State.new
  class <<PreTextState

    def chordline?( line )
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

    def endElement( converter, name )
      if name == "pre"
        converter.buffer.slice!( 0 ) if converter.buffer[0] == ?\n
        converter.buffer.chomp!
        converter.buffer.gsub!( ' ', '~' )
        converter.buffer.gsub!('--','{-}{-}')
        converter.buffer.gsub!( '[', '{\\relax}[' )

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
      converter.buffer << data
    end
  end

  TabState = State.new
  class <<TabState
    
    def endElement( converter, name )
      if name == "pre"
        converter.buffer.rstrip!
        converter.buffer.slice!( 0 ) if converter.buffer[0] == ?\n
        converter.buffer.gsub!( '--', '{-}{-}' )
        converter.buffer.gsub!( ' ', '~' )
        converter.buffer.gsub!( "\t", '~'*8 )
        converter.buffer.gsub!( "\n", "\\\\\\*\n" )
        converter.out << converter.buffer << "\n" << '\\end{pre}'
        converter.buffer = ""
        converter.endState
      end
    end
    
    def character( converter, data )
      converter.buffer << data
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
      converter.out << data
    end
  end

  SongTitleState = State.new
  class <<SongTitleState
    def endElement( converter, name )
      if name == "h1"
        converter.out << converter.buffer.gsub('!', "\\protect\\excl{}")
        converter.out << '}{' << simplify( converter.buffer ) << "}"
        converter.buffer = ""
        converter.endState
      else
        raise Converter::Error
      end
    end

    def character( converter, data )
      converter.buffer << data
    end

    def simplify( title )
      title.downcase.gsub( /\\?[#&~]|\\ss/, '' )
    end
  end

  RootState = State.new
  class <<RootState
    def startElement( converter, name, attr )
      if name == "body"
        converter.newState( BodyState )
      end
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
        when 'tab'
          converter.out << '\\begin{pre}%' << "\n"
          converter.buffer = ""
          converter.newState( TabState )
        when 'verse', 'refrain', 'bridge', 'bridge2', 'bridge3', 'spoken'
          converter.out << '\\begin{' << classes[0] << '}\\begin{pre}%' << "\n"
          converter.out << '\\slshape' if classes[0] == 'spoken'
          converter.extra = '\\end{' + classes[0] + '}' + converter.extra
          converter.newState( PreTextState )
        when 'quote'
          converter.out << '\\begin{quote}\\begin{alltt}'
          converter.extra = '\\end{quote}' + converter.extra
          converter.newState( MiscPreState )
        when 'chords'
          converter.out << '\\begin{alltt}'
          converter.newState( MiscPreState )
        else
          raise Converter::Error, "unexpected pre attribute #{classes[0]}"          
        end
      end
    end
  end
  
  BodyState = State.new
  class <<BodyState

    include PreHandler

    def startElement( converter, name, attributes )
      case name
      when 'p'
        converter.out << "\n\n"
        converter.newState( TextState )
      when 'pre'
        handle_pre( converter, attributes )
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
      when 'hr'
        converter.out << "\n\\bobrule\n"
      when 'ul'
        converter.out << '\\begin{itemize}'
      when 'li'
        converter.out << '\\item '
        converter.newState( TextState )
      when 'div'
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
      when 'body'
        converter.endState
      end
    end

    def character( converter, data )
      converter.out << data
    end
  end

  TextState = State.new
  class <<TextState

    include PreHandler

    def startElement( converter, name, attr )
      case name
      when 'i', 'em', 'a'
        converter.out << '\\emph{'
      when 'b', 'strong'
        converter.out << '\\textbf{'
      when 'tt'
        converter.out << '\\texttt{'
      when 'br'
        converter.out << '\\\\'
      # when 'u', 'small', 'big', 'abbr'
      when 'pre'
        handle_pre( converter, attr )
      when 'img'
        image = attr[ 'src' ]
        url = File.join( 'graphics', File.basename( image ) )
        url = File.chopext( url )
        converter.out << "\\input{#{url}}"
      else
        raise Converter::Error, "unexpected tag <#{name}>"
      end
    end

    def endElement( converter, name )
      case name
      when 'p'
        #converter.out << "\n"
        converter.endState
      when 'li'
        converter.endState
      when 'h1', 'h2', 'h3', 'h4'
        converter.out << '}'
        converter.endState
      when 'i', 'em', 'a', 'b', 'strong', 'tt'
        converter.out << '}'
      when 'blockquote'
        converter.out << '\\end{quote}'
        converter.endState
      end
    end

    def character( converter, data )
      converter.out << data
    end

    def skippedEntity( converter, name )
      case name
      when 'Oslash'
        converter.out << '\\O'
      end
    end
  end

end


class Converter < XML::Parser

  class Error < RuntimeError
  end

  attr_accessor :out, :buffer, :extra

  def initialize
    reset
  end
  
  def reset( *args )
    super( *args )
    @out = nil
    @states = [States::RootState]
    @buffer = ""
    @extra = ""
  end

  def startElement( name, attr )
    @states.last.startElement( self, name, attr )
  end

  def endElement( name )
    @states.last.endElement( self, name )
  end

  def character( data )
    @states.last.character( self, data )
  end
  
  def skippedEntity( entityName, is_param_ent )
    #$stderr << entityName
    @states.last.skippedEntity( self, entityName )
  end

  def newState( state )
    @states.push( state )
  end

  def endState
    self.out << extra
    @extra = ""
    @states.pop
  end

  def convert( input )
    out << "%%% Converted by seal on #{Time.now}\n"
    parse( input )
  end

  #def externalEntityRef( context, base, systemId, publicId )
  #  extp = XML::Parser.new( self, context )
  #  extp.parse( open( 'xhtml-lat1.ent' ).read )
  #  extp.done
  #end
end

if __FILE__ == $0
  converter = Converter.new
  converter.out = $stdout
  #puts converter.setParamEntityParsing( 2 )

  begin
    converter.convert( $<.read )
  rescue XML::Parser::Error, Converter::Error
    print "#{$0}: #{$!} (in line #{converter.line})\n"
    exit 1
  end
end
