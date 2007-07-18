
require 'src/converter'
require 'src/albumtitles'

module States
  AlbumIndexState = State.new
  class <<AlbumIndexState

    def startElement( converter, name, attributes )
      if name == 'title'
        converter.newState( AlbumTitleState )
      end
      if name == 'div' and attributes[ 'id' ] == 'intro'
        converter.out << "\\newpage\\begin{articlelayout}\n\\vspace*\\fill\n"
        converter.newState( AlbumIntroState )
      end
    end

    def to_s
      'AlbumIndexState'
    end
  end

  AlbumTitleState = State.new
  class <<AlbumTitleState

    include EntityHandler

    def endElement( converter, name )
      if name == "title"
        converter.buffer.gsub!( '#', '\\#' )
        converter.buffer.gsub!( '&', '\\\\&' )
        converter.title = converter.buffer
        converter.buffer = ""
        converter.endState
      else
        raise Converter::Error
      end
    end

    def character( converter, data )
      converter.buffer << data
    end

    def skippedEntity( converter, name )
      converter.buffer << entity( name )
    end

    def to_s
      'AlbumTitleState'
    end
  end



  AlbumIntroState = BodyState.clone
  class <<AlbumIntroState

    def endElement( converter, name )
      if name == 'div'
        converter.out << "\n\\end{articlelayout}\n"
        converter.endState
      else
        super
      end
    end

    def to_s
      'AlbumIndexState'
    end
  end
end

class AlbumConverter

  attr_reader :number, :title

  def initialize( options, stats )
    @options = options
    @stats = stats
    @number = 0
    @title  = ""
    @converter = Converter.new
    @converted_titles = {}
    @progress = Seal::out unless options[ :quiet ]
  end

  def convert( album_name, src, dest, songs )

    @number = @number.succ
    album_title, ext = album_name.split( '#' )
    ext = '_' + ext if not ext.nil?
    
    index = File.new( File.join( dest, "index#{ext}.tex" ), 'w' )

    index << start_index( album_name )

    inputs = []
    outtake = false

    Seal::out.printf( "\n%35s: ", album_name )
    songs.each do |song|
      if song.nil?
        progress( " " )
        index << "\\end{ctabular}\n\\begin{ctabular}[r]{r>{\\raggedright}p{20em}}"
        next
      end

      input = true
      prefix = ""
 
      case song[-1]
      when ?@
        # reference
        song.chop!
        input  = false
        prefix = '\\referencearrow'
      when ?*
        # outtake
        song.chop!
        unless outtake
          index << "&\\tabularnewline\n"
          outtake = true
        end
      else
      end

      basename = song[0...-4] # without extension, but with path
      if input
        inputs << File.join( File.basename( dest ), basename )
      end

      unless @converted_titles.has_key?( basename )
        @converter.out = File.new( File.join( dest, basename + '.tex' ), 'w' )
        @converter.convert( File.join( src, song ) )
        @converted_titles[ basename ] = @converter.title
        @converter.reset
        @stats.songs += 1
        progress( '.' )
      else
        progress( 'r' )
      end

      ttl = @converted_titles[ basename ]
      ref = ttl.downcase.gsub( /\\?[#&~]|\\ss/,'' )

      index << prefix << '\\pageref{song:' << ref << '} & \\textsc{' \
            << ttl << '} \\tabularnewline' << "\n"
    end

    index << "\\end{ctabular}\n\\end{flushright}\n\n"

    # Convert the intro (if any)
    @converter.out = index
    @converter.newState( States::AlbumIndexState )
    @converter.convert( File.join( src, 'index.htm' ) )
    @converter.out = nil
    @converter.reset

    index << "\\clearpage\n\n"
    inputs.each do |song|
      index << '\\input{' << song << "}\n"
    end
    index.close
    @stats.albums += 1
  end

  def progress( char )
    unless @options[ :quiet ]
      @progress.print( char )
      @progress.flush
    end
  end
end
