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
#--END-FILTERS--
set curriculamain=curricula-main
setenv CC_Main $curriculamain
set current_dir = `pwd`
set UnifiedMain=unified-curricula-main
#set UnifiedMain = `echo $FullUnifiedMainFile | sed s/.tex//`

set InTexDir=../Curricula.in/lang/Espanol/Disciplines/Computing/CS/tex
set OutputInstDir=../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016
set OutputTexDir=../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/tex
set OutputFigsDir=../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/figs
set OutputHtmlDir=../Curricula.out/html/Peru/CS-UCSP/Plan2016
set OutputScriptsDir=.../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/scripts
set Country=Peru
set Language=Espanol     # Espanol
set current_dir = `pwd`

if($area == "CS") then
    cd ../Curricula.in/lang/Espanol/Disciplines/Computing/CS/tex/tex4fig
    foreach tmptex ('Pregunta1'  'Pregunta2'  'Pregunta3' 'Pregunta4'  'Pregunta5'  'Pregunta6' 'Pregunta7'  'Pregunta8'  'Pregunta9' 'Pregunta10'  'Pregunta11'  'Pregunta12' 'Pregunta13' 'Pregunta14')
	    if( ! -e $current_dir/../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/figs/$tmptex.eps || ! -e $current_dir/../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/figs/$tmptex.png ) then
		    echo "******************************** Compiling Questions $area-$institution ($tmptex) ...******************************** "
		    latex $tmptex;
		    dvips -o $tmptex.ps $tmptex;
		    ps2eps -f $tmptex.ps;
			convert $tmptex.eps $tmptex.png;
			cp $tmptex.eps $tmptex.png $current_dir/../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/figs;
		    ./scripts/updatelog.pl "$tmptex generated";
		    echo "******************************** File ($tmptex) ... OK ! ********************************";
	    else
		    echo "Figures $current_dir/../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/figs/$tmptex.eps already exist ... jumping";
			echo "Figures $current_dir/../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/figs/$tmptex.jpg already exist ... jumping";
			echo "Figures $current_dir/../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/figs/$tmptex.png already exist ... jumping";
	    endif
		rm -f *.aux *.dvi *.log *.ps *.eps $tmptex.jpg;
    end
    cd $current_dir;
endif

cd ../Curricula.in/lang/Espanol/Disciplines/Computing/CS/tex/tex4fig;
foreach tmptex ('CS' 'course-levels' 'course-coding')
	if( ! -e $current_dir/../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/figs/$tmptex.eps || ! -e $current_dir/../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/figs/$tmptex.png ) then
		echo "******************************** Compiling coding courses $area-$institution ($tmptex) ...******************************** "
		latex $tmptex;
		dvips -o $tmptex.ps $tmptex.dvi;
		ps2eps -f $tmptex.ps;
		convert $tmptex.eps -colorspace RGB $tmptex.png;
		cp $tmptex.eps $tmptex.png $tmptex.svg $current_dir/../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/figs;
		./scripts/updatelog.pl "$tmptex generated";
		echo "******************************** File ($tmptex) ... OK ! ********************************";
	else
		echo "Figures $current_dir/../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/figs/$tmptex.eps already exist ... jumping";
		echo "Figures $current_dir/../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/figs/$tmptex.png already exist ... jumping";
	endif
	rm -f *.aux *.dvi *.log *.ps *.eps $tmptex.jpg $tmptex.png;
end
echo "Creating coding courses figures ... done !";
cd $current_dir;

cd ../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/tex;
foreach tmptex ('pie-credits' 'pie-by-levels') # 'pie-horas'
	if( ! -e $current_dir/../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/figs/$tmptex.eps || ! -e $current_dir/../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/figs/$tmptex.png ) then
		echo "******************************** Compiling pies $area-$institution ($tmptex) ...******************************** ";
		latex $tmptex-main;
		dvips -o $tmptex.ps $tmptex-main;
		echo $area-$institution;
		ps2eps -f $tmptex.ps;
		convert $tmptex.eps $tmptex.png;
		cp $tmptex.eps $tmptex.png $current_dir/../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/figs;
		echo "******************************** File ($tmptex) ... OK ! ********************************";
	else
		echo "Figures $current_dir/../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/figs/$tmptex.eps already exist ... jumping";
		echo "Figures $current_dir/../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/figs/$tmptex.png already exist ... jumping";
	endif
	rm -f *.aux *.dvi *.log *.ps *.eps $tmptex.jpg $tmptex.png;
end
cd $current_dir;
echo "Creating pies ... done !";

cd ../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/tex;
foreach graphtype ('curves' 'spider')
	foreach tmptex ('CE' 'CS' 'IS' 'IT' 'SE')
		foreach lang ('ES' 'EN')
			set file=$graphtype-$area-with-$tmptex-$lang
			if( ! -e $current_dir/../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/figs/$file.eps || ! -e $current_dir/../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/figs/$file.png ) then
				echo "Compiling $file ...";
				latex $file-main;
				dvips -o $file.ps $file-main.dvi;
				ps2eps -f $file.ps;
				convert $file.eps $file.png;
				cp $file.eps $file.png $current_dir/../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/figs;
				echo "******************************** File ($file) ... OK ! ********************************";
			else
				echo "Figures $current_dir/../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/figs/$file.ps already exist ... jumping";
				echo "Figures $current_dir/../Curricula.out/Peru/CS-UCSP/cycle/2023-I/Plan2016/figs/$file.jpg already exist ... jumping";
			endif
			rm *.aux *.dvi *.log *.ps *.eps $file.jpg $file.png;
		end
	end
end

cd $current_dir;

#xgs -dSAFER -dEPSCrop -r300 -sDEVICE=jpeg -dBATCH -dNOPAUSE -sOutputFile=$tmptex.png $tmptex.eps
echo "gen-eps-files.sh Done !";

