#!/usr/bin/env ruby

begin
  require 'hpricot'
rescue LoadError
  require 'rubygems' and retry

  puts "You need the Hpricot library to run seal-convert."
  exit( 1 )
end

class Converter
  
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
            child.each_child { |c| raise Converter::Error if c.elem? }
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
        when 'ul'
          @out << "\\begin{itemize}"
          child.each_child do |item|
            if item.elem?
              raise Converter::Error if item.name != 'li'
              @out << "\\item"
              text( child )
            end # ignore text and comments
          end
          @out << "\\end{itemize}"
        when 'div'
          body( child )
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
      pre_misc( element )
    else
      classes = css.split
      if classes[1]
        @out << "\\begin{#{classes[1]}}"
        extra = "\\end{#{classes[1]}}"
        #classes.delete_at( 1 )
      end

      case classes[0]
      when 'verse', 'refrain', 'bridge', 'bridge2', 'bridge3', 'spoken'
        @out << "\\begin{#{classes[0]}}\n\\begin{pre}"
        @out << '\\slshape' if classes[0] == 'spoken'
        @out << "%\n"
        pre_text( element )
        @out << "\\end{pre}\n\\end{#{classes[0]}"
      when 'tab'
        pre_tab( element )
      when 'chords'
        pre_misc( element )
      when 'quote'
        @out << "\\begin{quote}
        pre_misc( element )
        @out << "\\end{quote}"
      else
        raise Converter::Error, "unexpected pre CSS class #{classes[0]}"
      end

      @out << extra
    end
  end

  def pre_misc( element )
    @out << "\\begin{alltt}"
    # We assume this element contains only text
    element.each_child do |child|
      if child.text?
        text = child.to_html
        text.gsub!( '[', "{\\relax}[" )
        text.gsub!( "\t", '~'*8 )
        @out << text
      elsif child.elem?
        raise Converter::Error, "`misc' <pre> tag with child tags"
      else
        # write out
      end
    end
    @out << "\\end{alltt}"
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
    text = ""
    # We assume this element contains only text
    element.each_child do |child|
      if child.text?
        text += child.to_html
      elsif child.elem?
        raise Converter::Error, "`text' <pre> tag with child tags"
      else
        # write out
      end
    end

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

    tab = ""
    # We assume this element contains only text
    element.each_child do |child|
      if child.text?
        tab += child.to_html
      elsif child.elem?
        raise Converter::Error, "`tab' <pre> tag with child tags"
      else
        # write out
      end
    end

    text.rstrip!
    text.slice!( 0 ) while text[0] == ?\n
    text.gsub!( '[', "{\\relax}[" )
    text.gsub!( "\t", '~'*8 )
    text.gsub!( '--', '{-}{-}' )
    text.gsub!( ' ', '~' )

    text.gsub!( "\n\n\n", "\n\n" ) # for a_change_is_gonna_come

    # For String#(g)sub(!), \\\\\\ (six backslashes) is the smallest code
    # that produces \\ as output. See
    # http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-core/11037
    text.gsub!( "\n\n", "\\\\\\*[\\baselineskip]" )
    text.gsub!( "\n",   "\\\\\\*\n" )
    @out << text << "\n\\end{pre}"
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
