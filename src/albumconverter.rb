
begin
  require 'hpricot'
rescue LoadError
  require 'rubygems' and retry

  puts "You need the Hpricot library to run seal-convert."
  puts "Get it at http://code.whytheluckystiff.net/hpricot/"
  exit( 1 )
end

require 'src/converter'
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
    
    open( File.join( dest, "index#{ext}.tex" ), 'w' ) do |index_file|
      index_file << start_index( album_name )

      inputs = []
      outtake = false

      Seal::out.printf( "\n%35s: ", album_name )
      songs.each do |song|
        if song.nil?
          progress( " " )
          index_file << "\\end{ctabular}\n\\begin{ctabular}[r]{r>{\\raggedright}p{20em}}"
          next
        end

        input = true
 
        case song[-1]
        when ?@
          # reference
          song.chop!
          input = false
          index_file << "\\referencearrow"
        when ?*
          # outtake
          song.chop!
          if !outtake
            index_file << "&\\tabularnewline\n"
            outtake = true
          end
        end

        basename = song[0...-4] # without extension, but with path
        inputs << File.join( File.basename( dest ), basename ) if input
        
        if @converted_titles.has_key?( basename )
          progress( 'r' )
        else
          open( File.join( src, song ) ) do |ifile|
            open( File.join( dest, basename + '.tex' ), 'w' ) do |ofile|
              @converter.convert( ifile, ofile )
            end
          end
        
          @converted_titles[basename] = @converter.song_title

          @stats.songs += 1
          progress( '.' )
        end

        title = @converted_titles[basename].downcase # or not downcase?
        ref = title.downcase.gsub( /\\?[#&~]|\\ss/, '' )

        index_file << "\\pageref{song:#{ref}} & \\textsc{#{title}} \\tabularnewline\n"
      end

      index_file << "\\end{ctabular}\n\\end{flushright}\n\n"

      # Convert the intro (if any)
      data = File.read( File.join( src, 'index.htm' ) )
      Converter.preprocess( data )
      doc = Hpricot( data )

      # title = doc.at( "html/head/title" ).inner_html

      # find first <div> tag with attribute "id" value "intro"
      element = doc.at( "//div[@id='intro']" )
      if !element.nil?
        index_file << "\\newpage\\begin{articlelayout}\n\\vspace*\\fill\n"
        @converter.redirect( index_file ) do |c|
          c.body( element )
        end
        index_file << "\n\\end{articlelayout}\n"
      end
    
      index_file << "\\clearpage\n\n"
      inputs.each do |song|
        index_file << "\\input{#{song}}\n"
      end
    end

    @stats.albums += 1
  end

  def progress( char )
    unless @options[ :quiet ]
      Seal::out.print( char )
      Seal::out.flush
    end
  end
end
