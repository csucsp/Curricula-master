#!/bin/csh
set lang=$1

mkdir -p ../Curricula.out/pdfs/Peru-CS-UCSP/Plan2016;
mkdir -p ../Curricula.out/html/Peru/CS-UCSP/Plan2016/docs;

../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/scripts/compile-simple-latex.sh Computing-poster-$lang CS-UCSP-poster-$lang ../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/tex;
cp ../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/tex/CS-UCSP-poster-$lang.pdf ../Curricula.out/pdfs/Peru-CS-UCSP/Plan2016/.;
mv ../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/tex/CS-UCSP-poster-$lang.pdf ../Curricula.out/html/Peru/CS-UCSP/Plan2016/docs/.;

mkdir -p ../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/figs;
echo "mutool convert -o ../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/figs/CS-UCSP-poster-$lang-P%d.png ../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/tex/CS-UCSP-poster-$lang.pdf 1-1";
mutool convert -o ../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/figs/CS-UCSP-poster-$lang-P%d.png ../Curricula.out/pdfs/Peru-CS-UCSP/Plan2016/CS-UCSP-poster-$lang.pdf 1-1;
cp "../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/figs/CS-UCSP-poster-$lang-P1.png" "../Curricula.out/html/Peru/CS-UCSP/Plan2016/figs/.";
cp "../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/figs/CS-UCSP-poster-$lang-P1.png" "../Curricula.out/pdfs/Peru-CS-UCSP/Plan2016/.";
