#!/bin/csh
set figsize     = $1    # small or big
set lang        = $2

set current_dir = `pwd`
set file=$figsize-graph-curricula-$lang

echo "Generating ../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/dot/$file.dot => ../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/figs/$file.ps file ...";
dot -Tps ../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/dot/$file.dot -o ../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/figs/$file.ps;
echo "gen-graph OK! (../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/figs/$file.ps)";

echo "Generating ../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/dot/$file.dot => ../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/figs/$file.png file ...";
dot -Tsvg ../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/dot/$file.dot -o ../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/figs/$file.svg;
echo "gen-graph OK! (../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/figs/$file.svg)";

cp ../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/figs/$file.svg ../Curricula.out/html/Peru/CS-UCSP/Plan2016/figs/. ;

# -Gcharset=latin1