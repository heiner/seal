#!/bin/bash

cd /tmp
svn co file:///home/heiner/.repositories/seal/trunk seal
REVISION=`svnversion seal`
echo REVISION=$REVISION";" DATE=\"`date -R`\" > seal/src/snapshot.rb
zip -r seal-revision-$REVISION.zip seal
mv seal-revision-$REVISION.zip $OLDPWD
