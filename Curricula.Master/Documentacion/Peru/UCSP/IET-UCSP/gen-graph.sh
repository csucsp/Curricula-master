#!/bin/csh
set OutputInstDir=.
set file=IET-UCSP

echo "Generating $file.ps file ..."
dot -Tps $file.dot -o $file.ps
echo "Converting ps to png ..."
convert $file.ps $file.png
echo "gen-graph done!"
