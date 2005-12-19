
class Converter

  #attr_reader :songtitle
  attr_accessor :standalone

  #def initialize
  #  
  #end

  def convert( istream, ostream )
    @istream, @ostream = istream, ostream
    
  end

  def convert_file( src, dest_dir )
    src_ext  = File::extname( src )
    basename = File::basename( src, src_ext )
    dest = File::join( dest_dir, basename + '.tex' )

    begin
      ifile = File::new( src,  'r' )
      ofile = File::new( dest, 'w' )
      convert( ifile, ofile )
    ensure
      ifile.close unless ifile.nil?
      ofile.close unless ofile.nil?
    end
  end

  def <<( string )
    @ostream << Converter::texify( string )
  end

  REPLACEMENTS = [
    # non-entity replacements
    [ '\\', '\\bs' ],
    #[ /^\[/, "{\\relax}[" ],
    #[ /\]\Z/, "{\\relax}]" ],
    [ "\303\230", '{\\O}' ],
    
    [ "\302\222", "'" ],       # &#146;
    [ "\342\200\223", '--' ],  # &#8211;
    [ "\342\200\224", '---' ], # &#8212;
    [ "\342\200\234", '``' ],  # &#8220
    [ "\342\200\235", "''" ],  # &#8221;
    [ '~', '\\~{}' ], [ '$', '\\$'], [ '%', '\\%'],
    [ '_', '\\_'],    [ '#', '\\#'], [ '^', '\\^'],

    # entities
    ['&ndash;', '--'], ['&nbsp;', '~'], ['&ldquo;', '``'], ['&rdquo;', "''"],
    ['&acirc;', '\\^a'], ['&agrave;', '\\`a'], ['&aacute;', "\\'a"],
    ['&auml;', '\\"a'], ['&ecirc;', '\\^e'], ['&egrave;', '\\`e'],
    ['&eacute;', "\\'e"], ['&euml;', '\\"e'], ['&icirc;', '\\^i'],
    ['&igrave;', '\\`i'], ['&iacute;', "\\'i"], ['&iuml;', '\\"i'],
    ['&ocirc;', '\\^o'], ['&ograve;', '\\`o'], ['&oacute;', "\\'o"],
    ['&ouml;', '\\"o'], ['&ucirc;', '\\^u'], ['&ugrave;', '\\`u'],
    ['&uacute;', "\\'u"], ['&uuml;', '\\"u'], ['&ycirc;', '\\^y'],
    ['&ygrave;', '\\`y'], ['&yacute;', "\\'y"], ['&yuml;', '\\"y'],
    ['&Acirc;', '\\^A'], ['&Agrave;', '\\`A'], ['&Aacute;', "\\'A"],
    ['&Auml;', '\\"A'], ['&Ecirc;', '\\^E'], ['&Egrave;', '\\`E'],
    ['&Eacute;', "\\'E"], ['&Euml;', '\\"E'], ['&Icirc;', '\\^I'],
    ['&Igrave;', '\\`I'], ['&Iacute;', "\\'I"], ['&Iuml;', '\\"I'],
    ['&Ocirc;', '\\^O'], ['&Ograve;', '\\`O'], ['&Oacute;', "\\'O"],
    ['&Ouml;', '\\"O'], ['&Ucirc;', '\\^U'], ['&Ugrave;', '\\`U'],
    ['&Uacute;', "\\'U"], ['&Uuml;', '\\"U'], ['&Ycirc;', '\\^Y'],
    ['&Ygrave;', '\\`Y'], ['&Yacute;', "\\'Y"], ['&Yuml;', '\\"Y'],
    ['&atilde;', '\\~a'], ['&ntilde;', '\\~n'], ['&otilde;', '\\~o'],
    ['&Atilde;', '\\~A'], ['&Ntilde;', '\\~N'], ['&Otilde;', '\\~O'],
    ['&oslash;', '{\\o}'], ['&Oslash;', '{\\O}'], ['&aring;', '{\\aa}'],
    ['&Aring;', '{\\AA}'], ['&aelig;', '{\\ae}'], ['&AElig;', '{\\AE}'],
    ['&szlig;', '{\\ss}'], ['&ccedil;', '{\\c c}'], ['&Ccedil;', '{\\c C}'],

    # special (don't know why, but four backslashes are required!)
    [ '&', '\\\\&' ]
  ]
  
  def Converter::texify( string )
    REPLACEMENTS.each do |pattern, replacement|
      string.gsub!( pattern, replacement )
    end
    return string
  end

end
