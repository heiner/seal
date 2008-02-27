
begin
  require 'hpricot'
rescue LoadError
  require 'rubygems' and retry

  puts "You need the Hpricot library to run seal-convert."
  exit( 1 )
end

require 'src/pluckhpricot'
require 'src/albumtitles'


class AlbumConverter

  attr_reader :number, :title

  def initialize( options, stats )
    @options = options
    @stats = stats
    @number = 0
    @title  = ""
    @converter = Converter.new
    @converted_titles = {}
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
        ifile = File.new( File.join( src, song ) )
        ofile = File.new( File.join( dest, basename + '.tex' ), 'w' )
        @converter.convert( ifile, ofile )
        ofile.close
        ifile.close
        
        @converted_titles[basename] = @converter.song_title

        @stats.songs += 1
        progress( '.' )
      else
        progress( 'r' )
      end

      ttl = @converted_titles[basename]
      ref = ttl.downcase.gsub( /\\?[#&~]|\\ss/, '' )

      index << prefix << '\\pageref{song:' << ref << '} & \\textsc{' \
            << ttl.downcase << '} \\tabularnewline' << "\n"
    end

    index << "\\end{ctabular}\n\\end{flushright}\n\n"

    # Convert the intro (if any)
    data = File.read( File.join( src, 'index.htm' ) )
    Converter.preprocess( data )
    doc = Hpricot( data )

    # title = doc.at( "html/head/title" ).inner_html

    # find first <div> tag with attribute "id" value "intro"
    element = doc.at( "//div[@id='intro']" )
    if !element.nil?
      index << "\\newpage\\begin{articlelayout}\n\\vspace*\\fill\n"
      @converter.redirect( index ) do |c|
        c.body( element )
      end
      index << "\n\\end{articlelayout}\n"
    end
    
    index << "\\clearpage\n\n"
    inputs.each do |song|
      index << '\\input{' << song << "}\n"
    end
    index.close

    @stats.albums += 1
  end

  def progress( char )
    unless @options[ :quiet ]
      Seal::out.print( char )
      Seal::out.flush
    end
  end
end
