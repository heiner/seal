#!/usr/bin/env ruby

require 'hpricot'

#require 'forwardable'

class Converter
  extend Forwardable
  
  def initialize
    @out = File.new( "test.tmp", "w" )
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
        when 'hr'
          @out << "\n\\bobrule\n"
        when 'h1'
          if child.attributes[ 'class' ] == 'songtitle'
            # We assume this <h1> contains no further elements
            child.each_child { |c| raise if c.elem? }
            title = child.inner_html.gsub( '!', "\\textexclaim{}" )
            simple = converter.buffer.downcase.gsub( /\\?[#&~]|\\ss/, '' )
            @out << "\\songlbl{" << title << "}{" << simple << "}"
          else
            @out << "\\section*{"
            text( child )
            @out << '}'
          end
        when 'h2'
          if child.attributes[ 'class' ] == 'songversion'
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
        when 'li'
          @out << "\\item"
          text( child )
        when 'ul'
          # Do we want it this way?
          @out << "\\begin{itemize}"
        when 'div'
          body( child ) # hehe
        when 'blockquote'
          @out << "\\begin{quote}"
          text( child )
          @out << "\\end{quote}"
        else
          raise Converter::Error, "unexpected tag <#{child.name}>"
        end
      end # ignore text and comments
    end
  end

  def text( element )
    element.each_child do |child|
      if child.elem?
        case child.name
        when 'br'
          @out << "\\\\"
        when 'a'
          # Fix here!
          case child.attributes['class']
          when 'recordlink'
            @out << "\\emph{"
          when 'url'
            @out << "\\emph{"
          when 'songlink'
            @out << "\\emph{"
          else
            # puts child.attributes["class"]
            @out << "\\emph{"
          end
          text( child )
          @out << "}"
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
        else
          raise Converter::Error, "unexpected tag <#{child.name}>"
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
    css = element.attributes['class']
    if css.nil? || css.empty?
      @out << '\\begin{alltt}'
      pre_misc( element )
    else
      classes = css.split
      if classes[1]
        @out << "\\begin{#{classes[1]}}"
        converter.extra = '\\end{' + classes[1] + '}' + converter.extra
        classes.delete_at( 1 )
      end

      case classes[0]
      when 'verse', 'refrain', 'bridge', 'bridge2', 'bridge3', 'spoken'
        @out << '\\begin{' << classes[0] << '}\\begin{pre}'
        @out << '\\slshape' if classes[0] == 'spoken'
        @out << "%\n"
        converter.extra = '\\end{' + classes[0] + '}' + converter.extra
        converter.newState( PreTextState )
      when 'tab'
        @out << '\\begin{pre}%' << "\n"
        converter.buffer = ""
        converter.newState( TabState )
      when 'chords'
        @out << '\\begin{alltt}'
        converter.newState( MiscPreState )
      when 'quote'
        @out << '\\begin{quote}\\begin{alltt}'
        converter.extra = '\\end{quote}' + converter.extra
        converter.newState( MiscPreState )
      else
        raise RuntimeError, "unexpected pre attribute #{classes[0]}"
      end
    end
  end

end

class PluckHpricot
  def initialize( html )
    @doc = Hpricot( html )
    @converter = Converter.new
  end

  def start
    @converter.body( doc.at( "body" ) )
  end
end
