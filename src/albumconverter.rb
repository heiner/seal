
require 'src/converter'

class AlbumConverter

  attr_reader :number, :title

  def initialize( seal )
    @seal = seal

    @number = 0
    @title  = ""
    @converter = Converter.new( seal )
    @converted_titles = {}
  end

  def start_index( album )
    latex_title, @title, release, number = @seal.albumtitles[album]
    if not number.nil?
      @number = number
    end
    simple = @title.upcase.gsub( "\\&", '' )
    return <<EOS
\\def\\thesong{}
\\cleardoublepage
\\def\\thealbum{#{@title}}
\\thispagestyle{album}
\\phantomsection
\\pdfbookmark{#{@number} #{@title}}{album#{@number}}
\\label{album:#{@number}}
\\label{album:#{simple}}

\\begin{flushright}
\\scalebox{6}{\\Huge\\scshape #{@number.to_s.downcase}}

\\vspace{5ex}
#{latex_title}

{\\footnotesize #{release}}

\\vspace{10ex}

\\begin{ctabular}[r]{r>{\\raggedright}p{20em}}
EOS
  end

  def convert( album_name, src, dest, songs )
    @number = @number.succ
    album_title, ext = album_name.split( '#' )
    ext = '_' + ext if not ext.nil?
    
    open( File.join( dest, "index#{ext}.tex" ), 'w' ) do |index_file|
      index_file << start_index( album_name )

      inputs = []
      outtake = false

      @seal.out.printf( "\n%35s: ", album_name ) unless @seal.options[ :quiet ]
      songs.each do |song|
        if song.nil?
          @seal.progress( " " )
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
        if input
          inputs << File.join( File.basename( dest ), basename )
        end
        
        if @converted_titles.has_key?( basename )
          @seal.progress( 'r' )
        else
          open( File.join( src, song ) ) do |ifile|
            open( File.join( dest, basename + '.tex' ), 'w' ) do |ofile|
              @converter.convert( ifile, ofile )
            end
          end
        
          @converted_titles[basename] = @converter.song_title

          @seal.stats.songs += 1
          @seal.progress( '.' )
        end

        title = @converted_titles[basename].downcase # or not downcase?
        ref = title.downcase.gsub( /\\?[#&~]|\\ss/, '' )

        index_file << "\\pageref{song:#{ref}} & \\textsc{#{title}} \\tabularnewline\n"
      end

      index_file << "\\end{ctabular}\n\\end{flushright}\n\n"

      # Convert the intro (if any)
      ifilename = File.join( src, 'index.htm' )
      if not File.exists?( ifilename )
	ifilename += 'l'
      end
      open( ifilename ) do |ifile|
        @converter.convert( ifile, index_file ) do |doc|
          # title = doc.at( "html/head/title" ).inner_html

          # find first <div> tag with attribute "id" value "intro"
          element = doc.at( "//div[@id='intro']" )
          if !element.nil?
            index_file << "\\newpage\\begin{articlelayout}\n\\vspace*\\fill\n"
            @converter.body( element )
            index_file << "\n\\end{articlelayout}\n"
          end
        end
      end
    
      index_file << "\\clearpage\n\n"
      inputs.each do |song|
        index_file << "\\input{#{song}}\n"
      end
    end

    @seal.stats.albums += 1
  end

end
