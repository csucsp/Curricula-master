#!/bin/csh
set pdfparam=$1
set htmlparam=$2
set syllabiparam=$3
set pdf=0
set html=0
set syllabi=0

if($pdfparam == "y" || $pdfparam == "Y" || $pdfparam == "yes" || $pdfparam == "Yes" || $pdfparam == "YES") then
    set pdf=1
else if($pdfparam == "n" || $pdfparam == "N" || $pdfparam == "no" || $pdfparam == "No" || $pdfparam == "NO") then
    set pdf=0
else
    echo "Error in pdf param"
    exit
endif

if($htmlparam == "y" || $htmlparam == "Y" || $htmlparam == "yes" || $htmlparam == "Yes" || $htmlparam == "YES") then
    set html=1
else if($htmlparam == "n" || $htmlparam == "N" || $htmlparam == "no" || $htmlparam == "No" || $htmlparam == "NO") then
    set html=0
else
    echo "Error in html param"
    exit
endif

if($syllabiparam == "y" || $syllabiparam == "Y" || $syllabiparam == "yes" || $syllabiparam == "Yes" || $syllabiparam == "YES") then
    set syllabi=1
else if($syllabiparam == "n" || $syllabiparam == "N" || $syllabiparam == "no" || $syllabiparam == "No" || $syllabiparam == "NO") then
    set syllabi=0
else
    echo "Error in syllabi param"
    exit
endif

echo "pdf=$pdf, html=$html, syllabi=$syllabi"
#setenv max_print_line 1000
#setenv error_line 254

set LogDir=./log
date > ./log/Peru-CS-UCSP-time.txt
#--BEGIN-FILTERS--
set institution=UCSP
setenv CC_Institution UCSP
set filter=UCSP
setenv CC_Filter UCSP
set version=
setenv CC_Version 
set area=CS
setenv CC_Area CS
set CurriculaParam=Peru-CS-UCSP
#--END-FILTERS--
set curriculamain=curricula-main
setenv CC_Main curricula-main
set current_dir = `pwd`

set Country=Peru
set InLogosDir=../Curricula.in/country/Peru/logos
set OutputDir=../Curricula.out
set OutputInstDir=../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016
set OutputTexDir=../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/tex
set OutputScriptsDir=../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/scripts
set OutputHtmlDir=../Curricula.out/html/Peru/CS-UCSP/Plan2016

rm *.ps *.pdf *.log *.dvi *.aux *.bcf *.xml *.bbl *.blg *.toc *.log *.out *.xref *.lof *.lot *.tmp *.bit *.idx *.glo *.ind *.x;
# ls IS*.tex | xargs -0 perl -pi -e 's/CATORCE/UNOCUATRO/g'

# sudo addgroup curricula
#sudo chown -R ecuadros:curricula ./Curricula

mkdir -p ./log;
./scripts/process-curricula.pl Peru-CS-UCSP ;
../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/scripts/gen-eps-files.sh;
foreach lang ('ES' 'EN')
    ../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/scripts/gen-graph.sh small $lang;
end

if($pdf == 1) then
    # latex -interaction=nonstopmode curricula-main
    
    rm *.ps *.pdf *.log *.dvi *.aux *.bcf *.xml *.bbl *.blg *.toc *.log *.out *.xref *.lof *.lot *.tmp *.bit *.idx *.glo *.ind *.x;
    ./scripts/clean.sh;
    latex curricula-main;

    mkdir -p ./log;
    ./scripts/compbib.sh curricula-main > ./log/Peru-CS-UCSP-errors-bib.txt;

    latex curricula-main;
    latex curricula-main;

    echo CS-UCSP;
    dvips curricula-main.dvi -o CS-UCSP.ps;
    echo CS-UCSP;
    ps2pdf CS-UCSP.ps CS-UCSP.pdf;
    rm -rf CS-UCSP.ps;
endif

./scripts/update-outcome-itemizes.pl Peru-CS-UCSP
./scripts/update-page-numbers.pl Peru-CS-UCSP;
mkdir -p ../Curricula.out/html/Peru/CS-UCSP/Plan2016/figs;

if($syllabi == 1) then
    #../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/scripts/gen-syllabi.sh all;
    ./scripts/gen-syllabi-pdf.pl Peru-CS-UCSP all;
endif

mkdir -p "../Curricula.out/pdfs/Peru-CS-UCSP/Plan2016";
mutool convert -o ../Curricula.out/html/Peru/CS-UCSP/Plan2016/CS-UCSP-P%d.png CS-UCSP.pdf 1-1;
cp CS-UCSP.pdf "../Curricula.out/pdfs/Peru-CS-UCSP/Plan2016/CS-UCSP Plan2016.pdf";

foreach lang ('ES' 'EN')
    ../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/scripts/gen-book.sh  BookOfSyllabi-$lang  	    pdflatex "CS-UCSP 2023-I BookOfSyllabi-$lang (Plan2016) 1-10";
    ../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/scripts/gen-book.sh  BookOfBibliography-$lang  pdflatex "CS-UCSP 2023-I BookOfBibliography-$lang (Plan2016) 1-10";
    ../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/scripts/gen-book.sh  BookOfDescriptions-$lang  pdflatex "CS-UCSP 2023-I BookOfDescriptions-$lang (Plan2016) 1-10";
end

#   ../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/scripts/gen-book.sh  BookOfUnitsByCourse 	latex    "CS-UCSP 2023-I BookOfUnitsByCourse (Plan2016) 1-10";
#   ../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/scripts/gen-book.sh  BookOfDeliveryControl  pdflatex "CS-UCSP 2023-I BookOfDeliveryControl (Plan2016) 1-10";
# Generate Books
#
# foreach auxbook (../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/tex/BookOf*-*.tex)
#    set book = `echo $auxbook | sed s/.tex//`
#    $book = `echo $book | sed s|../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/tex/||`
#    echo $book
#    #bibtex $auxfile
#    ../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/scripts/gen-book.sh  $book       	pdflatex "CS-UCSP 2023-I $book (Plan2016) 1-10";
# end

if($html == 1) then
    rm unified-curricula-main* ;
    ./scripts/gen-html-main.pl Peru-CS-UCSP;
    cp ../Curricula.in/css/curricula-main.css unified-curricula-main.css;

    latex unified-curricula-main;
    bibtex unified-curricula-main;
    latex unified-curricula-main;
    latex unified-curricula-main;

    dvips -o unified-curricula-main.ps unified-curricula-main.dvi;
    rm unified-curricula-main.ps unified-curricula-main.dvi unified-curricula-main.pdf;
    rm -rf ../Curricula.out/html/Peru/CS-UCSP/Plan2016;

    latex2html -t "Curricula CS-UCSP" \
    -dir "../Curricula.out/html/Peru/CS-UCSP/Plan2016/" -mkdir -toc_depth 4 \
    -toc_stars -local_icons -no_footnode \
    -show_section_numbers -long_title 5 \
    -address "Generado por <A HREF='http://socios.spc.org.pe/ecuadros/'>Ernesto Cuadros-Vargas</A> <ecuadros AT spc.org.pe>,               <A HREF='http://www.spc.org.pe/'>Sociedad Peruana de Computaci&oacute;n-Peru</A>,               basado en el modelo de la Computing Curricula de               <A HREF='http://www.computer.org/'>IEEE-CS</A>/<A HREF='http://www.acm.org/'>ACM</A>" \
    -white unified-curricula-main;

    mkdir -p ../Curricula.out/html/Peru/CS-UCSP/Plan2016/figs;
    cp "../Curricula.out/html/Peru/CS-UCSP/Plan2016/Curricula_CS_UCSP.html" "../Curricula.out/html/Peru/CS-UCSP/Plan2016/index.html";
    sed 's/max-width:50em; //g' ../Curricula.out/html/Peru/CS-UCSP/Plan2016/unified-curricula-main.css > ../Curricula.out/html/Peru/CS-UCSP/Plan2016/unified-curricula-main.css1;
    mv ../Curricula.out/html/Peru/CS-UCSP/Plan2016/unified-curricula-main.css1 ../Curricula.out/html/Peru/CS-UCSP/Plan2016/unified-curricula-main.css;

    cp ../Curricula.in/figs/pdf.jpeg ../Curricula.in/figs/star.gif ../Curricula.in/figs/none.gif ../Curricula.in/figs/*.png ../Curricula.out/html/Peru/CS-UCSP/Plan2016/figs/.;
    cp ../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/figs/*.png ../Curricula.out/html/Peru/CS-UCSP/Plan2016/figs/.;
    cp ../Curricula.in/country/Peru/logos/UCSP.jpg ../Curricula.out/html/Peru/CS-UCSP/Plan2016/figs/.;

    ./scripts/update-analytic-info.pl Peru-CS-UCSP;
endif

foreach lang ('ES' 'EN')
    ../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/scripts/gen-graph.sh big $lang;
end

./scripts/post-processing.pl Peru-CS-UCSP;
../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/scripts/gen-dot-maps.sh;
./scripts/update-cvs-files.pl Peru-CS-UCSP;
cp ../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/figs/*.svg ../Curricula.out/html/Peru/CS-UCSP/Plan2016/figs/.;

foreach lang ('ES' 'EN')
    ../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/scripts/compile-simple-latex.sh small-graph-curricula-$lang CS-UCSP-small-graph-curricula ../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/tex;
    ../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/scripts/gen-poster.sh $lang;
end

mkdir -p ../Curricula.out/html/Peru/CS-UCSP/Plan2016/figs;
mkdir -p ../Curricula.out/html/Peru/CS-UCSP/Plan2016/syllabi;
mkdir -p ../Curricula.out/html/Peru/CS-UCSP/Plan2016/docs;
cp ../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/syllabi/* ../Curricula.out/html/Peru/CS-UCSP/Plan2016/syllabi/.;
mv CS-UCSP.pdf "../Curricula.out/html/Peru/CS-UCSP/Plan2016/CS-UCSP Plan2016.pdf";
cp ../Curricula.out/pdfs/Peru-CS-UCSP/Plan2016/*.pdf ../Curricula.out/html/Peru/CS-UCSP/Plan2016/docs/.;
cp ../Curricula.out/pdfs/Peru-CS-UCSP/Plan2016/*.png ../Curricula.out/html/Peru/CS-UCSP/Plan2016/figs/.;

date >> ./log/Peru-CS-UCSP-time.txt;
more ./log/Peru-CS-UCSP-time.txt;
#./scripts/testenv.pl
#beep
printf '\a';
printf '\a';
