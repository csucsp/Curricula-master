#!/bin/csh
set intexfile   = $1    # intexfile
set outfile     = $2    # outtexfile
set workingdir  = $3    # directory
set current_dir = `pwd`

# ../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/scripts/compile-simple-latex.sh Computing-poster CS-UCSP-poster .../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/tex;

cd $workingdir;
rm $intexfile.ps $intexfile.dvi $intexfile.aux $intexfile.log;
latex $intexfile;
latex $intexfile;
#latex $intexfile;
dvips -P a0 $intexfile.dvi -o;
ps2pdf $intexfile.ps $intexfile.pdf;
rm $intexfile.dvi $intexfile.aux $intexfile.log;
cd $current_dir;
#rm $workingdir/$intexfile.ps
echo "$workingdir/$intexfile.pdf -> $workingdir/$outfile.pdf;"
mv $workingdir/$intexfile.pdf $workingdir/$outfile.pdf;
