
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
    textoc = <<EOS
\\begin{tabular}{rlcrl}
\\multicolumn{5}{r}{{\\Huge Contents}}\\tabularnewline
&&&&\\tabularnewline
&&&&\\tabularnewline
\\textbf{2}$\\quad$Zweites Album &
\\emph{\\pageref{album:2}} &
&&\\tabularnewline

&&&&\\tabularnewline
\\multicolumn{4}{r}{Song Index} & \\emph{\\pageref{songindex}}\\tabularnewline
\\end{tabular}
EOS
    
    contents = [ [1, "Erstes Album"], [2, "Zweites Album"] ]
    @seal.generate_toc( contents )
    File::open( File::join( Dir::tmpdir, 'contents.tex' ) ) { |f|
      assert( f.read.include?( textoc.strip ), "Table of contents seems to be no good" )
    }
  end

end
