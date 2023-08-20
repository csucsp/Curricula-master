#!/bin/csh

set institution=UCSP
setenv CC_Institution UCSP
set filter=UCSP
setenv CC_Filter UCSP
set version=
setenv CC_Version 
set area=CS
setenv CC_Area CS
set CurriculaParam=CS-UCSP

./scripts/process-curricula.pl CS-UCSP 

foreach lang ('ES' 'EN')
    ../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/scripts/gen-graph.sh big $lang;
    ../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/scripts/compile-simple-latex.sh small-graph-curricula-$lang CS-UCSP-small-graph-curricula ../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/tex;
    ../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/scripts/gen-poster.sh $lang;
end

