
$:.unshift File::join( File::dirname( __FILE__ ), '..', 'src' )

require 'test/unit'
require 'conversion'

require 'stringio'
require 'ostruct'

class Seal
  def Seal::out
    $stdout
  end
  def Seal::err
    $stderr
  end
end

class TestModuleConverting < Test::Unit::TestCase

  include Converting

  SIMPLE_STRINGS = [
    [ "He told&nbsp;Peter, &ldquo;Peter, put up your sword&rdquo;?",
      "He told~Peter, ``Peter, put up your sword''?" ],
    [ "Of course &ndash; everything tabbed by Eyolf &Oslash;strem",
      "Of course -- everything tabbed by Eyolf {\\O}strem" ],
    [ "$200, thats 105%, hello_world, #42, ^wedge, &c",
      "\\$200, thats 105\\%, hello\\_world, \\#42, \\^wedge, \\&c" ]
  ]

  UNCLEAN_STRINGS = [
    [ "'\"Well,\" they say, \"all's well\"'",
      "`{}``{}Well,''{} they say, ``{}all's well''{}'{}" ],
    [ "\"He looks straight into the sun and says 'revenge is mine'\"",
      "``{}He looks straight into the sun and says `{}revenge is mine'{}''{}" ],
    [ "'...and says \"revenge is mine\"'",
      "`{}\\ldots{}and says ``{}revenge is mine''{}'{}" ],
    [ "(you can make that above \303\230strem \342\200\223 that's " \
        "\302\222Unicode\302\222)",
      "(you can make that above {\\O}strem -- that's `{}Unicode'{})" ],
    [ "Looking for an evil chord? Try Ab. Evil language? C# (<=>C#m).",
      "Looking for an evil chord? Try A$\\flat$. Evil language? C$\\sharp$ (<=>C$\\sharp$m)." ],
    [ "Open D tuning: D-A-d-f#-a-d'", "Open D tuning: D-A-d-f$\\sharp$-a-d'" ]
  ]
  
  def test_texify
    SIMPLE_STRINGS.each do |html, tex|
      html2tex = Converting::texify( html )
      assert_equal( tex, html2tex )
    end
    UNCLEAN_STRINGS.each do |html, tex|
      html2tex = Converting::texify( html )
      assert_equal( tex, html2tex )
    end
  end

  CHORDLINES = [ "G     C                 G",
    "     C/d     G/d            D7     G  .  C/g  .  G  .  .  .",
    "G          ", 
    "Bb Eb/g Bb/f Eb  Ab Eb Bb    Eb/g Bb/f  [chords x2]",
    "E                                              A",
    "C . . . Am . . . F . . . G      rep. ad lib.",
                 "G          C   /b    D/a           G",
                 "             C   /b      G",
                 "           C  /b       D/a           G",
                 "               C  /b    D/f#"
               ]
  NOCHORDLINES = [ "That's what they did              ",
  "Of Canadee-i-o.",
  "It sure is right "]
  def test_chordlines
    CHORDLINES.each do |line|
      assert( Converting::chordline?( line ), "is chordline: #{line}" )
    end
    NOCHORDLINES.each do |line|
      assert( !Converting::chordline?( line ), "is no chordline: #{line}" )
    end
  end

  SIMPLE_HTML_STRINGS = [
    [ "<h1>A BIG <i>SURPRISE</i></h1>",
      "\\section*{A BIG \\emph{SURPRISE}}\n" ],
    [ "<h2>A BIGGER<br />\n<b>SURPRISE</b></h2>",
      "\\subsection*{A BIGGER\\\\ \\textbf{SURPRISE}}\n"],
    [ "<p>This is a &ldquo;paragraph&rdquo;, I said a <em>paragraph</em></p>",
      "\nThis is a ``paragraph'', I said a \\emph{paragraph}\n" ],
    [ "<p>&#9839;&#9837;</p>", "\n$\\sharp$$\\flat$\n" ],
    [ "<p><em>Italic<br />Newline</em></p>", "\n\\emph{Italic\\\\Newline}\n" ]
  ]
  
  def test_tag_coversion
    SIMPLE_HTML_STRINGS.each do |xml, tex|
      @ostream = ""
      next_tag( Document.new( xml ).root )
      assert_equal( tex, @ostream )
    end
  end

  def test_failures
    assert_raise( ConversionError ) {
      convert( "<h><body><h1>Wrong</h2></body></h>", "" )
    }
    assert_raise( ConversionError ) {
      convert( "<h><body><dong /></body></h>", "" )
    }
    assert_raise( ConversionError ) {
      convert( "<h><body><p><dong /></p></body></h>", "" )
    }
    assert_raise( ConversionError ) {
      convert( "<h><body><p><ul><p/></ul></p></body></h>", "" )
    }
  end

  def test_songconverter
    xml = <<EOS
<html><head />
<body>
<h1 class='songtitle'>Mary had a little lamp</h1>
<h2 class='songversion'>Classic harp version</h2>
<p>...</p>
</body></html>
EOS
    out = StringIO.new( "", 'w' )
    sc = SongConverter.new
    sc.convert( xml, out )
    assert_match( /\\songlbl\{Mary/, out.string )
    assert_match( /\\songversion\{Classic/, out.string )
    assert_match( /\\ldots/, out.string )
  end

  def test_preformated
    pre_tags = []

    pre_tags << []
    pre_tags.last << "<pre>This is a pre-tag</pre>" << \
      "\\begin{alltt}This is a pre-tag\\end{alltt}\n"


    pre_tags << []
    pre_tags.last << <<EOS
<pre class="verse">
G          C   /b    D/a           G
Wie gro&szlig;e Berge von Geld gibt man aus
             C   /b      G
F&uuml;r Bomben, Raketen und Tod?
           C  /b       D/a           G
Wie gro&szlig;e Worte macht heut' mancher Mann
               C  /b    D/f#
Und lindert damit keine Not?
</pre>
EOS

    pre_tags.last << <<EOS
\\begin{verse}\\begin{pre}%
G~~~~~~~~~~C~~~/b~~~~D/a~~~~~~~~~~~G\\\\*\\relax
Wie~gro{\\ss}e~Berge~von~Geld~gibt~man~aus\\\\ \\relax
~~~~~~~~~~~~~C~~~/b~~~~~~G\\\\*\\relax
F\\"ur~Bomben,~Raketen~und~Tod?\\\\ \\relax
~~~~~~~~~~~C~~/b~~~~~~~D/a~~~~~~~~~~~G\\\\*\\relax
Wie~gro{\\ss}e~Worte~macht~heut'~mancher~Mann\\\\ \\relax
~~~~~~~~~~~~~~~C~~/b~~~~D/f\\#\\\\*\\relax
Und~lindert~damit~keine~Not?\\\\ \\relax
\\end{pre}\\end{verse}
EOS

    pre_tags << []
    pre_tags.last << <<EOS
<pre class="chords">
E    x76454    F    F#   G
A    577655    Bb   B    C
G#m  466444    Am   A#m  Bm
B    799877    C    C#   D
</pre>
EOS
    pre_tags.last << <<EOS
\\begin{alltt}
E    x76454    F    F\\#   G
A    577655    Bb   B    C
G\\#m  466444    Am   A\\#m  Bm
B    799877    C    C\\#   D\\end{alltt}
EOS

    pre_tags << []
    pre_tags.last << <<EOS
<pre class="bridge2">
He helped me to build my union, he learned me how to talk.
I could see he was a cripple but he learned my soul to walk ***).
This world was lucky to see him born.

<em>
[You Nazis and you fascists tried to boss this world by hate.
He fought my war the union way and the hate gang all got beat.
This world was lucky to see him born.

... more commie crap follows ...
</em>
</pre>
EOS
    pre_tags.last << <<EOS
\\begin{bridge2}\\begin{pre}%
He~helped~me~to~build~my~union,~he~learned~me~how~to~talk.\\\\ \\relax
I~could~see~he~was~a~cripple~but~he~learned~my~soul~to~walk~***).\\\\ \\relax
This~world~was~lucky~to~see~him~born.\\\\ \\relax
~\\\\
\\textsl{{\\relax}[You~Nazis~and~you~fascists~tried~to~boss~this~world~by~hate.\\\\ \\relax
He~fought~my~war~the~union~way~and~the~hate~gang~all~got~beat.\\\\ \\relax
This~world~was~lucky~to~see~him~born.\\\\ \\relax
~\\\\
...~more~commie~crap~follows~...}\\\\ \\relax
\\end{pre}\\end{bridge2}
EOS

    pre_tags << []
    pre_tags.last << <<EOS
<pre class="tab">
  G
  :   .   .     :   .   .     :   .   .
|-----3-3-3-3-|-----3-3-3-3-|-----3-3-----|
|-----0-0-0-0-|-----0-0-0-0-|-----0-0-----|
|-----0-0-0-0-|-----0-0-0-0-|-----0-0-----|
|-------------|-------------|-------------|
|-2-----------|-0h2---------|-0h2-----0---|
|(3)----------|-------------|-------------|

  G
  :   .   .     :   .   .     :   .   .     :   .   .
|-----3---3---|-----3-------|-----3---3---|-----3---3--|
|-----0---0---|-----0-------|-----0---0---|-----0---0--|
|-----0---0---|-----0-------|-----0---0---|-----0---0--|
|-----0---0---|-0h2---------|-------------|-0----------|
|-------------|---------2---|-------------|------------|
|-3-----------|-------------|-0-----------|------------|
                                            I'm

  :   .   .     :   .   .     :   .   .
|-------------|-------------|--------------|
|-----0-0-0-0-|-----0-0-0-0-|-----3-3-3-3--|
|-----0-0-0-0-|-----0-0-0-0-|-----2-2-2-2--|
|-----0-0-0-0-|-0h2---------|-----0-0-0-0--|
|-2-----------|-------------|--------------|
|(3)----------|-------------|-2------------|
 out here a     thou -  sand  miles...
</pre>
EOS
    pre_tags.last << <<EOS
\\begin{pre}%
~~G\\\\*
~~:~~~.~~~.~~~~~:~~~.~~~.~~~~~:~~~.~~~.\\\\*
|{-}{-}{-}{-}-3-3-3-3-|{-}{-}{-}{-}-3-3-3-3-|{-}{-}{-}{-}-3-3{-}{-}{-}{-}-|\\\\*
|{-}{-}{-}{-}-0-0-0-0-|{-}{-}{-}{-}-0-0-0-0-|{-}{-}{-}{-}-0-0{-}{-}{-}{-}-|\\\\*
|{-}{-}{-}{-}-0-0-0-0-|{-}{-}{-}{-}-0-0-0-0-|{-}{-}{-}{-}-0-0{-}{-}{-}{-}-|\\\\*
|{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}-|{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}-|{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}-|\\\\*
|-2{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}-|-0h2{-}{-}{-}{-}{-}{-}{-}{-}-|-0h2{-}{-}{-}{-}-0{-}{-}-|\\\\*
|(3){-}{-}{-}{-}{-}{-}{-}{-}{-}{-}|{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}-|{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}-|\\end{pre}\\begin{pre}~~G\\\\*
~~:~~~.~~~.~~~~~:~~~.~~~.~~~~~:~~~.~~~.~~~~~:~~~.~~~.\\\\*
|{-}{-}{-}{-}-3{-}{-}-3{-}{-}-|{-}{-}{-}{-}-3{-}{-}{-}{-}{-}{-}-|{-}{-}{-}{-}-3{-}{-}-3{-}{-}-|{-}{-}{-}{-}-3{-}{-}-3{-}{-}|\\\\*
|{-}{-}{-}{-}-0{-}{-}-0{-}{-}-|{-}{-}{-}{-}-0{-}{-}{-}{-}{-}{-}-|{-}{-}{-}{-}-0{-}{-}-0{-}{-}-|{-}{-}{-}{-}-0{-}{-}-0{-}{-}|\\\\*
|{-}{-}{-}{-}-0{-}{-}-0{-}{-}-|{-}{-}{-}{-}-0{-}{-}{-}{-}{-}{-}-|{-}{-}{-}{-}-0{-}{-}-0{-}{-}-|{-}{-}{-}{-}-0{-}{-}-0{-}{-}|\\\\*
|{-}{-}{-}{-}-0{-}{-}-0{-}{-}-|-0h2{-}{-}{-}{-}{-}{-}{-}{-}-|{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}-|-0{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}|\\\\*
|{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}-|{-}{-}{-}{-}{-}{-}{-}{-}-2{-}{-}-|{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}-|{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}|\\\\*
|-3{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}-|{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}-|-0{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}-|{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}|\\\\*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~I'm\\end{pre}\\begin{pre}~~:~~~.~~~.~~~~~:~~~.~~~.~~~~~:~~~.~~~.\\\\*
|{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}-|{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}-|{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}|\\\\*
|{-}{-}{-}{-}-0-0-0-0-|{-}{-}{-}{-}-0-0-0-0-|{-}{-}{-}{-}-3-3-3-3{-}{-}|\\\\*
|{-}{-}{-}{-}-0-0-0-0-|{-}{-}{-}{-}-0-0-0-0-|{-}{-}{-}{-}-2-2-2-2{-}{-}|\\\\*
|{-}{-}{-}{-}-0-0-0-0-|-0h2{-}{-}{-}{-}{-}{-}{-}{-}-|{-}{-}{-}{-}-0-0-0-0{-}{-}|\\\\*
|-2{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}-|{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}-|{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}|\\\\*
|(3){-}{-}{-}{-}{-}{-}{-}{-}{-}{-}|{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}-|-2{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}{-}|\\\\*
~out~here~a~~~~~thou~-~~sand~~miles...
\\end{pre}
EOS

    @istream = OpenStruct.new
    @istream.path = "string"
    
    pre_tags.each do |tag, tex|
      @ostream = ""
      next_tag( Document.new( tag ).root )
      assert_equal( tex.strip, @ostream.strip )
    end
  end
end

class TestClassAlbumBuilder < Test::Unit::TestCase

  class AlbumBuilderWrapper < AlbumBuilder
    attr_writer :source, :destination, :number, :songs
  end

  def initialize( *args )
    super( *args )
    @builder = AlbumBuilderWrapper.new
  end

  RELEASESTRINGS = [
    [ [ "Recorded live at the shows in Fort Worth, May 16 and Fort Collins, May 23.", "\nReleased Sep 1, 1976" ],
      "Recorded live at the shows in Fort Worth, May 16 and Fort Collins, May 23. --- Released September 1, 1976"
    ], 
    [ [ "Recorded Sept/Dec 1974, ", "\nreleased Jan 20, 1975" ],
      "Recorded September/December 1974 --- Released January 20, 1975"
    ]
  ]
  def test_format_release
    RELEASESTRINGS.each do |string, release|
      assert_equal( release, @builder.send( :format_release, string ) )
    end
  end

  def test_convert
    istring = <<EOS
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html lang="en" xml:lang="en" xmlns="http://www.w3.org/1999/xhtml">


<head>
<title>Saved (1980)</title>
<link rel="stylesheet" type="text/css" href="../css/general.css" />
<link href="../css/indexpages.css" rel="stylesheet" type="text/css" />
</head>

<body>
<h1><img alt="Saved" src="../graphics/saved.jpg" width="150" height="150" /> Saved (1980)</h1>

<p class="recdate">Recorded Feb 11-15 1980<br />
Released June 20 1980
</p>
<ol>
  <li><a href="a_satisfied_mind.htm">A Satisfied Mind</a> (incl. live version, 1999)</li>
  <li><a href="saved.htm">Saved</a></li>
  <li><a href="covenant_woman.htm">Covenant Woman</a></li>
  <li><a href="what_can_i_do_for_you.htm">What Can I Do For You?</a> (With transcription of the harp solo
    at the end)</li>
  <li><a href="solid_rock.htm">Solid Rock</a></li>
  <li><a href="pressing_on.htm">Pressing On</a></li>
  <li><a href="in_the_garden.htm">In the Garden</a></li>
  <li><a href="saving_grace.htm">Saving Grace</a></li>
  <li><a href="are_you_ready.htm">Are You Ready?</a></li>
</ol>
</body>
</html>
EOS

    latex = <<EOS
{\\footnotesize Recorded February 11--15 1980 --- Released June 20 1980}
EOS
    @builder.songs = []
    @builder.number = 23
    ostring = ""
    @builder.send( :convert, istring, ostring )

    latex.each_line do |line|
      assert( ostring.include?( line ),
              "`Saved' index isn't converted right: Should include <#{line.dump}>" )
    end
  end

end
