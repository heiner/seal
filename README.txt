
This is SEAL, a program to build a book of Bob Dylan tunes.

Quick start: Type into a terminal
  ./seal-convert /path/to/dylanchords
  ./seal-tex

If you are a MS Windows user or you have problems, see
http://www.dylanchords.com/seal-installation.htm

The homepage of Seal is
http://www.math.tu-dresden.de/~kuettler/seal/

Command line help
-----------------

Just type
  ./seal-convert --help
or
  ./seal-tex --help

Configuration Options
---------------------

Beginning with revision 82, seal-convert has configuration options
that determine certain aspects of the output. Right now these are

  openright    Start new songs on a right (odd, recto) page
  openleft     Start new songs on a left (even, verso) page
  openany      Start new songs on any (the next) page

For instance, you can type
  ./seal-convert -o openleft /usr/local/doc/dylanchords/
to have each songs started on a left-hand side.

Have fun!
Heiner <heinrich.kuettler@gmx.de>
