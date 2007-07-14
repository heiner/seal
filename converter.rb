#!/usr/bin/env ruby

require 'xml/parser'

class State
  def startElement( converter, name, attr )
  end
  def endElement( converter, name )
  end
  def character( converter, data )
  end
end

class RootState < State
  def startElement( converter, name, attr )
    if name == "body"
      converter.newState( BodyState.new )
    end
  end
end

class BodyState < State
  def startElement( converter, name, attributes )
    case name
    when 'p'
      converter.out << "\n\n"
      converter.newState( TextState.new )
    when 'pre'
      case attributes[ 'class' ]
      when /\btab\b/
        converter.out << '\\begin{pre}%' << "\n"
        converter.buffer = ""
        converter.newState( TabState.new )
      when /\bverse\b/
        converter.out << '\\begin{pre}%' << "\n"
        converter.buffer = "verse"
        converter.newState( PreState.new )
      else
        converter.newState( PreState.new )
      end
    when 'h1'
      converter.out << '\\section*{'
      converter.newState( TextState.new )
    end
  end

  def endElement( converter, name )
    case name
    when 'body'
      converter.endState
    end
  end

  def character( converter, data )
    converter.out << data
  end

end

class TextState < State
  def startElement( converter, name, attr )
    case name
    when 'i', 'em', 'a'
      converter.out << '\\emph{'
    when 'br'
      converter.out << '\\\\'
    end
  end

  def endElement( converter, name )
    case name
    when 'p'
      #converter.out << "\n"
      converter.endState
    when 'h1'
      converter.out << '}'
      converter.endState
    when 'i', 'em', 'a'
      converter.out << '}'
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

class PreState < State
  def endElement( converter, name )
    if name == "pre"
      converter.endState
    end
  end

  def character( converter, data )
    converter.out << ":" << data
  end
end

class TabState < State

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

class Converter < XML::Parser

  attr_accessor :out, :buffer

  def initialize
    reset
  end
  
  def reset( *args )
    super( *args )
    @out = nil
    @states = [RootState.new]
    @buffer = ""
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
    @buffer = ""
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

converter = Converter.new
converter.out = $stdout
puts converter.setParamEntityParsing( 2 )

begin
  converter.convert( $<.read )
rescue XML::ParserError
  print "#{$0}: #{$!} (in line #{parser.line})\n"
  exit 1
end
