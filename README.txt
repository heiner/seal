
This is SEAL, a little program to build a book of songs by Bob
Dylan. For instructions see

http://www.math.tu-dresden.de/~kuettler/seal/
http://www.dylanchords.com/seal-installation.htm


Seal Options
------------

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
