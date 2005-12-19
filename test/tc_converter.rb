
$:.unshift File::join( File::dirname( __FILE__ ), '..', 'lib' )

require 'test/unit'
require 'conversion'

class TestConverter < Test::Unit::TestCase

  SIMPLE_STRINGS = [
    [ "He told&nbsp;Peter, &ldquo;Peter, put up your sword&rdquo;?",
      "He told~Peter, ``Peter, put up your sword''?" ],
    [ "Of course &ndash; everything tabbed by Eyolf &Oslash;strem",
      "Of course -- everything tabbed by Eyolf {\\O}strem" ],
    [ "(you can make that \303\230strem \342\200\223 that's " \
        "\302\222Unicode\302\222)",
      "(you can make that {\\O}strem -- that's 'Unicode')" ],
    [ "$200, thats 105%, hello_world, #42, ^wedge, &c",
      "\\$200, thats 105\\%, hello\\_world, \\#42, \\^wedge, \\&c" ]
  ]
  
  def test_texify
    SIMPLE_STRINGS.each do |html, tex|
      html2tex = Converter::texify( html )
      assert_equal( tex, html2tex )
    end
  end
end
