
$:.unshift File::join( File::dirname( __FILE__ ), '..' )

require 'test/unit'
load 'seal-convert'

require 'tmpdir'

class TestSealConvert < Test::Unit::TestCase

  def initialize( *args )
    super( *args )
    @seal = Seal.new( { :destination=>Dir::tmpdir} )
  end

  def test_toc
    latex = <<EOS
&&&&\\tabularnewline
&&&&\\tabularnewline
\\textbf{1}$\\quad$Erstes Album & \\emph{\\pageref{album:1}} & &
\\textbf{2}$\\quad$Zweites Album & \\emph{\\pageref{album:2}}
\\tabularnewline
&&&&\\tabularnewline
\\multicolumn{4}{r}{Song Index} & \\emph{\\pageref{songindex}}\\tabularnewline
\\end{tabular}
EOS
    
    contents = [ [1, "Erstes Album"], [2, "Zweites Album"] ]
    @seal.generate_toc( contents )
    File::open( File::join( Dir::tmpdir, 'contents.tex' ) ) do |f|
      input = f.read
      latex.each_line do |line|
        assert( input.include?( line.strip ),
                "Table of contents seems to be no good, " \
                "should include ``#{line.strip}''" )
      end
    end
  end

end
