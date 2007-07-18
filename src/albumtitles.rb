
class AlbumConverter

  # This isn't really good, is it?
  
  def start_index( album )
    case album
    when "01_bobdylan"
      title_latex = "\\scalebox{1.5}{\\Huge Bob Dylan}\n"
      @title = "Bob Dylan"
      release = "Recorded November 20 and 22, 1961 --- Released March 19, 1962"

    when "02_freewheelin"
      title_latex = "\\scalebox{1.5}{\\Huge The Freewheelin'}\n\n\\vspace{1ex}\n\\scalebox{1.5}{\\Huge Bob Dylan}\n"
      @title = "The Freewheelin' Bob Dylan"
      release = "Recorded: April 24, 1962--April 24, 1963 --- Released: May 27, 1963"

    when "03_times"
      title_latex = "\\scalebox{1.5}{\\Huge The Times}\n\n\\vspace{1ex}\n\\scalebox{1.5}{\\Huge They Are A-Changin'}\n"
      @title = "The Times The Are A-Changin'"
      release = "Recorded August--October 1963 --- Released January 13, 1964"

    when "04_anotherside"
      title_latex = "\\scalebox{1.5}{\\Huge Another Side Of Bob Dylan}\n"
      @title = "Another Side Of Bob Dylan"
      release = "Recorded: June 9 1964 --- Released: August 8, 1964"

    when "05_biabh"
      title_latex = "\\scalebox{1.5}{\\Huge Bringing It All Back Home}\n"
      @title = "Bringing It All Back Home"
      release = "Recorded January 13--15, 1965 --- Released March 22, 1965"

    when "06_hwy61"
      title_latex = "\\scalebox{1.5}{\\Huge Highway 61 Revisited}\n"
      @title = "Highway 61 Revisited"
      release = "Recorded May 12--August 4, 1965 --- Released August 30, 1965"

    when "07_bob"
      title_latex = "\\scalebox{1.5}{\\Huge Blonde on Blonde}\n"
      @title = "Blonde on Blonde"
      release = "Recorded October 5, 1965--March 10, 1966 --- Released May 16, 1966"

    when "08_jwh"
      title_latex = "\\scalebox{1.5}{\\Huge John Wesley Harding}\n"
      @title = "John Wesley Harding"
      release = "Recorded: October/November 1967 --- Released: December 27, 1967"

    when "09_nashville"
      title_latex = "\\scalebox{1.5}{\\Huge Nashville Skyline}\n"
      @title = "Nashville Skyline"
      release = "Recorded February 1969 --- Released April 9, 1969"

    when "10_selfportrait"
      title_latex = "\\scalebox{1.5}{\\Huge Self Portrait}\n"
      @title = "Self Portrait"
      release = "Recorded April 1969--March 1970 ---   Released June 8, 1970"

    when "11_newmorning"
      title_latex = "\\scalebox{1.5}{\\Huge New Morning}\n"
      @title = "New Morning"
      release = "Recorded March--June 1970 --- Released October 21, 1970"

    when "12_billy"
      title_latex = "\\scalebox{1.5}{\\Huge Pat Garrett \\& Billy The Kid}\n"
      @title = "Pat Garrett \\& Billy The Kid"
      release = "Recorded January--February 1973 --- Released Jul 13, 1973\\\\(The movie was released in May 1973)"

    when "13_dylan"
      title_latex = "\\scalebox{1.5}{\\Huge Dylan (A fool such as I)}\n"
      @title = "Dylan (A fool such as I)"
      release = "Released November 16, 1973"

    when "14_planetwaves"
      title_latex = "\\scalebox{1.5}{\\Huge Planet Waves}\n"
      @title = "Planet Waves"
      release = "Recorded November 1973 --- Released January 17, 1974"

    when "15_beforetheflood"
      title_latex = "\\scalebox{1.5}{\\Huge Before the Flood}\n"
      @title = "Before the Flood"
      release = "Recorded live with The Band January 30 and February 13--14, 1974  --- Released: Jun 20, 1974"

    when "16_bott"
      title_latex = "\\scalebox{1.5}{\\Huge Blood on the Tracks}\n"
      @title = "Blood on the Tracks"
      release = "Recorded September/December 1974 --- Released January 20, 1975"

    when "17_basement"
      title_latex = "\\scalebox{1.5}{\\Huge The Basement Tapes}\n"
      @title = "The Basement Tapes"
      release = "Recorded June--November, 1967 --- Released June 26, 1975"

    when "18_desire"
      title_latex = "\\scalebox{1.5}{\\Huge Desire}\n"
      @title = "Desire"
      release = "Recorded July 1975 --- Released January 16 1976"

    when "19_hardrain"
      title_latex = "\\scalebox{1.5}{\\Huge Hard Rain}\n"
      @title = "Hard Rain"
      release = "Recorded live at the shows in Fort Worth, May 16 and Fort Collins, May 23.  --- Released September 1, 1976"

    when "20_streetlegal"
      title_latex = "\\scalebox{1.5}{\\Huge Street Legal}\n"
      @title = "Street Legal"
      release = "Recorded April 1978 --- Released June 15, 1978"

    when "21_budokan"
      title_latex = "\\scalebox{1.5}{\\Huge At Budokan}\n"
      @title = "At Budokan"
      release = "Recorded live at Nippon Budokan, Tokyo February 28 \\& March 1, 1978 --- Released April 23 1979"

    when "22_slowtrain"
      title_latex = "\\scalebox{1.5}{\\Huge Slow Train Coming}\n"
      @title = "Slow Train Coming"
      release = "Recorded April--May 1979 --- Released: August 18, 1979"

    when "23_saved"
      title_latex = "\\scalebox{1.5}{\\Huge Saved}\n"
      @title = "Saved"
      release = "Recorded February 11--15 1980 --- Released June 20 1980"

    when "24_shotoflove"
      title_latex = "\\scalebox{1.5}{\\Huge Shot of Love}\n"
      @title = "Shot of Love"
      release = "Recorded April--May, 1981 --- Released August 12, 1981"

    when "25_infidels"
      title_latex = "\\scalebox{1.5}{\\Huge Infidels}\n"
      @title = "Infidels"
      release = "Recorded April--May, 1983 --- Released October 27, 1983"

    when "26_reallive"
      title_latex = "\\scalebox{1.5}{\\Huge Real Live}\n"
      @title = "Real Live"
      release = "Recorded live July 5--8, 1984 --- Released: November 29, 1984"

    when "27_empire"
      title_latex = "\\scalebox{1.5}{\\Huge Empire Burlesque}\n"
      @title = "Empire Burlesque"
      release = "Recorded July 1984--March 1985 --- Released June 8, 1995"

    when "28_biograph"
      title_latex = "\\scalebox{1.5}{\\Huge Biograph}\n"
      @title = "Biograph"
      release = "Released: November 7, 1985"

    when "29_knocked"
      title_latex = "\\scalebox{1.5}{\\Huge Knocked Out Loaded}\n"
      @title = "Knocked Out Loaded"
      release = "Recorded Jul 1984--May 1986 --- Released Jul 14, 1986"

    when "30_down"
      title_latex = "\\scalebox{1.5}{\\Huge Down In The Groove}\n"
      @title = "Down In The Groove"
      release = "Recorded: August 1986 to May 1987 --- Released: May 31, 1988"

    when "31_ohmercy"
      title_latex = "\\scalebox{1.5}{\\Huge Oh Mercy}\n"
      @title = "Oh Mercy"
      release = "Recorded March 1989 --- Released September 22 1989"

    when "33_utrs"
      title_latex = "\\scalebox{1.5}{\\Huge Under The Red Sky}\n"
      @title = "Under The Red Sky"
      release = "Recorded January--March 1990 --- Released September 11, 1990"

    when "34_bootleg"
      title_latex = "\\scalebox{1.5}{\\Huge The Bootleg Series 1-3}\n"
      @title = "The Bootleg Series 1-3"
      release = "Released March 26, 1991"

    when "35_gaibty"
      title_latex = "\\scalebox{1.5}{\\Huge Good As I Been To You}\n"
      @title = "Good As I Been To You"
      release = "Recorded June--July 1992 --- Released November 3, 1992"

    when "36_wgw"
      title_latex = "\\scalebox{1.5}{\\Huge World Gone Wrong}\n"
      @title = "World Gone Wrong"
      release = "Recorded May 1993 --- Released October 26, 1993"

    when "37_unplugged"
      title_latex = "\\scalebox{1.5}{\\Huge Unplugged}\n"
      @title = "Unplugged"
      release = "Recorded November 17--18, 1994 --- Released May 2, 1995"

    when "38_toom"
      title_latex = "\\scalebox{1.5}{\\Huge Time out of Mind}\n"
      @title = "Time out of Mind"
      release = "Released September 30, 1997"

    when "39_rah"
      title_latex = "{\\Large Bootleg Series vol. 4: Live 1966}\n\n\\vspace{1ex}\n{\\Huge The ``Royal Albert Hall'' Concert}\n"
      @title = "Live 1966"
      release = "Recorded May 17, 1966 in Manchester Free TraDecember Hall.  --- Released 1998"

    when "41_lat"
      title_latex = "\\scalebox{1.5}{\\Huge ``Love And Theft''}\n"
      @title = "``Love And Theft''"
      release = "Recorded Spring 2001 --- Released September 11, 2001"

    when "42_bs5"
      title_latex = "{\\Large Bootleg Series vol. 5: Live 1975}\n\n\\vspace{1ex}\n{\\Huge The Rolling Thunder Revue}\n"
      @title = "Live 1975"
      release = "Recorded November--December 1975 --- Released November 26, 2002"

    when "43_bs6"
      title_latex = "{\\Large Bootleg Series vol. 6: Live 1964}\n\n\\vspace{1ex}\n{\\Huge Concert at Philharmonic Hall}\n"
      @title = "Live 1964"
      release = "Recorded October 31, 1964 at Philharmonic Hall, New York City --- Released March 30, 2004"

    when "44_bs7_ndh"
      title_latex = "{\\Large Bootleg Series vol. 7}\n\n\\vspace{1ex}\n{\\Huge No Direction Home: The Soundtrack}\n"
      @title = "No Direction Home"
      release = "Released September  2005"

    when "45_modern"
      title_latex = "\\scalebox{1.5}{\\Huge Modern Times}\n"
      @title = "Modern Times"
      release = "Recorded ? --- \\\\Released August 29, 2006"

    when "00_misc#early"
      @number = 'A'
      title_latex = "\\scalebox{1.5}{\\Huge Early Acoustic Bob}\n"
      @title = "Early Acoustic Bob"
      release = "Miscellaneous songs from 1960 to 1965"

    when "00_misc#electric"
      title_latex = "\\scalebox{1.5}{\\Huge (More or less) Electric Bob}\n"
      @title = "(More or less) Electric Bob"
      release = "Miscellaneous songs from 1965 to 1975"

    when "00_misc#rtr"
      title_latex = "\\scalebox{1.5}{\\Huge The Rolling Thunder Revue}\n"
      @title = "Rolling Thunder Revue"
      release = "Lasting from 1975 to 1976"

    when "00_misc#1978"
      title_latex = "\\scalebox{1.5}{\\Huge 1978 World Tour}\n"
      @title = "1978 World Tour"
      release = "Lasting from February to December 1978"

    when "00_misc#gospel"
      title_latex = "\\scalebox{1.5}{\\Huge Gospel period}\n"
      @title = "Gospel period"
      release = "From 1979 to 1981"

    when "00_misc#outtakes"
      title_latex = "\\scalebox{1.5}{\\Huge Studio outtakes, soundtracks etc.}\n"
      @title = "Studio outtakes, soundtracks etc."
      release = "1978 -- present"

    when "00_misc#live"
      title_latex = "\\scalebox{1.5}{\\Huge Live covers}\n"
      @title = "Live covers"
      release = "1984 -- present"
    else
      raise
    end

    return <<EOS
\\def\\thesong{}
\\cleardoublepage
\\def\\thealbum{#{@title}}
\\thispagestyle{album}
\\phantomsection
\\pdfbookmark{#{@number} #{@title}}{album#{@number}}
\\label{album:#{@number}}

\\begin{flushright}
\\scalebox{6}{\\Huge #{@number}}

\\vspace{5ex}
#{title_latex}

{\\footnotesize #{release}}

\\vspace{10ex}

\\begin{ctabular}[r]{r>{\\raggedright}p{20em}}
EOS
  end
end
