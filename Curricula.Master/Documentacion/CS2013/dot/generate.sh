#!/bin/csh
set file=cs2013

echo "Generating $file.ps file ..."
neato -Tps $file.dot -o $file.ps
echo "Converting ps to png ..."
convert $file.ps $file.png
echo "Converting ps to pdf ..."
convert $file.ps $file.pdf
echo "gen-graph done!"
