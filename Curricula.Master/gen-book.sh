#!/bin/csh

#--BEGIN-FILTERS--
set MainFile	= $1;		# BookOfSyllabi-ES
set Compiler    = $2;   	# pdflatex
set OutputFile  = "$3";

# ../Curricula.out/Peru/CS-ANR/cycle/2012-2/Plan2012/scripts/gen-book.sh  BookOfSyllabi-ES       	pdflatex "CS-ANR 2012-2 BookOfSyllabi (Plan2012) 1-10"

#--END-FILTERS--
set OutputInstDir=../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016;
set current_dir = `pwd`;

# # set semester = `grep -e "\Semester}" $InfoFile | cut -d"{" -f3 | cut -d\\ -f1`
# set InfoFile	= "../Curricula.in/country/Peru/institutions/UCSP/Computing/CS/institution-info.tex"

echo "../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/scripts/CompileTexFile.sh CS UCSP $Compiler $MainFile $OutputFile";
../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/scripts/CompileTexFile.sh CS UCSP $Compiler $MainFile "$OutputFile";

echo "cd ../Curricula.out/html/Peru/CS-UCSP/Plan2016/docs";
cd "../Curricula.out/html/Peru/CS-UCSP/Plan2016/docs";
#echo "pdftk A=$MainFile.pdf cat A1-1 output $MainFile-P1.pdf";
#pdftk A=$MainFile.pdf cat A1-1 output $MainFile-P1.pdf;
#convert $MainFile-P1.pdf $MainFile-P1.png;
#rm $MainFile-P1.pdf;
echo "mutool convert -o $MainFile-P1.png $MainFile.pdf 1-1";
mutool convert -o $MainFile-P%d.png $MainFile.pdf 1-1;

echo "cd $current_dir;"
cd $current_dir;
mkdir -p ../Curricula.out/pdfs/CS-UCSP/Plan2016;
echo "cp ../Curricula.out/html/Peru/CS-UCSP/Plan2016/docs/$MainFile.pdf ../Curricula.out/pdfs/Peru-CS-UCSP/Plan2016/.;"
cp "../Curricula.out/html/Peru/CS-UCSP/Plan2016/docs/$MainFile.pdf" "../Curricula.out/pdfs/Peru-CS-UCSP/Plan2016/.";

echo "cp ../Curricula.out/html/Peru/CS-UCSP/Plan2016/docs/$MainFile-P1.png ../Curricula.out/pdfs/Peru-CS-UCSP/Plan2016/.;"
cp "../Curricula.out/html/Peru/CS-UCSP/Plan2016/docs/$MainFile-P1.png" "../Curricula.out/pdfs/Peru-CS-UCSP/Plan2016/.";

