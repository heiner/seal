#!/bin/bash

ssh -T kuettler@www.math.tu-dresden.de <<EOS
svn export file://$HOME/.repositories/seal/trunk $HOME/seal
REVISION=`svnversion seal`
echo REVISION=$REVISION";" DATE=\"`date -R`\" > $HOME/seal/src/snapshot.rb
zip -r $HOME/public_html/seal/snapshots/seal-revision-$REVISION.zip $HOME/seal/
rm -rf $HOME/seal/
EOS
