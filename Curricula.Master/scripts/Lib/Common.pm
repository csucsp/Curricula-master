package Common;
# ! danger
# ? deberias estar aqui?
# * super importante

#use Lib::InformationSystems;
use Carp::Assert;
use Data::Dumper;
use Clone 'clone';
use Lib::Util;
# use Cwd;
use strict;
use Scalar::Util qw(looks_like_number);
use Number::Bytes::Human qw(format_bytes);
use PDF::API2;
use Lib::HotKey;
use File::Slurp qw(read_dir);
use open qw/:std :utf8/;
use Scalar::Util qw(looks_like_number);

our $command     = "";
our $filter      = "";
our $version	 = "";
our $discipline  = "";

our %list_of_areas			= ();
our %list_of_courses_per_area   = ();
our %config 				= ();
our %error 					= ();
			#$Common::error{"$codcour}{$lang"}{file} = $fullname;
			#$Common::error{"$codcour}{$lang"}{$env} = "I did not find $env";
our %general_info			= ();
our %dictionary				= ();
our %path_map				= ();
our %data					= (); # ! Pending to remove?
our %inst_list				= ();
our %map_hours_unit_by_course= ();
our %ku_info				= ();
our %acc_hours_by_course	= ();
our %acc_hours_by_unit		= ();

our $prefix_area 			= "";
our $only_macros_file		= "";

our %course_info          	= ();
our @codcour_list_sorted;
our %codcour_list_priority 	= ();
our %courses_by_semester 	= ();
our %counts              	= ();
our %antialias_info 	 	= ();
our %list_of_courses_per_axe	= ();

my %Numbers2Text = (0 => "OH",   1 => "ONE", 2 => "TWO", 3 => "THREE", 4 => "FOUR",
				   5 => "FIVE", 6 => "SIX", 7 => "SEVEN", 8 => "EIGHT", 9 => "NINE"
				  );
# our %template_files = (	"Syllabus" 		=> "in-syllabus-template-file"
# 						"DeliveryControl" 	=> "in-syllabus-delivery-control-file",
#						);
our %professor_role_order = ("C" => 0, "T" => 1, "L" => 2, "-" => 3);
our %position_ranking   = ("Director" => 1, "Professor" => 2);
our %dedication_ranking = ("TC"       => 1, "TP"        => 2);
our $Disciplines = "Disciplines";

# flush stdout with every print -- gives better feedback during
# long computations
$| = 1;
our $nolistsep = "\\setlist{nolistsep,leftmargin=*}";
our $svg_in_html = <<'MAP';
\begin{htmlonly}
	\begin{rawhtml}
		<div class="svg-container">
			<object type="image/svg+xml" data="./figs/<filename>.svg" width="<WIDTH>" height="<HEIGHT>" class="svg-content">
			</object>
		</div>
	\end{rawhtml}
\end{htmlonly}
MAP
#my $svg_in_html = <<'MAP';
#\begin{htmlonly}
#	\begin{rawhtml}
#		<div class="center">
#            <iframe scrolling="no" frameborder="0" src="./figs/<filename>.svg" width="958pt" height="609pt">
#                  <p><b>This browser is not able to show SVG: try Firefox, Chrome, Safari, or Opera instead.</b></p>
#            </iframe>
#        </div>
#	\end{rawhtml}
#\end{htmlonly}
#MAP

# ok
sub replace_accents($)
{
	my ($text) = (@_);
	$text =~ s/\\'A/Á/g;		$text =~ s/\\'a/á/g;		$text =~ s/\\'\{a\}/á/g;
	$text =~ s/\\'E/É/g;		$text =~ s/\\'e/é/g;		$text =~ s/\\'\{e\}/é/g;
	$text =~ s/\\'I/Í/g;		$text =~ s/\\'i/í/g;		$text =~ s/\\'\{i\}/í/g;
	$text =~ s/\\'O/Ó/g;		$text =~ s/\\'o/ó/g;		$text =~ s/\\'\{o\}/ó/g;
	$text =~ s/\\'U/U/g;		$text =~ s/\\'u/ú/g;		$text =~ s/\\'\{u\}/ú/g;
	$text =~ s/\\~N/Ñ/g;		$text =~ s/\\~n/ñ/g;		$text =~ s/\\~\{n\}/n/g;
	return $text;
}

sub replace_latex_label_to_latex_standard($)
{
	my ($text) = (@_);
	$text =~ s/Á/\\'A/g;		$text =~ s/á/\\'a/g;
	$text =~ s/É/\\'E/g;		$text =~ s/é/\\'e/g;
	$text =~ s/Í/\\'\{I\}/g;	$text =~ s/í/\\'\{i\}/g;
	$text =~ s/Ó/\\'O/g;		$text =~ s/ó/\\'o/g;
	$text =~ s/Ú/\\'U/g;		$text =~ s/ú/\\'u/g;		$text =~ s/ü/\\"u/g;
	$text =~ s/Ñ/\\~N/g;		$text =~ s/ñ/\\~n/g;
	return $text;
}

# ok
sub no_accents($)
{
	my ($text) = (@_);
	$text =~ s/Á/A/g;		$text =~ s/á/a/g;
	$text =~ s/É/E/g;		$text =~ s/é/e/g;
	$text =~ s/Í/I/g;		$text =~ s/í/i/g;
	$text =~ s/Ó/O/g;		$text =~ s/ó/o/g;
	$text =~ s/Ú/U/g;		$text =~ s/ú/u/g;
	$text =~ s/Ñ/N/g;		$text =~ s/ñ/n/g;
	return $text;
}

# http://www.htmlhelp.com/reference/html40/entities/latin1.html
# http://symbolcodes.tlt.psu.edu/web/codehtml.html
sub special_chars_to_html($)
{
	my ($text) = (@_);
	$text =~ s/Á/&Aacute;/g;		$text =~ s/á/&aacute;/g;
	$text =~ s/É/&Eacute;/g;		$text =~ s/é/&eacute;/g;
	$text =~ s/Í/&Iacute;/g;		$text =~ s/í/&iacute;/g;
	$text =~ s/Ó/&Oacute;/g;		$text =~ s/ó/&oacute;/g;
	$text =~ s/Ú/&Uacute;/g;		$text =~ s/ú/&uacute;/g;
	$text =~ s/Ñ/&Ntilde;/g;		$text =~ s/ñ/&ntilde;/g;
	return $text;
}

sub replace_special_chars($)
{
	my ($text) = (@_);
	$text =~ s/\\/\\\\/g;	$text =~ s/\//\\\//g;
	$text =~ s/\./\\./g;
	$text =~ s/\&/\\&/g;
	$text =~ s/\(/\\(/g;	$text =~ s/\)/\\)/g;
	$text =~ s/\[/\\[/g;	$text =~ s/\]/\\]/g;
	$text =~ s/\{/\\{/g;	$text =~ s/\}/\\}/g;
	$text =~ s/\+/\\\+/g;
	$text =~ s/\$/\\\$/g;
	$text =~ s/\^/\\\^/g;
	#$text =~ s/\-/\\\-/g;
	$text =~ s/\_/\\\_/g;
	$text =~ s/\?/\\\?/g;
	$text =~ s/\*/\\\*/g;
    $text =~ s/\|/\\\|/g;
	return $text;
}

sub prepare_text_for_latex($)
{
	my ($text) = (@_);
	$text =~ s/\\n/ /g;
	return $text;
}

sub ExpandTags($$)
{
	my ($InTxt, $lang) = (@_);
	if(not defined($lang) )
	{
		Util::print_message(Util::red("lang not defined !"));
		Util::print_error("lang not defined !");
	}
	if( not $lang eq "" )
	{
		$InTxt =~ s/<LANG-EXTENDED>/$lang/g;
		$InTxt =~ s/<LANG>/$Common::config{dictionaries}{$lang}{lang_prefix}/g;
		$InTxt =~ s/<LANG_FOR_LATEX>/$Common::config{dictionaries}{$lang}{lang_for_latex}/g;
	}
	$InTxt =~ s/<DISCIPLINE>/$Common::config{discipline}/g;
	$InTxt =~ s/<AREA>/$config{area}/g;
	$InTxt =~ s/<INST>/$Common::config{institution}/g;
	$InTxt =~ s/<COUNTRY>/$config{country_without_accents}/g;
	$InTxt =~ s/<CYCLE>/$config{Semester}/g;
	$InTxt =~ s/<CURRICULA_VERSION>/$config{CurriculaVersion}/g;
	$InTxt =~ s/<PLAN>/$config{Plan}/g;
	return $InTxt; 
}

sub ExpandTags2($$$$$$$)
{
	my ($InTxt, $country, $institution, $area, $semester, $curricula_version, $lang) = (@_);
	# Util::print_message("country:$country, institution:$institution, area:$area, semester:$semester, curricula_version:$curricula_version, lang:$lang");
	#Util::print_message("ExpandTags2,  input InTxt=$InTxt");
	if(not defined($InTxt))
	{	Util::print_error("Something wrong here !"); 	}
	my $discipline 	= $inst_list{$country}{$institution}{$area}{discipline};

	#print Dumper(%{$inst_list{$country}});
	#Util::print_message("$country     eq $inst_list{$country}{$institution}{$area}{country}");
	if( not defined($inst_list{$country}{$institution}{$area}{country}) )
	{
		Util::print_message("Some problems ! country=".Util::red($country)
							.", institution=".Util::red($institution)
							.", area=".Util::red($area)
							.", lang=".Util::red($lang)
							);
		Util::print_message("I guess you forgot to add this information at: ".Util::red(GetInternalTemplate("institutions-list")));
		#$inst_list{$country}{$institution}{$area}{country}
		# print Dumper(\%inst_list); 
		#Util::print_message("inst_list{$country}{$institution}{$area}{country}");
		#Util::print_error("See stack !");
		exit;
	}
	if( not $country     eq $inst_list{$country}{$institution}{$area}{country} )
	{
		Util::print_message("$country neq $inst_list{$country}{$institution}{$area}{country}");
	}
	assert($institution eq $inst_list{$country}{$institution}{$area}{institution});
	
	my $country_without_accents = $inst_list{$country}{$institution}{$area}{country_without_accents};
	my $filter					= $inst_list{$country}{$institution}{$area}{filter};
	my $plan					= $inst_list{$country}{$institution}{$area}{plan};
	my $version 				= $inst_list{$country}{$institution}{$area}{version};

	if( not $semester eq "" )
	{	$InTxt =~ s/<CYCLE>/$semester/g;
	}
	if( not $lang eq "" )
	{	$InTxt =~ s/<LANG-EXTENDED>/$lang/g;
		$InTxt =~ s/<LANG>/$Common::config{dictionaries}{$lang}{lang_prefix}/g;
		$InTxt =~ s/<LANG_FOR_LATEX>/$Common::config{dictionaries}{$lang}{lang_for_latex}/g;
	}
	$InTxt =~ s/<DISCIPLINE>/$discipline/g;
	$InTxt =~ s/<AREA>/$area/g;
	$InTxt =~ s/<INST>/$institution/g;
	$InTxt =~ s/<COUNTRY>/$country_without_accents/g;
	$InTxt =~ s/<PLAN>/$plan/g;
	if( not $curricula_version eq "" )
	{	$InTxt =~ s/<CURRICULA_VERSION>/$curricula_version/g;	
	}
	#Util::print_message("ExpandTags2, output InTxt=$InTxt\n");
	return $InTxt; 
}

# ok
sub GetInternalTemplate($)
{
	my ($acro) = (@_);
	if(defined($path_map{$acro}))
	{	return $path_map{$acro};	}
	Util::halt("GetInternalTemplate: Template not recognized ($acro), Did you define it?");
}

# ok 
sub GetTemplateForAnotherInstitution($$$$$$$)
{
	my ($key, $country_without_accents, $institution, $area, $semester, $curricula_version, $lang) = (@_);
	return ExpandTags2(GetInternalTemplate($key), $country_without_accents, $institution, $area, $semester, $curricula_version, $lang);
}

sub GetExpandedTemplateWithLang($$)
{
	my ($acro, $lang) = (@_);
	return ExpandTags(GetInternalTemplate($acro), $lang);
}

sub GetTemplate($)
{
	my ($acro) = (@_);
	return ExpandTags2(GetInternalTemplate($acro), 
					   $config{country_without_accents}, $config{institution}, $config{area}, 
					   (defined($config{Semester})?$config{Semester}:""), 
					   (defined($config{CurriculaVersion})?$config{CurriculaVersion}:""), "");
}

sub copy_file_expanding_tags($$$)
{
	my ($InFile, $OutFile, $lang) = (@_);
	my $infile_txt = Util::read_file($InFile);
	$infile_txt = ExpandTags($infile_txt, $lang);
	Util::print_message("Copying and expanding to $lang: $InFile -> $OutFile");
	Util::write_file($OutFile, $infile_txt);
}

sub GetInCountryBaseDir()
{
    return $path_map{InDir}."/country/<COUNTRY>";
}

sub GetInCountryBaseDirExt($)
{
	my ($country) = (@_);
	my $text = GetInCountryBaseDir();
	$text =~ s/<COUNTRY>/$country/g;
    return $text;
}

sub GetOutCountryBaseDir()
{
    return $path_map{OutDir}."/country/<COUNTRY>";
}

sub GetInstitutionDir()
{
	return GetInCountryBaseDir()."/institutions/<INST>";
}

sub GetProgramInDir()
{
	return GetInstitutionDir()."/<DISCIPLINE>/<AREA>";
}

sub GetProgramInDirExt($$$$)
{
	my ($country_without_accents, $discipline, $area, $institution) = (@_);
	return ExpandTags2(GetInstitutionDir(), $country_without_accents, $institution, $area, "", "", "");
}

sub GetInstitutionInfo()
{
	return GetInstitutionDir()."/<INST>.tex";
}

sub format_menu_for_syllabus_dir($)
{
	my ($lang) = (@_);
	# my $syllabus_base_dir = GetExpandedTemplateWithLang("InSyllabiContainerDir", $lang);
	my @temp_list;
	foreach my $item ( sort {length($b) <=> length($a)} @{$config{SyllabiDirs}{$lang}} )
	{	if( $item =~ m/Empty/g or $item =~ m/temp/g or $item =~ m/trash/ig )
		{ next; }
		my $exists = 0;
		foreach (@temp_list)
		{	if( m/^$item\// )
			{	$exists = 1;	last;	}
		}
		if( $exists == 0 )
		{	push(@temp_list, $item);	}
	}
	my %syllabus_dirs_map = ();
	my $i = 1;
	foreach my $item ( sort {$a cmp $b} @temp_list )
	{	$syllabus_dirs_map{"$i"} = $item;
		$i++;
	}
	return %syllabus_dirs_map;
}

sub PrintAA
{
    my($test, %aa) = @_;
    print $test . "\n";
    foreach (keys %aa)
    {
        print $_ . " : " . $aa{$_} . "\n";
    }
}

#my(%hash) = ( 'aaa' => 1, 'bbb' => 'balls', 'ccc' => \&PrintAA );
#PrintAA("test", %hash);

sub get_menu_option
{
	my ($prompt, %syllabus_dirs_map) = (@_);
	foreach my $key (sort {$a cmp $b} keys %syllabus_dirs_map)
	{
		Util::print_message(sprintf("[%s] %s", Util::yellow(sprintf("%2s", $key)), $syllabus_dirs_map{$key}));
	}
	do {
		print("$prompt");
		my $key = <STDIN>;
		chomp $key;
		$key = uc($key);
		if( defined($syllabus_dirs_map{$key}) )
		{	return $key;	}
		Util::print_message(Util::red("I don't find this option \"$key\" ..."));
	} while(1);
}

sub save_courses_by_competence($$$)
{
	my ($text, $competence, $lang)  = (@_);
	my $OutputCompetencesDir = GetExpandedTemplateWithLang("OutputCompetencesDir", $lang);
	my $filename 	= "course-by-outcome-$competence";
	my $fullname	= "$OutputCompetencesDir/$filename.tex";
	Util::print_message("save_courses_by_competence is Generating $fullname");
	Util::write_file($fullname, $text);
	return "\\OutputCompetencesDir/$filename";
}

sub filter_non_valid_chars($)
{
	my ($text) = (@_);
	$text = no_accents($text);
	$text =~ s/ //g;
	return $text;
}

# ok
sub get_alias($)
{
	my ($codcour) = (@_);
# 	if(defined($course_info{$codcour}))
# 	{
	    if( defined($course_info{$codcour}{alias}) )
	    {	return $course_info{$codcour}{alias};		}
# 	}
	else{	return "";	}
}

# Verify if it is just an alias for a real course or directly the codcour
sub unmask_codcour2($$)
{
	my ($codcour, $context_msg) = (@_);
	my $temp = $codcour;
	if( defined($course_info{$codcour}) )
	{     return $codcour;		}
	if( defined($antialias_info{$codcour}) )
	{	return $antialias_info{$codcour};		}
	Util::print_error("$context_msg: codcour \"$temp($codcour)\" does not exist ... ");
	return $codcour;
}

# Verify if it is just an alias for a real course or directly the codcour
sub unmask_codcour($)
{
	my ($codcour) = (@_);
	return unmask_codcour2($codcour, "");
}

# ok
sub get_course_prefix($)
{
	my ($codcour) = (@_);
# 	print "x$codcour, alias=$course_info{$codcour}{alias}\n";
	# $codcour = $course_info{$codcour}{alias};
	if($codcour =~ m/(\D*)(.)/) # \D non-digit character
	{	return $1;	}
	return "";
}

sub get_level($)
{
	my ($codcour) = (@_);
	if($codcour =~ m/([A-Z]*)(.)/) # \D non-digit character
	{	return $2;	}
	return "";
}

sub get_link($$)
{
	my ($file, $lang) = (@_);
	my $link .= "<a href=\"$file\">$file".get_language_icon($lang)."</a>\n";
	return $link;
}

sub get_size($)
{
	my ($file) = (@_);
	return format_bytes(-s $file); # 4.5M
}

sub getPDFnPages($)
{
	my ($file) = (@_);
	if(-e $file )
	{	
		#my $pdf 	= PDF->new($file) or Util::print_color("Error trying to find: $file");
		#my $nPages	= $pdf->numPages();
		#Util::print_message("PDF: $file -> $nPages Pages detected ...");
		#return $nPages;
		my $pdf = PDF::API2->open($file);
    	my $nPages = $pdf->pages;
		# Util::print_message("PDF: $file -> $nPages Pages detected ..."); exit;
		return $nPages;
	}
	else
	{	Util::print_color("Error trying to find: $file");
		return 0;
	}
}


sub get_link_and_size($$)
{
	my ($file, $lang) = (@_);
	my $size = get_size($file);
	my $link .= "<a href=\"$file\">$file ($size)".get_language_icon($lang)."</a>\n";
	return $link;
}

sub get_language_icon($)
{
    my ($lang) = (@_);
	my $FigsDirRelativePath = Common::GetTemplate("FigsDirRelativePath");
	my $lang_prefix = $Common::config{dictionaries}{$lang}{lang_prefix};
	my $link  = "<img src=\"$FigsDirRelativePath/pdf.jpeg\" style=\"border: 0px solid ; width: 16px; height: 16px;\">";
	   $link .= "<img src=\"$FigsDirRelativePath/$lang_prefix.png\" style=\"border: 0px solid ; width: 16px; height: 16px;\">";
    return $link;
}

sub get_link_with_language_icon($$$)
{
	my ($text, $link, $lang) = (@_);
	return  "<a href=\"$link\">$text ".get_language_icon($lang)."</a>";
}

sub get_syllabi_language_links($$)
{
    my ($prev_tex, $codcour) = (@_);
	my ($output_txt, $sep) 		 = ("\n", "");
	foreach my $lang (@{$Common::config{SyllabusLangsList}})
	{
	    my $lang_prefix = $Common::config{dictionaries}{$lang}{lang_prefix};
		my $label 	= "$codcour-$lang_prefix.pdf";
		my $link	= "syllabi/$label";
		my $file    = GetTemplate("OutputSyllabiDir")."/$label";
		my $size	= get_size($file);
		$output_txt .= "$sep$prev_tex".get_link_with_language_icon("", $link, $lang);
	    $sep = ",\n";
	}
    return $output_txt;
}

sub get_small_icon($$)
{
    my ($icon, $alt) = (@_);
	my $OutputDocsDirRelativePath = Common::GetTemplate("OutputDocsDirRelativePath");
	my $pdflink .= "\\begin{htmlonly}\n";
	$pdflink    .= "\t\\begin{rawhtml}\n";
	$pdflink    .= "\t\t<img alt=\"$alt\" src=\"./$OutputDocsDirRelativePath/$icon\" style=\"border: 0px solid ; width: 16px; height: 16px;\">\n";
	$pdflink    .= "\t\\end{rawhtml}\n";
	$pdflink    .= "\\end{htmlonly}\n";
    return $pdflink;
}

sub get_course_link($$)
{
	my ($codcour, $lang) = (@_);
	#print $codcour;
	if($codcour eq "")
	{	assert(0);	}
	my $course_name 		= Common::prepare_text_for_latex($Common::course_info{$codcour}{$lang}{course_name});
	my $course_full_label	= "$codcour. $course_name";
	my $codcour_sem_label   = format_semester_label_in_latex($course_info{$codcour}{semester}, $lang);
	my $course_link	   		= "\\htmlref{$course_full_label}{sec:$codcour}~";
	   $course_link   	   .= "($codcour_sem_label-$config{dictionaries}{$lang}{Pag}~\\pageref{sec:$codcour})";
	return $course_link;
}

sub get_pdf_link($)
{
	my ($codcour) = (@_);
	my $pdflink   	 = "\n\\begin{htmlonly}\n";
        $pdflink 	.= "\t\\begin{rawhtml}";
        $pdflink 	.= Common::get_syllabi_language_links("\t\t", $codcour)."\n";
        $pdflink 	.= "\t\\end{rawhtml}\n";
        $pdflink 	.= "\\end{htmlonly}\n";
	return $pdflink;
}

sub format_connection_beetween_two_nodes($$$$)
{
	my ($source, $target, $style, $comment) = (@_);
	my $output_txt = "";
	$output_txt = "\t\"$source\"->\"$target\"";
	if( not $style eq "" ) # Do we have any style, then add it
	{	$output_txt .= " [$style]";		}
	$output_txt .= ";";
	if( not $comment eq "" ) # Do we have any comment
	{	$output_txt .= " # $comment";		}
	$output_txt .= "\n";
	return $output_txt;
}

sub generate_connection_between_two_courses($$$)
{
	my ($source, $target, $lang) = (@_);
	my ($output_txt, $prefix) = ("", "");
	my ($style, $comment)     = ("", "");
	if($source =~ m/(.*?)=(.*)/)
	{
		my ($inst, $prereq) = ($1, $2);
		assert( $inst eq $Common::config{institution});
		return (format_connection_beetween_two_nodes($prereq, $target, $style, $comment), 0);
	}
	my ($critical_path_style, $width) = ("", 4);
	if( defined($Common::course_info{$source}{critical_path}{$target}))
	{			$style .= "penwidth=$width,label=\"$Common::config{dictionaries}{$lang}{CriticalPath}\"";	}
	if( defined($course_info{$target}{prereq_to_hide}{$source}) )
	{	$prefix  = "# ";
		$comment = "# (H) Hide this link just in the picture";	
	}
	$output_txt = $prefix.format_connection_beetween_two_nodes($source, $target, $style, $comment);
	return ($output_txt, 1);
}

sub generate_invisible_connection_between_two_courses($$)
{
	my ($source, $target) = (@_);
	my ($output_txt, $comment) = ("", "");
	
	if( defined($course_info{$target}{prereq_invis}{$source}) )
	{	my $style   = "style=dotted, penwidth=1";
		my $comment = "Invisible link ... just to arrange nodes ...";
		return format_connection_beetween_two_nodes($source, $target, $style, $comment);
	}
	else{
		Util::print_error("generate_invisible_connection_between_two_courses: something wrong! $target has not $source as invisible connection !")
	}
	return ($output_txt);
}

sub GetCourseNameWithLink($$$$)
{
    my ($codcour, $lang, $recommended, $extra_link) = (@_);
	my $course_name = Common::prepare_text_for_latex($Common::course_info{$codcour}{$lang}{course_name});
	my $CourseName  = "\\htmlref{$course_name}{sec:$codcour}";
# 	Util::print_message("codcour=$codcour");
# 	print Dumper ( \%{$Common::course_info{$codcour}} );
	if($recommended == 1 && not $Common::course_info{$codcour}{recommended} eq "")
	{
		my ($rec_courses, $sep) = ("", "");
		foreach my $rec (split(",", $Common::course_info{$codcour}{recommended}))
		{
			$rec = Common::unmask_codcour($rec);
			my $semester_rec 	  = $Common::course_info{$rec}{semester};
			$rec_courses 		 .= "$sep\\htmlref{$rec $Common::course_info{$rec}{$lang}{course_name}}{sec:$codcour}";
			my $codcour_sem_label = format_semester_label_in_latex($semester_rec, $lang);
			$rec_courses .= "($codcour_sem_label)";
			$sep = ", ";
# 			print "$rec(C)\n";
		}
		$CourseName .= "\\footnote{$Common::config{dictionary}{AdviceRecCourses}: $rec_courses.}";
	}
	$CourseName .= " ($Common::config{dictionary}{Pag}~\\pageref{sec:$codcour})";
	if( not $extra_link eq "" )
	{	$CourseName .= "~$extra_link";		}
	return $CourseName;
}

sub GetCourseHyperLink($$)
{
    my ($codcour, $link) = (@_);
#     my $link = Common::GetTemplate("LinkToCurriculaBase");
    my $semester 		= $Common::course_info{$codcour}{semester};
	my $lang     		= $config{language_without_accents};
	my $SemesterInfo 	= format_semester_label_in_plain_text($semester, $lang);
    #my $SemesterInfo = "$Common::course_info{$codcour}{semester}$Common::config{dictionary}{ordinal_postfix}{$semester} $Common::config{dictionary}{Sem}";
    my $hyperlink = "<li><a href=\"$link\">$codcour. $course_info{$codcour}{$lang}{course_name} ($SemesterInfo)</a></li>\n";
    return $hyperlink;
}

sub format_course_label($$)
{
	my ($codcour, $color) = (@_);
	my $label 	= "\\colorbox{$color}{\\htmlref{$codcour}{sec:$codcour}}";
	return $label;
}

sub InsertSeparator($)
{
    my ($input) = (@_);
    my $output  = "|";
    my $count = 0;
    while($input =~ m/([c|l|r|X|p])/g)
    {
        my $c    = $1;
        if($c eq "p")
        {       if($input =~ m/(\{.*?\})/g)
                {   $output .= "$c$1|";       }
        }
        else
        {   $output .= "$c|";       }
        #Util::print_message("$input->$output");
        $count++;
        #exit if($count == 20);
    }
    return $output;
}

sub read_pages()
{
        my $filename    = Common::GetTemplate("file_for_page_numbers");
        %{$config{pages_map}}   = ();

	if(-e $filename)
        {
	    my $file_txt    = Util::read_file($filename);
	    # \newlabel{sec:FG102}{{4}{133}{Contenido detallado por curso\relax }{section*.69}{}}
	    while($file_txt =~ m/\\newlabel\{(.*?)\}\{\{(.*?)\{(.*?)\}/g)
	    {
		    my ($label, $ref, $page) = ($1, $2, $3);
		    $config{pages_map}{$label} = $page;
		    # Util::print_message("pages_map{$label} = $page");
	    }
	}
        #return %pages_map;
}

sub read_dot_template($$)
{
	my ($size, $lang) = (@_);
	my @dot_files = ("in-country-graph-item.dot", "in-discipline-graph-item.dot", 
					 "in-area-graph-item.dot"   , "in-institution-graph-item.dot");
	#my $dot_txt = "";
	my $dot_file = "";
	foreach my $one_dot_file (@dot_files)
	{
		my $template_file = Common::GetExpandedTemplateWithLang($one_dot_file, $lang);
		#Util::print_message("template_file=$template_file");
		$template_file = Common::ExpandTags($template_file, $lang);
		$template_file =~ s/<SIZE>/$size/g;
		if( -e $template_file )
		{	#printf("$Util::icons{ok} %s\n", Util::green("$template_file"));
			$dot_file = $template_file;
			#$dot_txt = Util::read_file($template_file);
		}
		else
		{	
			Util::print_message(" ".("$Util::icons{bulb}"x3)." ".
								Util::highlight_filename($template_file)." ".
								Util::red("does not exist ! no problem"));	
		}
	}
	return $dot_file;
}

sub read_outcomes_labels()
{
	my $filename     	 = Common::GetTemplate("file_for_page_numbers");
	$config{outcomes_map}= ();

	if(-e $filename)
	{
		my $file_txt     = Util::read_file($filename);
		while($file_txt  =~ m/\\newlabel\{out:Outcome(.*?)\}\{\{(.*?)\}/g)
		{
			my ($outcome, $letter) = ($1, $2);
			if($outcome eq "\\IeC {\\~n}"){	$outcome = "ñ";		}
			$config{outcomes_map}{$outcome} = $letter;
			if( $letter =~ m/\\.n/)
			{       $config{outcomes_map}{$outcome} = "ñ";          }
		}
	}
}

sub read_pagerefs()
{
    #%{$config{pages_map}}     =
    Common::read_pages();
    #%{$config{outcomes_map}}  =
    Common::read_outcomes_labels();
    #print Dumper(%{$Common::config{outcomes_map}});
    Util::check_point("read_pagerefs");
}

sub format_semester_label_in_latex($$)
{
	my ($semester, $lang) = (@_);
	return "$semester\$^{$config{dictionaries}{$lang}{ordinal_postfix}{$semester}}\$~$config{dictionaries}{$lang}{Sem}";
}

sub format_semester_label_in_plain_text($$)
{
	my ($semester, $lang) = (@_);
	return "$semester$config{dictionaries}{$lang}{ordinal_postfix}{$semester} $config{dictionaries}{$lang}{Sem}";
}

# ok
sub format_semester_label_in_dot($$)
{
	my ($semester, $lang) = (@_);
	my $rpta  = "\"".format_semester_label_in_plain_text($semester, $lang)." ";
	   $rpta .= "($config{credits_this_semester}{$semester} $config{dictionaries}{$lang}{cr})\"";
	return  $rpta;
}

sub set_version($)
{
	my ($version) = (@_);
	$config{graph_version} = $version;
	if($config{graph_version} == 1)
	{
	      $config{sep} = "|";
	      $config{hline} = "\\hline";
	}
	elsif($config{graph_version} == 2)
	{
	      $config{sep} = "";
	      $config{hline} = "";
	}
	else
	{	Util::halt("Version \"$version\" is not supported ...");	}
}

sub CreateDir($)
{
	my ($dir) = (@_);
	$dir = ExpandTags($dir, "");
	if( -e $dir )
	{	Util::print_message("$Util::icons{ok} file exists $dir " );	}
	else
	{	Util::print_message("$Util::icons{star} ".Util::green("+Creating")."   $dir ..." );		}
	system("mkdir -p $dir");
}
	
sub set_global_variables()
{
	$config{bibstyle}   = "apalike";
	$config{InScriptsDir}	 = "$config{in}/scripts";
	$config{GithubMasterDir} = "https://github.com/ecuadros/Curricula/edit/master/Curricula.Master";

	#Util::print_message( Util::red("config{OutputInstDir}=$config{OutputInstDir}") );
	CreateDir($config{OutputInstDir});
	#Util::print_message( Util::red("Here !") );

	$config{OutputTexDir} 	= "$config{OutputInstDir}/tex";
	CreateDir($config{OutputTexDir});
	$config{OutputJsonDir} 	= "$config{OutputInstDir}/json";
	CreateDir($config{OutputJsonDir});
	CreateDir("$config{OutputInstDir}/syllabi");

	#  ./Curricula.out/html/Peru/CS-UTEC/Plan 2018
	$config{OutputDocsDirRelativePath} 	= "docs";
	$config{FigsDirRelativePath}		= "figs";
	$config{OutputHtmlDir} 	   = "$config{OutHtmlBase}/$config{country_without_accents}/$config{area}-$config{institution}/$config{Plan}";
    $config{OutputHtmlFigsDir} = "$config{OutputHtmlDir}/$config{FigsDirRelativePath}";
	CreateDir($config{OutputHtmlFigsDir});
	
	$config{OutputHtmlDocsDir} = "$config{OutputHtmlDir}/$config{OutputDocsDirRelativePath}";
    CreateDir($config{OutputHtmlDocsDir});

	#my $cwd = getcwd();
	my $cmd = "ln -f -s ./$config{OutputHtmlDir} $config{OutputInstDir}/html";
# 	Util::print_message($cmd);
    system($cmd);

	$config{OutputPrereqDir} 	= "$config{OutputTexDir}/prereq";
	CreateDir($config{OutputPrereqDir});

	$config{OutputDotDir} 	= "$config{OutputInstDir}/dot";
	CreateDir($config{OutputDotDir});

	$config{OutputBinDir} 		= "$config{OutputInstDir}/bin";
	CreateDir($config{OutputBinDir});

	$config{OutputSqlDir}        = "$config{OutputInstDir}/gen-sql";
	CreateDir($config{OutputSqlDir});

	$config{OutputMain4FigDir}  = "$config{OutputInstDir}/tex/main4figs";
	CreateDir($config{OutputMain4FigDir});

	$config{OutputFigsDir}       = "$config{OutputInstDir}/$config{FigsDirRelativePath}";
	CreateDir($config{OutputFigsDir});

	$config{OutputAdvancesDir}  = "$config{OutputInstDir}/advances";
	CreateDir($config{OutputAdvancesDir});

# 	$config{OutputPrereqDir}    = "$config{OutputInstDir}/pre-prerequisites";
# 	CreateDir($config{OutputPrereqDir});

	$config{OutputScriptsDir}	= "$config{OutputInstDir}/scripts";
	CreateDir($config{OutputScriptsDir});

	$config{OutputCompetencesDir}	= "$config{OutputTexDir}/competences";
	CreateDir($config{OutputCompetencesDir});

	$config{InLangBaseDir}	 	= "$config{in}/lang";
	$config{InLangDefaultDir}	= "$config{InLangBaseDir}/$config{language_without_accents}";
	$config{InLangCommonDir}	= "$config{InLangBaseDir}/Common";

	$config{InPeopleDir}		= $config{in}."/people";
	$config{OutputPdfDir}		= "$config{out}/pdfs";
	CreateDir($config{OutputPdfDir});
	Util::check_point("set_global_variables");
}

# OK
sub set_initial_paths()
{
	Util::precondition("set_global_variables");
	assert(defined($config{language_without_accents}) and defined($config{discipline}));

	$path_map{OutputDocsDirRelativePath}	= $config{OutputDocsDirRelativePath};
	$path_map{FigsDirRelativePath}			= $config{FigsDirRelativePath};
	
	$path_map{"curricula-main"}				= "curricula-main.tex";
	$path_map{"unified-main-file"}			= "unified-curricula-main.tex";
    $path_map{"file_for_page_numbers"}		= "curricula-main.aux";

	$path_map{"country"}					= $config{country};
	$path_map{"country_without_accents"}	= $config{country_without_accents};
	$path_map{"language"}					= $config{language};
	$path_map{"language_without_accents"}	= $config{language_without_accents};

################################################################################################################
# InputsDirs
	$path_map{InLangBaseDir}			= $config{InLangBaseDir};
	$path_map{InLangCommonDir}			= $config{InLangCommonDir};
	$path_map{InLangDefaultDir}			= $config{InLangDefaultDir};
	$path_map{InLangDir}				= $path_map{InDir}."/lang/<LANG-EXTENDED>";
	$path_map{InLangCommonDir}			= $path_map{InDir}."/lang/Common";
	$path_map{InAllTexDir}				= $path_map{InDir}."/All.tex";	
	$path_map{InTexDir}					= $path_map{InDir}."/lang/<LANG-EXTENDED>/$Disciplines/<DISCIPLINE>/<AREA>/tex";
	$path_map{InStyDir}					= $path_map{InDir}."/lang/<LANG-EXTENDED>/$Disciplines/<DISCIPLINE>/<AREA>/sty";
	$path_map{InOthersDir}				= $path_map{InDir}."/lang/<LANG-EXTENDED>/$Disciplines/<DISCIPLINE>/<AREA>/others";
	$path_map{InCSStyDir}				= $path_map{InDir}."/lang/<LANG-EXTENDED>/$Disciplines/<DISCIPLINE>/CS/sty"; # Constant for CS
	$path_map{"in-acronyms-base-file"}	= $path_map{InDir}."/lang/<LANG-EXTENDED>/$Disciplines/<DISCIPLINE>/tex/<DISCIPLINE>-acronyms.tex";
	$path_map{SpiderChartInfoDir}		= $path_map{InDir}."/lang/<LANG-EXTENDED>/$Disciplines/<DISCIPLINE>/tex/SpiderChartInfo";

	$path_map{InStyAllDir}				= $path_map{InDir}."/All.sty";
	$path_map{InFigsDir}				= $path_map{InDir}."/figs";
	$path_map{InSyllabiContainerDir}		= $path_map{InLangDir}."/cycle/$config{Semester}/Syllabi";
	$path_map{InSyllabiCommonContainerDir}	= $path_map{InLangCommonDir}."/cycle/$config{Semester}/Syllabi";
	#$path_map{InSyllabiDir}				= "$path_map{InSyllabiContainerDir}/EmptySyllabi/<COUNTRY>/<INST>/<AREA>/<LANG-EXTENDED>"; 
	#$path_map{InSyllabiCommonDir}		= "$path_map{InSyllabiContainerDir}/EmptySyllabi/<COUNTRY>/<INST>/<AREA>/Common"; 

	$path_map{InHtmlDir}				= $path_map{InLangDefaultDir}."/All.html";
	$path_map{InTexAllDir}				= $path_map{InLangDefaultDir}."/All.tex";
	$path_map{InDisciplinesBaseDir}		= $path_map{InDir}."/$Disciplines";
	$path_map{InGeneralAreaDir}			= $path_map{InDisciplinesBaseDir}."/<DISCIPLINE>/<AREA>";
	$path_map{InDisciplineDir}			= "$path_map{InDisciplinesBaseDir}/<DISCIPLINE>";
	$path_map{InDisciplineTexDir}		= $path_map{InDisciplineDir}."/tex";
	$path_map{InDisciplineDotDir}		= $path_map{InDisciplineDir}."/dot";
	$path_map{InDisciplineConfigDir}	= $path_map{InDisciplineDir}."/config";

	$path_map{InAreaDir}				= $path_map{InDisciplineDir}."/<AREA>";
	$path_map{InAreaTexDir}				= $path_map{InAreaDir}."/tex";
	$path_map{InAreaConfigDir}			= $path_map{InAreaDir}."/config";

	$path_map{InScriptsDir}				= "./scripts";
	# Here ok InCountryDir
	$path_map{InCountryDir}				= $path_map{InDir}."/country/<COUNTRY>";
	# Here ok InCountryTexDir
	$path_map{InCountryTexDir}			= $path_map{InCountryDir}."/<DISCIPLINE>/<AREA>/<AREA>.tex";
	
	$path_map{InInstUCSPDir}			= GetProgramInDirExt("Peru", "Computing", "CS", "UCSP");
	$path_map{InInstitutionsByCountryBaseDir} = "$path_map{InDir}/country/<COUNTRY>/institutions";
	$path_map{InInstitutionBaseDir}		= "$path_map{InInstitutionsByCountryBaseDir}/<INST>";
	$path_map{InInstitutionConfigDir}	= "$path_map{InInstitutionsByCountryBaseDir}/<INST>";
	$path_map{InInstitutionCycleDir}	= "$path_map{InInstitutionConfigDir}/cycle";

	$path_map{InInstitutionDisciplineConfigDir}	= "$path_map{InInstitutionsByCountryBaseDir}/<INST>/<DISCIPLINE>";
	# Here ok InProgramTexDir
	$path_map{InProgramTexDir}			= GetProgramInDir();
	# Here ok InEquivDir
	$path_map{InEquivDir}				= $path_map{InProgramDir}."/equivalences";
	# Here ok InLogosDir
	$path_map{InLogosDir}				= $path_map{InCountryDir}."/logos";
	# Here InTemplatesDot
	$path_map{InTemplatesDot}			= $path_map{InCountryDir}."/dot";
	$path_map{InPeopleDir}				= $config{InPeopleDir};
	# Here ok InFacultyPhotosDir
	$path_map{InFacultyPhotosDir}		= $path_map{InProgramDir}."/photos";
	$path_map{InFacultyIconsDir}		= $path_map{InDir}."/html";

	$path_map{InProgramSemesterDir}		= $path_map{InProgramDir}."/cycle/$config{Semester}";
	$path_map{InSemesterDir}			= $path_map{InDir}."/cycle";
#############################################################################################################################
# OutputsDirs
	$path_map{OutHtmlBase}				= "$config{out}/html";
	$path_map{OutputInstDir}			= $config{OutputInstDir};
	$path_map{OutputTexDir}				= $config{OutputTexDir}; #$config{Plan}
	$path_map{OutputJsonDir}			= $config{OutputJsonDir};
	$path_map{OutputBinDir}				= $config{OutputBinDir};
	$path_map{OutputLogDir}				= $config{out}."/log";
	$path_map{OutputHtmlDir}			= $config{OutputHtmlDir};
	$path_map{OutputHtmlDocsDir}		= $config{OutputHtmlDocsDir};
	$path_map{OutputHtmlFigsDir}		= $config{OutputHtmlFigsDir};
	$path_map{OutputHtmlSyllabiDir}		= $config{OutputHtmlDir}."/syllabi";
	$path_map{OutputFigsDir}            = $config{OutputFigsDir};
	$path_map{OutputScriptsDir}			= $config{OutputScriptsDir};
	$path_map{OutputPrereqDir}          = $config{OutputTexDir}."/prereq";
	$path_map{OutputDotDir}             = $config{OutputDotDir};
	$path_map{OutputMain4FigDir}		= $config{OutputMain4FigDir};
	$path_map{OutputSyllabiDir}			= $config{OutputInstDir}."/syllabi";
	$path_map{OutputFullSyllabiDir}		= $config{OutputInstDir}."/full-syllabi";
	$path_map{OutputFacultyDir}			= $config{OutputInstDir}."/faculty";
	$path_map{OutputCompetencesDir}		= $config{OutputCompetencesDir};
	$path_map{OutputFacultyFigDir}		= $path_map{OutputFacultyDir}."/fig";			
	CreateDir($path_map{OutputFacultyFigDir});
	$path_map{OutputFacultyIconDir}		= $path_map{OutputFacultyDir}."/icon";			
	CreateDir($path_map{OutputFacultyIconDir});
	$path_map{LinkToCurriculaBase}		= $config{LinkToCurriculaBase};
	$path_map{OutputPdfDir}				= $config{OutputPdfDir};
	$path_map{OutputPdfInstDir}			= "$config{OutputPdfDir}/<COUNTRY>-<AREA>-<INST>/$config{Plan}";
	$path_map{OutputLogDir}				= "./log";
	CreateDir($path_map{OutputPdfInstDir});
	
################################################################################################################################
# Input and Output files

	# People Files

	# Tex files
	$path_map{"out-current-institution-file"}	= $path_map{OutputInstDir}."/tex/current-institution.tex";
	$path_map{"preamble0-file"}                 = $path_map{InAllTexDir}."/preamble0.tex";
	$path_map{"list-of-courses"}		   		= $path_map{InGeneralAreaDir}."/<AREA><CURRICULA_VERSION>-dependencies.tex";

	$path_map{"out-acronym-file"}				= $path_map{OutputTexDir}."/acronyms.tex";
	$path_map{"out-ncredits-file"}              = $path_map{OutputTexDir}."/ncredits.tex";
	$path_map{"out-nsemesters-file"}            = $path_map{OutputTexDir}."/nsemesters.tex";

	$path_map{"in-outcomes-macros-file"}		= $path_map{InTexDir}."/outcomes-macros.tex";
	$path_map{"in-bok-file"}					= $path_map{InTexDir}."/bok.tex";
	$path_map{"in-bok-macros-file"}				= $path_map{InStyDir}."/bok-macros.sty";
	$path_map{"in-bok-macros-V0-file"}			= $path_map{InStyDir}."/bok-macros-V0.sty";

	$path_map{"in-LU-file"}						= $path_map{InTexDir}."/LU.tex";

	$path_map{"out-bok-index-file"}				= $path_map{OutputTexDir}."/BodyOfKnowledge-Index-<LANG>.tex";
	$path_map{"out-bok-body-file"}				= $path_map{OutputTexDir}."/BodyOfKnowledge-Body-<LANG>.tex";
	$path_map{"in-macros-order-file"}			= $path_map{InOthersDir}."/macros-order.txt";
	$path_map{"in-main-to-gen-fig"}				= $path_map{InTexAllDir}."/main-to-gen-fig.tex";

	$path_map{"out-tables-foreach-semester-file"}	= $path_map{OutputTexDir}."/tables-by-semester-<LANG>.tex";
	$path_map{"out-distribution-area-by-semester-file"}= $path_map{OutputTexDir}."/distribution-area-by-semester.tex";
	$path_map{"out-distribution-of-credits-by-area-by-semester-file"}= $path_map{OutputTexDir}."/distribution-credits-by-area-by-semester.tex";

	$path_map{"out-pie-credits-file"}			= $path_map{OutputTexDir}."/pie-credits.tex";
	$path_map{"out-pie-hours-file"}				= $path_map{OutputTexDir}."/pie-hours.tex";
	$path_map{"out-pie-by-levels-file"}			= $path_map{OutputTexDir}."/pie-by-levels.tex";

	$path_map{"out-list-of-courses-per-area-file"}	= $path_map{OutputTexDir}."/list-of-courses-per-area.tex";
	$path_map{"out-comparing-with-standards-file"}	= $path_map{OutputTexDir}."/comparing-with-standards-<LANG>.tex";
	$path_map{"in-all-outcomes-by-course-poster"}	= $path_map{OutputTexDir}."/all-outcomes-by-course-poster-<LANG>.tex";
	$path_map{"out-list-of-outcomes"}			= $path_map{OutputTexDir}."/list-of-outcomes.tex";
	$path_map{"list-of-courses-by-outcome"}		= $path_map{OutputTexDir}."/courses-by-outcome-<LANG>.tex";
	$path_map{"list-of-courses-by-specific-outcome"}= $path_map{OutputTexDir}."/list-of-courses-by-specific-outcome-<LANG>.tex";
	$path_map{"table-of-courses-by-specific-outcome"}= $path_map{OutputTexDir}."/table-of-courses-by-specific-outcome-<LANG>.tex";

	$path_map{"out-list-of-syllabi-include-file"}   = $path_map{OutputTexDir}."/list-of-syllabi.tex";
	$path_map{"out-laboratories-by-course-file"}	= $path_map{OutputTexDir}."/laboratories-by-course.tex";
	$path_map{"out-equivalences-file"}			= $path_map{OutputTexDir}."/equivalences.tex";

	$path_map{"in-Book-of-Syllabi-main-file"}	= $path_map{InAllTexDir}."/BookOfSyllabi.tex";
	$path_map{"out-Book-of-Syllabi-only-file"}	= "BookOfSyllabi-<LANG>.tex";
	$path_map{"out-Book-of-Syllabi-main-file"}	= $path_map{OutputTexDir}."/".$path_map{"out-Book-of-Syllabi-only-file"};
	$path_map{"in-Book-of-Syllabi-face-file"}	= $path_map{InAllTexDir}."/Book-Face.tex";
	$path_map{"pdf-syllabi-includelist-only-file"}= "pdf-syllabi-includelist-<LANG>.tex";
	$path_map{"out-Syllabi-includelist-file"}	= $path_map{OutputTexDir}."/".$path_map{"pdf-syllabi-includelist-only-file"};

	$path_map{"in-Book-of-Syllabi-delivery-control-file"}		= $path_map{InAllTexDir}."/BookOfDeliveryControl.tex";
	$path_map{"in-Book-of-Syllabi-delivery-control-face-file"}	= $path_map{InAllTexDir}."/Book-Face.tex";

	$path_map{"out-Book-of-Descriptions-only-file"}	= "BookOfDescriptions-<LANG>.tex";
	$path_map{"in-Book-of-Descriptions-main-file"}	= $path_map{InAllTexDir}."/BookOfDescriptions.tex";
	$path_map{"out-Book-of-Descriptions-main-file"}	= $path_map{OutputTexDir}."/".$path_map{"out-Book-of-Descriptions-only-file"};
	$path_map{"in-Book-of-Descriptions-face-file"}	= $path_map{InAllTexDir}."/Book-Face.tex";
	$path_map{"out-Descriptions-includelist-file"}	= $path_map{OutputTexDir}."/short-descriptions-<LANG>.tex";

	$path_map{"out-Book-of-Bibliography-only-file"}	= "BookOfBibliography-<LANG>.tex";
	$path_map{"in-Book-of-Bibliography-main-file"}	= $path_map{InAllTexDir}."/BookOfBibliography.tex";
	$path_map{"out-Book-of-Bibliography-main-file"}	= $path_map{OutputTexDir}."/".$path_map{"out-Book-of-Bibliography-only-file"};
	$path_map{"in-Book-of-Bibliography-face-file"}	= $path_map{InAllTexDir}."/Book-Face.tex";
	$path_map{"out-Bibliography-includelist-file"}	= $path_map{OutputTexDir}."/bibliography-list-<LANG>.tex";

	$path_map{"out-team-file"}						= $path_map{OutputTexDir}."/team-<LANG>.tex";
	$path_map{"in-config-hdr-foot-sty-file"}        = $path_map{InStyAllDir}."/config-hdr-foot.sty";
	$path_map{"out-config-hdr-foot-sty-only-file"}  = "config-hdr-foot-<LANG>.sty";
	$path_map{"out-config-hdr-foot-sty-file"}       = $path_map{OutputTexDir}."/".$path_map{"out-config-hdr-foot-sty-only-file"};

	$path_map{"in-Book-of-units-by-course-main-file"}= $path_map{InAllTexDir}."/BookOfUnitsByCourse.tex";
	$path_map{"in-Book-of-units-by-course-face-file"}= $path_map{InAllTexDir}."/Book-Face.tex";
	$path_map{"out-Syllabi-delivery-control-includelist-file"}= $path_map{OutputTexDir}."/pdf-syllabi-delivery-control-includelist.tex";

	$path_map{"in-pdf-icon-file"}					= $path_map{InFigsDir}."/pdf.jpeg";

	$path_map{"out-list-of-unit-by-course-file"}	= $path_map{OutputTexDir}."/list-of-units-by-course.tex";

	$path_map{"in-description-foreach-area-file"}   = $path_map{InTexDir}."/description-foreach-area.tex";
	$path_map{"out-description-foreach-area-file"}  = $path_map{OutputTexDir}."/area-description-<LANG>.tex";

	$path_map{"in-description-foreach-prefix-file"}   = $path_map{InTexDir}."/description-foreach-prefix.tex";
	$path_map{"out-description-foreach-prefix-file"}  = $path_map{OutputTexDir}."/prefix-description-<LANG>.tex";

	$path_map{InLangBaseDir} 						= $path_map{InLangBaseDir};
	$path_map{"in-sumilla-template-file"}			= $path_map{InProgramDir}."/sumilla-template.tex";
	
	# Here ok in-syllabus-template-by-institution-file
	$path_map{"in-syllabus-template-by-institution-file"}		= GetInstitutionDir()."/syllabus-template.tex";
	$path_map{"in-syllabus-template-by-program-file"}			= $path_map{InProgramDir}."/syllabus-template.tex";
	$path_map{"in-syllabus-template-by-program-by-cycle-file"}	= $path_map{InProgramDir}."/cycle/$config{Semester}/syllabus-template.tex";
	
	$path_map{"in-empty-syllabus-tex-file"}			= $path_map{InLangBaseDir}."/empty-syllabus.tex";
	$path_map{"in-empty-syllabus-bib-file"}			= $path_map{InLangBaseDir}."/empty-syllabus.bib";
	$path_map{"in-empty-common-file"}				= $path_map{InLangBaseDir}."/empty-common.tex";
	$path_map{"in-syllabus-first-page-file"}		= $path_map{InProgramDir}."/cycle/$config{Semester}/syllabus-Page*";

	$path_map{"in-institution-dictionary"}			= $path_map{InProgramDir}."/lang/<LANG-EXTENDED>.txt";
	
	$path_map{"in-syllabus-delivery-control-file"}	= $path_map{InProgramDir}."/syllabus-delivery-control.tex";
	$path_map{InCycleDir}							= $path_map{InProgramDir}."/cycle/<CYCLE>"; 	# $config{Semester}
	$path_map{InPlanDir}							= $path_map{InCycleDir}."/<PLAN>"; 				# $config{Plan}
	$path_map{"in-additional-institution-info-file"}= $path_map{InPlanDir}."/additional-info.txt";
	$path_map{"in-distribution-dir"}				= $path_map{InPlanDir};
	$path_map{"in-this-semester-dir"}				= $path_map{InPlanDir};

	$path_map{"in-distribution-file"}				= $path_map{"in-distribution-dir"}."/distribution.txt";
	$path_map{"in-this-semester-evaluation-dir"}	= $path_map{"in-this-semester-dir"}."/evaluation";
	$path_map{"in-specific-evaluation-file"}		= $path_map{"in-distribution-dir"}."/Specific-Evaluation.tex";
	$path_map{"out-only-macros-file"}				= $path_map{OutputTexDir}."/macros-only.tex";

	$path_map{"in-general-cycle-config-file"}		= $path_map{InSemesterDir}."/$config{Semester}.config";
	$path_map{"in-institution-cycle-config-file"}	= $path_map{InInstitutionCycleDir}."/$config{Semester}.config";
	$path_map{"in-cycle-config-file"}				= $path_map{InProgramSemesterDir}."/cycle.config";
	$path_map{"faculty-file"}						= $path_map{InProgramSemesterDir}."/faculty.txt";

	$path_map{"faculty-template.html"}				= $path_map{InFacultyIconsDir}."/faculty.html";
	$path_map{"NoFace-file"}						= $path_map{InFacultyIconsDir}."/noface.gif";

	$path_map{"faculty-general-output-html"}		= $path_map{OutputFacultyDir}."/faculty.html";
	$path_map{"out-courses-by-professor-file"}		= $config{OutputTexDir}."/courses-by-professor-<LANG>.tex";
	$path_map{"out-professor-by-course-file"}		= $config{OutputTexDir}."/professor-by-course-<LANG>.tex";
	$path_map{"in-replacements-file"}				= $path_map{InStyDir}."/replacements.txt";
	$path_map{"out-change-files"}					= $config{OutputTexDir}."/files-to-be-changed.txt";

	$path_map{"output-curricula-html-file"}			= "$path_map{OutputHtmlDir}/Curricula_<AREA>_<INST>.html";
	$path_map{"output-index-html-file"}				= "$path_map{OutputHtmlDir}/index.html";

	# Batch files
	$path_map{"out-compileall-file"}				= "compileall";
	
	$path_map{"in-compile1institucion-base-file"}	= $path_map{InDir}."/base-scripts/compile1institucion.sh";
	$path_map{"out-compile1institucion-file"}  		= $path_map{OutputScriptsDir}."/compile1institucion.sh";
	
	$path_map{"in-gen-html-1institution-base-file"}	= $path_map{InDir}."/base-scripts/gen-html-1institution.sh";
	$path_map{"out-gen-html-1institution-file"} 	= $path_map{OutputScriptsDir}."/gen-html-1institution.sh";
	
	$path_map{"in-gen-eps-files-base-file"}			= $path_map{InDir}."/base-scripts/gen-eps-files.sh";
	$path_map{"out-gen-eps-files-file"} 			= $path_map{OutputScriptsDir}."/gen-eps-files.sh";

	$path_map{"in-gen-graph-base-file"}				= $path_map{InDir}."/base-scripts/gen-graph.sh";
	$path_map{"out-gen-graph-file"} 				= $path_map{OutputScriptsDir}."/gen-graph.sh";
	
	$path_map{"in-gen-book-base-file"}				= $path_map{InDir}."/base-scripts/gen-book.sh";
	$path_map{"out-gen-book-file"} 					= $path_map{OutputScriptsDir}."/gen-book.sh";
	
	$path_map{"in-CompileTexFile-base-file"}		= $path_map{InDir}."/base-scripts/CompileTexFile.sh";
	$path_map{"out-CompileTexFile-file"} 			= $path_map{OutputScriptsDir}."/CompileTexFile.sh";
	
	$path_map{"in-compile-simple-latex-base-file"}	= $path_map{InDir}."/base-scripts/compile-simple-latex.sh";
	$path_map{"out-compile-simple-latex-file"} 		= $path_map{OutputScriptsDir}."/compile-simple-latex.sh";

	$path_map{"in-gen-poster-base-file"}			= $path_map{InDir}."/base-scripts/gen-poster.sh";
	$path_map{"out-gen-poster-file"} 				= $path_map{OutputScriptsDir}."/gen-poster.sh";
	$path_map{"in-gen-poster-fast-base-file"}		= $path_map{InDir}."/base-scripts/gen-poster-fast.sh";
	$path_map{"out-gen-poster-fast-file"} 			= $path_map{OutputScriptsDir}."/gen-poster-fast.sh";
	
	$path_map{"update-page-numbers"}	 			= $path_map{InScriptsDir}."/update-page-numbers.pl";

	$path_map{"out-batch-to-gen-figs-file"}         = $path_map{OutputScriptsDir}."/gen-fig-files.sh";
	$path_map{"out-gen-syllabi.sh-file"}			= $path_map{OutputScriptsDir}."/gen-syllabi.sh";
	$path_map{"out-dot-maps-batch"}					= $path_map{OutputScriptsDir}."/gen-dot-maps.sh";

	# Dot files
	#$path_map{"in-country-small-graph-item.dot"}	= $path_map{InCountryDir}."/dot/small-graph-item$config{graph_version}.dot";
	# Here in-country-graph-item.dot
	$path_map{"in-country-graph-item.dot"}			= $path_map{InCountryDir}."/dot/<SIZE>-graph-item$config{graph_version}.dot";
	$path_map{"in-discipline-graph-item.dot"}		= $path_map{InDisciplineDotDir}."/<SIZE>-graph-item$config{graph_version}.dot";
	$path_map{"in-area-graph-item.dot"}				= $path_map{InAreaDir}."/dot/<SIZE>-graph-item$config{graph_version}.dot";
	$path_map{"in-institution-graph-item.dot"}		= $path_map{InProgramDir}."/dot/<SIZE>-graph-item$config{graph_version}.dot";
	
	foreach my $size ('small', 'big')
	{	$path_map{"out-$size-graph-curricula-dot-only-file"} = "$size-graph-curricula-<LANG>.dot";
		$path_map{"out-$size-graph-curricula-dot-file"} = $config{OutputDotDir}."/".$path_map{"out-$size-graph-curricula-dot-only-file"};
	}
	# Poster files
	$path_map{"in-poster-file"}						= $path_map{InDisciplineTexDir}."/<DISCIPLINE>-poster.tex";
	$path_map{"out-poster-file"}					= $path_map{OutputTexDir}."/<DISCIPLINE>-poster-<LANG>.tex";
	$path_map{"in-a0poster-sty-file"}               = $path_map{InStyAllDir}."/a0poster.sty";
	$path_map{"in-poster-macros-sty-file"}          = $path_map{InStyAllDir}."/poster-macros.sty";
	$path_map{"in-small-graph-curricula-file"}      = $path_map{InTexAllDir}."/small-graph-curricula.tex";
	$path_map{"out-small-graph-curricula-file"}     = $path_map{OutputTexDir}."/small-graph-curricula-<LANG>.tex";

	# Html
	$path_map{"in-web-course-template.html-file"} 	= $path_map{InHtmlDir}."/web-course-template.html";
	$path_map{"in-analytics.js-file"}               = $path_map{InDir}."/analytics.js";

	# Config files
	$path_map{"all-config"}							= $path_map{InDir}."/config/all.config";
	$path_map{"colors"}								= $path_map{InDir}."/config/colors.config";
	$path_map{"institution-colors"}					= "$path_map{InInstitutionConfigDir}/colors.config";
	
	$path_map{"discipline-config"}		   			= "$path_map{InDisciplineConfigDir}/<DISCIPLINE>.config";
	$path_map{"in-area-all-config-file"}			= "$path_map{InAreaDir}/config/All.config";
	$path_map{"in-area-config-file"}				= "$path_map{InAreaDir}/config/Area.config";

	# Here ok in-country-config-file
	$path_map{"in-country-config-file"}				= $path_map{InCountryDir}."/country.config";
	$path_map{"in-institution-config-file"}			= $path_map{InInstitutionConfigDir}."/<INST>.config";
	
	
	# Here ok in-country-environments-to-insert-file
	$path_map{"in-country-environments-to-insert-file"}	= $path_map{InCountryDir}."/country-environments-to-insert.tex";
	$path_map{"DefaultDictionary"}					= $path_map{InLangDefaultDir}."/dictionary.txt";
	$path_map{"dictionary"}							= $path_map{InLangBaseDir}."/<LANG-EXTENDED>/dictionary.txt";

	$path_map{"OutputDisciplinesList-file"}			= $path_map{OutHtmlBase}."/disciplines.html";
	$path_map{"output-errors-file"}					= $path_map{OutputLogDir}."/$config{country_without_accents}-<AREA>-<INST> $config{Plan}.txt";
	$path_map{"output-errors-markdown-file"}		= $path_map{OutputLogDir}."/$config{country_without_accents}-<AREA>-<INST> $config{Plan}.md";
	
	$path_map{"in-json-file"}						= $path_map{OutputJsonDir}."/timestamps.json";

	$path_map{InInstitutionMainFile}				= "$path_map{InInstitutionBaseDir}/Main.tex";
	$path_map{"out-main-tex-file"}					= $path_map{OutputTexDir}."/Main.tex";
	Util::check_point("set_initial_paths");
}

sub get_file_name($)
{
	my ($tpl) = (@_);
	return GetTemplate($tpl);
}

sub get_list_of_dirs_from_root($);  # it is just a prototype to avoid a warning into the for
sub get_list_of_dirs_from_root($)
{
	my ($root) = (@_);
	#Util::print_message("root=$root");
	my @list = ();
	if( -e $root )
	{	for my $dir (grep { -d "$root/$_" } read_dir($root))
		{
			push(@list, "$root/$dir");
			if( -d "$root/$dir" )
			{	push(@list, get_list_of_dirs_from_root("$root/$dir"));	}
		}
	}
	return @list;
}

sub get_list_of_dirs_by_lang($)
{
	my ($lang) = (@_);
	my $root = GetExpandedTemplateWithLang("InSyllabiContainerDir", $lang);
	my @dirs = get_list_of_dirs_from_root($root);
	for(my $i = 0; $i < scalar @dirs; $i++)
	{
		$dirs[$i] =~ s/$root\///g;
	}
	return @dirs;
}

sub read_dictionaries()
{
	# Read dictionary for this language
	$config{DefaultLang} = $config{language_without_accents};
	my $lang = $config{DefaultLang};
	$config{lang} = $lang;
	#Util::print_message( Util::red("Here 3! lang=$lang") );
	Util::print_message(Util::yellow("Reading dictionaries ..."));
	%{$config{dictionary}} = read_config_file(GetTemplate("DefaultDictionary"));
	foreach my $lang (@{$config{SyllabusLangsList}})
	{
		my $lang_prefix = "";
		if( $lang =~ m/(..)/g )
		{		$lang_prefix = uc($1);	      }
		%{$config{dictionaries}{$lang}} 		  = read_dictionary_file($lang);
		$config{dictionaries}{$lang}{lang_prefix} = $lang_prefix;

		my $filename = GetExpandedTemplateWithLang("in-institution-dictionary", $lang);
		my %institution_dictionary = read_customized_dictionary_for_this_institution($filename);
		foreach my $key (keys %institution_dictionary)
		{
			if(defined($config{dictionaries}{$lang}{$key}))
			{	$config{dictionaries}{$lang}{$key} = $institution_dictionary{$key};
				if($lang eq $config{DefaultLang})
				{	$config{dictionary}{$key} = $institution_dictionary{$key};
				}
			}
			else
			{	Util::print_error("Defining new unkonwn term \"$key\" in $lang for this institution ... See: $filename ...");
				exit;
			}
		}
		#Util::print_message("config{dictionaries}{$lang}{lang_prefix} = $config{dictionaries}{$lang}{lang_prefix}");
		foreach my $key (keys %{$config{dictionaries}{$lang}})
		{	$config{dictionaries}{terms}{$key} = "";	}
		#print Dumper(\%{$config{dictionaries}{terms}});
		@{$config{SyllabiDirs}{$lang}} = get_list_of_dirs_by_lang($lang);
	}
	#dump_dictionary_errors();
}
# ok
sub read_discipline_config()
{
	#my ($lang) = (@_);
	my $DisciplineConfigFile = GetTemplate("discipline-config");
	my %discipline_cfg	= read_config_file($DisciplineConfigFile);
	push(@{$config{config_file}}, $DisciplineConfigFile);
	#print Dumper (\%discipline_cfg);
	my ($key, $value);
	while ( ($key, $value)  = each(%discipline_cfg) )
	{
# 		print "country-info: key=$key, value=$value\n";
		$config{$key} = $value;
	}
	# my $syllabus_base_dir = get_extended_template("InSyllabiContainerDir", $lang);
	$config{PrefixPriorityCount} = 0;
	foreach my $axe (split(",", $config{SpiderChartAxes}))
	{	$config{SpiderChartAxesItems}{$axe} = ++$config{PrefixPriorityCount};	}
	$config{NumberOfAxes} = $config{PrefixPriorityCount};
}

sub get_list_of_dirs_to_find_syllabi($)
{
	my ($codcour, $lang) = (@_);
	my $coursefile = $course_info{$codcour}{coursefile};
	my $dirlist = "";
	my $root = GetExpandedTemplateWithLang("InSyllabiContainerDir", $lang);
	foreach my $dir (@{$config{SyllabiDirs}{$lang}})
	{	$dirlist .= "$root/$dir/$coursefile.tex\n";		}
	return $dirlist;
}

# ok
sub get_syllabus_dir($$)
{
	my ($codcour, $lang) = (@_);
	my $coursefile = $course_info{$codcour}{coursefile};
	my $root = GetExpandedTemplateWithLang("InSyllabiContainerDir", $lang);
	foreach my $dir (@{$config{SyllabiDirs}{$lang}})
	{
		my $file = "$root/$dir/$coursefile";
		if(-e $file.".tex" or -e $file.".bib")
		{	return "$root/$dir";	}
	}
	Util::halt("I can not find syllabus/bib file for $codcour");
}

sub update_hash($$)
{
	my ($key, $file) = (@_);
	# print Dumper(\%{$config{$key}});
	my $output_hash_txt = "<HASH name=$key>\n";
	if( defined($config{$key}) )
	{
		for my $prefix (sort {$a cmp $b} keys %{$config{$key}} )
		{	$output_hash_txt .= sprintf("%-5s => %s\n", $prefix, $config{$key}{$prefix});
		}
	}
	$output_hash_txt .= "</HASH>\n";
	my $file_txt = Util::read_file($file);
	# if this hash exists replace it
	if( $file_txt =~ m/<HASH name=$key>((?:.|\n)*?)<\/HASH>/g )
	{	my $NewKey = replace_special_chars($key);
		$file_txt =~ s/<HASH name=$NewKey>((?:.|\n)*?)<\/HASH>/$output_hash_txt/g;
	}
	else # we have to add this hash
	{	$file_txt .= "\n\n$output_hash_txt";
	}
	# Util::print_message("$file_txt");
	Util::write_file($file, $file_txt); 
}

sub update_syllabi_prefix_location($$)
{
	my ($prefix, $subdir) = (@_);
	if( not defined($config{"syllabi_path"}{$prefix}) )
	{
		$config{"syllabi_path"}{$prefix} = $subdir;
		my $inst_config_file = GetTemplate("in-institution-config-file");
		Util::print_message("Updating $inst_config_file ($prefix=$subdir)");
		update_hash("syllabi_path", $inst_config_file);
	}
}

sub getchar()
{
	ReadMode("cbreak");
	my $key = ReadKey(0);
	ReadMode("normal");
}

sub read_common_content($$)
{
	my ($codcour, $lang) = (@_);
	my $file_fullpath = $course_info{$codcour}{$lang}{file_fullpath};
	my $syllabus_in = Util::read_file($file_fullpath);
	if( $syllabus_in && $syllabus_in =~ m/\\end\{goals\}\s*((?:.|\n)*?)\\begin\{unit\}/)
	{
		my $common_content = $1;
		# Util::print_message(Util::green("Common content for: ")."$file_fullpath");
		# Util::print_message($common_content);
		return $common_content;
	} else {
		return "\\begin{outcomes}{V1}\n    \\item \\ShowOutcome{a}{1}\n\\end{outcomes}";
	}
	#  elsif(index($file_fullpath, "/Common/") != -1){
	# 	Util::write_file($file_fullpath, "");
	# 	return "";
	# } else {
	# 	Util::print_message("Error on path:");
	# 	Util::print_message($file_fullpath);
	# }
}

sub remove_common_content($$)
{
	my ($codcour, $lang) = (@_);
	my $file_fullpath = $course_info{$codcour}{$lang}{file_fullpath};
	Util::print_message("remove_common_content: $file_fullpath");
	my $syllabus_in = Util::read_file($file_fullpath);
	if( $syllabus_in =~ m/\\end\{goals\}(?:.|\n)*?\\begin\{unit\}/g )
	{	$syllabus_in =~ s/\\end\{goals\}(?:.|\n)*?\\begin\{unit\}/\\end\{goals\}\n\n--COMMON-CONTENT--\n\n\\begin\{unit\}/g;
	}
	Util::write_file($file_fullpath, $syllabus_in);
}

sub create_common_file($$$)
{
	my ($codcour, $lang, $AskBeforeCreate) = (@_);
	my $syllabus_common_base_dir 	= GetExpandedTemplateWithLang("InSyllabiCommonContainerDir", $lang);
	my $codcourfile 		= $course_info{$codcour}{coursefile};
	my $relative_path 		= $course_info{$codcour}{relative_path};
	my $common_file 		= "$syllabus_common_base_dir/$relative_path/$codcourfile.tex";
	if( -e $common_file )
	{	return $common_file;	}

	my $common_file_highlight 		= "$syllabus_common_base_dir/".Util::yellow($relative_path)."/".Util::yellow("$codcourfile.tex");
	$common_file_highlight 			= Util::highlight($common_file_highlight, "Common", \&Util::yellow);
	my $course_name 				= $Common::course_info{$codcour}{$lang}{course_name};
	Util::print_message(sprintf("File $common_file_highlight (%s) %s ", Util::yellow($course_name), Util::red("does not exist ...")));
	my $option = "N";
	if( $AskBeforeCreate == 1 )
	{	my %YesNoMenu = ("Y" => "Yes", "N" => "No");
		$option = get_menu_option("Do you want to create it? ", %YesNoMenu);
	}
	if( $option eq "Y" || $AskBeforeCreate == 0 )
	{
		Util::print_message("Creating file $common_file_highlight");
		$course_info{$codcour}{common_file} = $common_file;
		CreateDir("$syllabus_common_base_dir/$relative_path");
		my $common_content = read_common_content($codcour, $lang);
		Util::write_file($common_file, $common_content);
	}
	else
	{
		Util::print_message("I cann't create the new common file ($common_file_highlight) ... Bye!");
		exit;
	}
}

sub GetCommonFileFullPath($$)
{
	my ($codcour, $lang) = (@_);
	if( not $Common::course_info{$codcour}{common_file} eq "" )
	{	return $Common::course_info{$codcour}{common_file};		}

	my $syllabus_common_base_dir= GetExpandedTemplateWithLang("InSyllabiCommonContainerDir", $lang);
	my $codcourfile 			= $course_info{$codcour}{coursefile};
	my $relative_path 			= $course_info{$codcour}{relative_path};
	my $common_file 			= "$syllabus_common_base_dir/$relative_path/$codcourfile.tex";
	return $common_file;

}
sub create_empty_common_file($$)
{
	my ($codcour, $lang) = (@_);
	my $relative_path 			= $course_info{$codcour}{relative_path};
	my $common_file 			= Common::GetCommonFileFullPath($codcour, $lang);
	my $common_file_highlighted	= Util::HighlightFilenameLangRelativePath($common_file, $relative_path, "Common");
	if( -e $common_file )
	{
		Util::print_message($Util::icons{bulb}.Util::red("create_empty_common_file")." File $common_file_highlighted already exists !");
		return;
	}
	my $output_txt = <<"END_TEXT";
\\begin{outcomes}{V1}
    \\item \\ShowOutcome{a}{1}
\\end{outcomes}

\\begin{outcomes}{V2}
    \\item \\ShowOutcome{1}{1}
\\end{outcomes}
END_TEXT
	Util::print_message("$Util::icons{ok} create_empty_common_file:  Creating file: $common_file_highlighted (".length($output_txt)." bytes)");
	Util::write_file($common_file, $output_txt);
}

sub create_input_syllabus_file($$$)
{	
	my ($codcour, $semester, $lang) = (@_);
	my $relative_path 				= $course_info{$codcour}{relative_path};
	my $syllabus_base_dir 			= GetExpandedTemplateWithLang("InSyllabiContainerDir", $lang);
	my $syllabus_common_base_dir 	= GetExpandedTemplateWithLang("InSyllabiCommonContainerDir", $lang);

	my $codcourfile 		= $course_info{$codcour}{coursefile};
	my $course_name 		= prepare_text_for_latex($course_info{$codcour}{$lang}{course_name});
	my $course_type 		= $course_info{$codcour}{course_type};
	#my $InEmptySyllabiDir 		= GetExpandedTemplateWithLang("InEmptySyllabiDir", $lang);
	#my $InEmptySyllabiCommonDir = GetExpandedTemplateWithLang("InEmptySyllabiCommonDir", $lang);

	# Create the tex file	
	my $empty_syllabus_tex_file = GetTemplate("in-empty-syllabus-tex-file");
	Util::print_message("Reading from file $empty_syllabus_tex_file");
	my $empty_syllabus_in_tex	= Util::read_file($empty_syllabus_tex_file);
	Util::print_message("create_input_syllabus_file:Reading: ".Util::yellow("$empty_syllabus_tex_file") ); 
	   $empty_syllabus_in_tex   =~ s/<CODE>/$codcour/g;
	   $empty_syllabus_in_tex   =~ s/<NAME>/$course_name/g;
	   $empty_syllabus_in_tex   =~ s/<COURSE_TYPE>/$config{dictionaries}{$lang}{$course_type}/g;
	   $empty_syllabus_in_tex   =~ s/<SUBAREA>/$course_info{$codcour}{relative_path}/g;
	#  $empty_syllabus_in_tex   =~ s/<COURSE_TYPE>/$config{dictionaries}{$lang}{$course_type}/g;

	my $new_file = "$syllabus_base_dir/$relative_path/$codcourfile";
	my ($new_tex_file, $new_bib_file) = ("$new_file.tex", "$new_file.bib");
	$course_info{$codcour}{$lang}{file_fullpath} = $new_tex_file;
	Util::print_message("create_input_syllabus_file:Creating file: ");
	#Util::print_color($empty_syllabus_in_tex);
	Util::print_message("create_input_syllabus_file:Creating file: ". Util::highlight_FilenameAndLang("$new_tex_file", $lang)." (".length($empty_syllabus_in_tex)." bytes)" );
	Util::write_file($new_tex_file, $empty_syllabus_in_tex);
	
	# Create the bib file
	my $empty_syllabus_bib 	= Util::read_file(GetTemplate("in-empty-syllabus-bib-file"));
	Util::print_message("create_input_syllabus_file:Creating file: ". Util::highlight_FilenameAndLang("$new_bib_file", $lang)." (".length($empty_syllabus_bib)." bytes)");
	
	Util::write_file("$new_bib_file", $empty_syllabus_bib);

	# Create the common file
	create_empty_common_file($codcour, $lang);
	remove_common_content($codcour, $lang);
	return "$new_file.tex";
}

# ok
sub get_input_syllabus_full_path($$$)
{
	my ($codcour, $semester, $lang) = (@_);
	#Util::print_message("get_input_syllabus_full_path($codcour, $semester, $lang)");
	my $codcourfile 		= $course_info{$codcour}{coursefile};
	my $codcourfile_prefix  = get_course_prefix($codcourfile);
	my $root = GetExpandedTemplateWithLang("InSyllabiContainerDir", $lang);
	#print Dumper(\@{$config{SyllabiDirs}{$lang}});
	foreach my $dir (@{$config{SyllabiDirs}{$lang}})
	{
		$course_info{$codcour}{relative_path} = $dir;
		my $file = "$root/$dir/$codcourfile";
		my $fullname = "$file.tex";
		#Util::print_message("get_input_syllabus_full_path(
		if(-e $fullname )
		{	$Common::course_info{$codcour}{$lang}{file_fullpath} = $fullname;
			return $fullname;
		}
		#if(-e $file.".bib")
		#{	return $file.".bib";	}
	}
	#assert(false);
	return "---";
}

sub TryToCreateSyllabus($$$)
{
	my ($codcour, $semester, $lang) = (@_);
	my $codcourfile 		= $course_info{$codcour}{coursefile};
	my $codcourfile_prefix  = get_course_prefix($codcourfile);
	my $new_file 			= "";
	my $syllabus_base_dir 	= GetExpandedTemplateWithLang("InSyllabiContainerDir", $lang);
	my $course_name 		= prepare_text_for_latex($course_info{$codcour}{$lang}{course_name});
	my $msg 				= "$course_name, ".format_semester_label_in_plain_text($semester, $lang);

	Util::print_message("I could not find course ".Util::yellow("$codcour ($msg)")." ...");
	if( defined($config{"syllabi_path"}{$codcourfile_prefix}) )
	{	
		my $filename_highlighted = "$syllabus_base_dir/".Util::green($config{"syllabi_path"}{$codcourfile_prefix});
		Util::print_message("I suggest to create ".Util::green("$codcourfile")." at: $filename_highlighted/ ...");
		my %YesNoMenu = ("Y" => "Yes", "N" => "No");
		my $option = get_menu_option("Do you want to create ".Util::yellow($codcourfile)."? ", %YesNoMenu);
		if($option eq "Y")
		{	$course_info{$codcour}{relative_path} = $config{"syllabi_path"}{$codcourfile_prefix};
			$new_file = create_input_syllabus_file($codcour, $semester, $lang);
			#Util::print_color("Check point A"); assert(0); exit;
			return $new_file;
		}
		else
		{
			Util::print_message("I cann't create the new syllabus ... Bye!");
			my $inst_config_file = GetTemplate("in-institution-config-file");
			Util::print_message("Please verify: $inst_config_file");
			Util::print_message("Bye!");
			exit;	
		}
	}
	else
	{	Util::print_message("I was looking for that file at: ".Util::yellow($syllabus_base_dir));
	}

	#my $root = GetExpandedTemplateWithLang("InSyllabiContainerDir", $lang);
	my %syllabus_dirs_map 	= format_menu_for_syllabus_dir($lang);
	$syllabus_dirs_map{"0"} = "Quit";
	#print Dumper(\%syllabus_dirs_map);
	my $option = get_menu_option("Where do you want to create ".Util::yellow($codcourfile)."? ", %syllabus_dirs_map);
	#print Dumper(\@{$config{SyllabiDirs}{$lang}});

	if($option eq "0") # Quit
	{	Util::print_message("I cann't create the new syllabus ... Bye!");
		exit;
	}
	update_syllabi_prefix_location($codcourfile_prefix, $syllabus_dirs_map{$option});
	assert(defined($config{"syllabi_path"}{$codcourfile_prefix}));
	$course_info{$codcour}{relative_path} = $config{"syllabi_path"}{$codcourfile_prefix};
	$new_file = create_input_syllabus_file($codcour, $semester, $lang);

	# Create the common file
	create_common_file($codcour, $lang, 0);
	#remove_common_content($codcour, $lang);
	return $new_file;
}


sub TrackKeyLog($$$)
{
	my ($key, $value, $file) = (@_);
	push( @{$config{KeyLog}{$key}{files}},  $file);
	push( @{$config{KeyLog}{$key}{values}}, $value);
}

sub read_config_file_details($)
{
	my ($filename) 		= (@_);
	my %map 		= ();
	if( not -e $filename )
	{	Util::print_message("Config file: ". Util::red("$filename"). " doesn't exist ... $Util::icons{X}");
		Util::print_error("");
	}
 	printf("$Util::icons{ok} Reading config file: \"".Util::highlight_filename($filename)."\"\n");
	my $txt = Util::read_file($filename);
	while($txt =~ m/<HASH name=(.*?)>((?:.|\n)*?)<\/HASH>/)
	{
		my ($name, $body) = ($1, $2);
		my $body_tmp = replace_special_chars($body);
		$txt =~ s/<HASH name=$name>$body_tmp<\/HASH>//g;
		while($body =~ m/\s*(\w*)\s*=>\s*(.*?)\s*\n/g)
		{	$map{$name}{$1} = $2;	}
	}
	while($txt =~ m/\s*(.*?)\s*=\s*(.*)\s*/g)
	{	my ($key, $value) = ($1, $2);
		$map{$key}        = $value;
 		TrackKeyLog($key, $value, $filename)
	}
    return %map;
}

# TODO: fusionar estas dos funciones \/ y /\
sub process_one_cycle_var($)
{
	my ($cycle_config_file_template) = (@_);
	my $lang 				= $config{language_without_accents};
	my $cycle_config_file	= GetTemplate($cycle_config_file_template);
	if( not -e $cycle_config_file )
	{	Util::print_message(Util::blue("$cycle_config_file")." does not exist ! No problem !");	}

	my %cycle_vars 			= read_config_if_exists($cycle_config_file);
	my $count_errors 		= 0;
	while ( my ($key, $value) = each(%cycle_vars) ) # Overwrite some terms for this country !
	{	
		#Util::print_message(Util::blue("($key, $value)"));
		if( $key =~ m/(.*)\.(.*)/g )
		{	my ($codcour, $field) = ($1, $2);
			#Util::print_message("X0: codcour=$codcour, field=$field");
			if(not (	$field eq "LearningModality" 
					#|| 	$field eq "field2" 
					#|| 	$field eq "field3" ...
					)
				)# 
			{	Util::print_message("$Util::icons{X} field: ".Util::red($field)." not defined !");
				$count_errors++;
				next;
			}
			if( defined($course_info{$codcour}) )
			{	if( defined($config{dictionary}{LearningModalityList}{$value}) )
				{	$course_info{$codcour}{LearningModality} = $value;
					Util::print_message("$Util::icons{check} : ".Util::yellow($codcour).".LearningModality=$course_info{$codcour}{LearningModality}");
				}
				else
				{	print Dumper(\%{$config{dictionary}{LearningModalityList}});
					Util::print_message("$Util::icons{X} Course: ".Util::yellow("$codcour").
										" has a LearningModality ".Util::red("$field not defined !"));
				}
			}
			else
			{	Util::print_message("$Util::icons{X} Course: ".Util::yellow("$codcour")." not defined !");
				$count_errors++;
			}
		}
		else
		{	$config{$key} = $value; 		}
	}
	if( $count_errors > 0 )
	{	Util::print_message("Courses not defined ! See: ".Util::red($cycle_config_file));
		exit;
	}
	#Util::print_message("");
}

sub process_cycle_vars()
{
	Util::precondition("filter_courses");
	process_one_cycle_var("in-general-cycle-config-file");
	process_one_cycle_var("in-institution-cycle-config-file");
	process_one_cycle_var("in-cycle-config-file");

	#print Dumper(\%{$config{dictionary}});
	#print Dumper(\%{$config{dictionary}{LearningModalityList}});
	if( defined($config{dictionary}{LearningModalityList}{$config{LearningModality}}) )
	{	foreach my $codcour (@codcour_list_sorted)
		{	if( $course_info{$codcour}{LearningModality} eq "" )
			{	$course_info{$codcour}{LearningModality} = $config{LearningModality};		}
		}
	}
	else
	{	Util::print_message("LearningModality (".Util::red($config{LearningModality}).") not defined");
		print_keyLog("LearningModality");
		exit;
	}
}

sub add_key_to_dictionary($$$)
{
	my ($lang, $key, $value)     		= (@_);
	$config{dictionary}{$key}    		= $value;
	$config{dictionaries}{$lang}{$key} 	= $value;
	#Util::print_warning("config{dictionary}{$key}=$config{dictionary}{$key}, config{dictionaries}{$lang}{$key}=$config{dictionaries}{$lang}{$key}");
}
sub concat_key_to_dictionary($$$)
{
	my ($lang, $key, $value)     		= (@_);
	$config{dictionary}{$key}    		.= $value;
	$config{dictionaries}{$lang}{$key} 	.= $value;
	#Util::print_warning("config{dictionary}{$key}=$config{dictionary}{$key}, config{dictionaries}{$lang}{$key}=$config{dictionaries}{$lang}{$key}");
}

# ok
sub read_config_file($)
{
	my ($file) 		= (@_);
	return read_config_file_details($file);
}

sub read_dictionary_file($)
{
	my ($lang) = (@_);
	my $filename = GetExpandedTemplateWithLang("dictionary", $lang);
	return read_config_file_details($filename);
}

sub read_customized_dictionary_for_this_institution($)
{
	my ($filename) = (@_);
	if(-e $filename)
	{	return read_config_file_details($filename);	}
	else
	{	return ();	}
}


# ok
sub read_config($)
{
	my ($file) = (@_);
	my %map = read_config_file($file);
	my ($key, $value);
	while ( ($key, $value) = each(%map))
	{
		$config{$key} = $value;
		push( @{$config{KeyLog}{$key}{files}}, $file);
		push( @{$config{KeyLog}{$key}{values}}, $value);
	}
	return %map;
}

sub read_config_if_exists($)
{
	my ($file) = (@_);
	my %map = ();
	if( -e $file )
	{	return read_config($file);	}
	return %map;
}

sub print_keyLog($)
{	my ($key) = (@_);
	#print "$key\n". Dumper( \%{$config{KeyLog}});

	my $count = @{$config{KeyLog}{$key}{files}};
	for(my $i = 0 ; $i < $count ; $i++)
	{	Util::print_message( Util::green("V$i") );
		Util::print_message("  value= $config{KeyLog}{$key}{values}[$i]");
		Util::print_message("  file = $config{KeyLog}{$key}{files}[$i]");
	}
	Util::print_message("");
}

sub get_dictionary_term($)
{
    my ($word) = (@_);
    return $config{dictionary}{language_without_accents}{$word};
}

sub sort_macros()
{
    @{$config{sorted_macros}} = [];
    @{$config{sorted_macros}} = sort {length($b) <=> length($a)} keys %{$config{macros}};
    Util::check_point("sort_macros");
}

sub write_files_to_be_changed()
{
	my $file = Common::GetTemplate("out-change-files");
	my $output_txt = "";
	my ($key, $value);
	while( ($key, $value) = ( each(%{$Common::config{change_file}}) ) )
	{	$output_txt .=	"$key=$value\n";		}
	Util::write_file($file, $output_txt);
	Util::print_message("$Util::icons{ok} Generating ".Util::highlight_filename($file)." ...");
}

sub read_files_to_be_changed()
{
	my $output_change_files = Common::GetTemplate("out-change-files");
	my %map = Common::read_config_file($output_change_files);
	my ($key, $value);
	while ( ($key, $value) = each(%map))
	{	
		$Common::config{change_file}{$key} = $value;
	}
}

# ok
our %macros_order = ();
sub parse_macros($)
{
	my ($txt) = (@_);
	$txt 		  = Util::trim_comments($txt);
	my %macros 		 = ();
	%{$Common::macros_order} = ();
	my @tokens = ();
	while($txt =~ /(\{(?:(?1)|[^{}]*+)++\})|[^{}\s]++/g )
	{	my ($token) = ($&);
		push(@tokens, $token);
	}
	my $ntokens = scalar @tokens;
	#Util::print_message("ntokens=$ntokens");
	my ($count, $priority) = (0, 0);
	#Util::print_message("count=$count, ntokens=$ntokens ...");
    while($count < $ntokens)
    {
		if($tokens[$count] eq "\\newcommand")
		{
			my ($key, $body) = ("", "");
			if( $tokens[$count+1] =~ m/\{\\(.*)\}/g )
			{	$key = $1;	}
			else{	#Util::print_message("Something wrong1 @"."read_macros($file_name)! count=$count, tokens[$count]=$tokens[$count]");	
			}
			if( $tokens[$count+2] =~ m/\{((.|\n)*)\}/sg )
			{	$body = $1;	}
			else{	#Util::print_message("Something wrong2 @"."read_macros($file_name)! count=$count, key=$key,tokens[$count]=\"$tokens[$count]\"");	
			}
			$macros{$key} 		= $body;
			$macros_order{$key} = $priority++;
			$count += 2;
		}
		else
		{
			#Util::print_message("Something wrong3 @"."read_macros($file_name)! count=$count, tokens[$count]=\"$tokens[$count]\" \nI was expecting a newcommand");
		}
		++$count;
	}
	#print Dumper (\%macros);
    #Util::print_message("read_macros($file_name) ". (keys %macros) ." processed ... OK!");
	if($Util::flag == 100)
	{	
		#Util::print_soft_error("Llegó ! ($file_name) ...");  
		#Util::print_soft_error("macros{finaltest}=\n$macros{finaltest} ...");
	}
	return %macros;
}

sub read_macros($)
{
    my ($file_name) = (@_);
	#Util::print_message("Reading macros ( $file_name ) ...");
	if( not -e $file_name )
	{	print("$Util::icons{X} Reading macros cann't open: ".Util::red($file_name)."...");	
		exit;
	}
	my $txt				= Util::read_file($file_name);
	my %macros 			= parse_macros($txt);
	my $noutcomes_read  = keys %macros;
	Util::print_message("$Util::icons{ok} ".Util::yellow("$noutcomes_read macros read"));
	return %macros;
}

sub read_outcomes($$)
{
    my ($file_name, $lang) = (@_);
    my $txt 	= Util::read_file($file_name);
	#my %macros = parse_macros($txt);
	my %macros 	= ();
	#Util::print_message("file_name=$file_name ...");
	#print Dumper(\%macros); exit;
    my $count = 0;
    while($txt =~ m/\\Define(.*?)\{(.*?)\}\{/g)
    {
		my ($cmd, $code)  = (lc $1, $2);
		my ($outcome, $number) = ($code, "");
		if( $cmd eq "specificoutcome")
		{	$txt =~ m/(.*?)\}\{(.*?)\}\{/g;
			$number = $1;
			$code .= $number;
			$config{specificoutcome}{$lang}{$outcome}{$number}{label}    = $2;
			$config{specificoutcome}{$lang}{$outcome}{$number}{priority} = $count;
			#Util::print_message("SpecificOutcome $code detected ...");
		}
		my $cPar   = 1;
		my $body   = "";
		while($cPar > 0)
		{
			$txt =~ m/((.|\s))/g;
			$cPar++ if($1 eq "{");
			$cPar-- if($1 eq "}");
			$body      .= $1 if($cPar > 0);
		}
		#$macros{"outcomeg"} = $body;
		#$macros{"competenceC2"} = $body;
		#$macros{"specificoutcomec3"} = $body;
		$macros{"$cmd$code"} = $body;
		if( $cmd eq "specificoutcome")
		{	$config{specificoutcome}{$lang}{$outcome}{$number}{txt} = $body;
		}
		$count++;
    }
    #Util::print_message("read_outcomes ($file_name, $lang) $count macros processed ... OK!");
	#Util::print_color("config{specificoutcome}{$lang}");
	#print Dumper(\%{$config{specificoutcome}{$lang}{a}});
	#exit;
	return %macros;
}

sub read_special_macros($$)
{
    my ($file_name, $macro) = (@_);
    my $txt 	  = clean_file(Util::read_file($file_name));

    my $count = 0;
    while($txt =~ m/\\Define$macro\{(.*?)\}\{/g)
    {
	my ($cmd)  = ($1);
	my $cPar   = 1;
	my $body   = "";
	while($cPar > 0)
	{
		$txt =~ m/((.|\s))/g;
		$cPar++ if($1 eq "{");
		$cPar-- if($1 eq "}");
		$body      .= $1 if($cPar > 0);
	}
	$Common::config{$macro}{$cmd} = $body;
# 	if( $cmd eq "SPONEAllTopics")
# 	{	Util::print_message("*****\n$body\n*****");	exit;	}
	$count++;
    }
    Util::print_message("read_special_macros($macro) ($file_name) $count macros processed ... OK!");
}

sub read_bok($)
{
    my ($lang) = (@_);
    my $bok_macros_file = Common::GetExpandedTemplateWithLang("in-bok-macros-file", $lang);
	Util::print_message("$Util::icons{ok} read_bok(".Util::yellow($lang).") ... ");
	Util::print_message("$Util::icons{ok} Reading ".Util::highlight_filename($bok_macros_file));
    $bok_macros_file =~ s/<LANG>/$lang/g;
	#$Util::flag = 100;
    my %macros = read_macros($bok_macros_file);
	@{$Common::config{macros}}{keys %macros} = values %macros;

	foreach my $key (keys %macros_order)
	{	$Common::config{topics_priority}{$key} = $macros_order{$key};		}
}

sub read_replacements($)
{
	my ($lang) = (@_);
	my $replacements_file = Common::GetExpandedTemplateWithLang("in-replacements-file", $lang);
	%{$config{replacements}} = ();
	if( not -e $replacements_file )
	{
	      Util::print_warning("I did not find read_replacements($lang) : $replacements_file just ignoring this process ... ");
	      return;
	}
    my $txt = Util::read_file($replacements_file);
	foreach my $line (split("\n", $txt))
	{
		if($line =~ m/\s*(.*)\s*=>\s*(.*)\s*/g )
		{	$config{replacements}{$1} = $2;	}
	}
}

sub replace_old_macros($)
{
      my ($syllabus_in) = (@_);
      my $count = 0;
      foreach my $key (sort {length($b) <=> length($a)} keys %{$config{replacements}})
      {
	    $count += $syllabus_in =~ s/\\$key/\\$config{replacements}{$key}/g;
      }
      return ($syllabus_in, $count);
}

# ok
sub process_config_vars()
{
#  	print "config{macros_file} = \"$config{macros_file}\"\n";
    my $InStyDir = GetTemplate("InStyDir");
	my $InLangDefaultDir = GetTemplate("InLangDefaultDir");
	foreach my $file (split(",", $config{macros_file}))
	{
		$file =~ s/<STY-AREA>/$InStyDir/g;
		$file =~ s/<LANG-AREA>/$InLangDefaultDir/g;
	}

# 	SpiderChartAxes=CS,IS,SE,HW,IT,MC,OG,CB,CF,CM,CQ,HU,ET,ID # Pending Er
#   It is duplicated ... look for SpiderChartAxes
	$config{PrefixPriorityCount} = 0;
	$config{SpiderChartAxes} =~ s/ //g;
	foreach my $prefix (split(",", $config{SpiderChartAxes}))
	{	$config{prefix_priority}{$prefix} = ++$config{PrefixPriorityCount};		}

# 	AreaPriority=AF,AE,AB,AC
	$config{AreaPriorityCount} = 0;
	foreach my $area (split(",", $config{AreaPriority}))
	{	$config{area_priority}{$area} = ++$config{AreaPriorityCount};		}

	%{$config{colors}{colors_per_level}}   = %{$config{temp_colors}{colors_per_level}};
	undef(%{$config{temp_colors}{colors_per_level}});
	foreach my $prefix (keys %{$config{temp_colors}})
	{
		# Util::print_message("$config{temp_colors}{$prefix}");
		if(ref($config{temp_colors}{$prefix}) eq "HASH")
		{
			Util::print_message("***** Ignoring config{temp_colors}{$prefix}");
		}
		else
		{
# 			Util::print_message("config{temp_colors}{$prefix}");
			if($config{temp_colors}{$prefix} =~ m/(.*),(.*)/g)
			{
				$config{colors}{$prefix}{textcolor} = $1;
				$config{colors}{$prefix}{bgcolor}   = $2;
			}
		}
	}
	$config{colors}{change_highlight_background} = "honeydew3";
	$config{colors}{change_highlight_text}       = "black";

	#print Dumper(\%{$config{colors}});
	#exit;
}

# ok
sub read_institutions_list()
{
	my $inst_list_file 	= GetInternalTemplate("institutions-list");
	Util::print_message("Reading $inst_list_file ...");
	open(IN, "<$inst_list_file") or Util::halt("read_inst_list: $inst_list_file does not open");
	my @lines = <IN>;
	close(IN);
	my $count = 0;
	foreach my $line (@lines)
	{
		#                   CS-SPC     : Peru	   : Computing : SPC       : Plan2010 : final
		if($line =~ m/\s*(.*?)-(.*?)\s*:\s*(.*?)\s*:\s*(.*?)\s*:\s*(.*?)\s*:\s*(.*?)\s*:\s*(.*?)\s*/)
		{
			# Util::print_message("line = $line");
			my ($area, $institution, $country, $discipline, $filter, $plan, $version)= ($1, $2, $3, $4, $5, $6, $7);
			$inst_list{$country}{$institution}{$area}{area}       				= $area;
			$inst_list{$country}{$institution}{$area}{institution}       		= $institution;
			$inst_list{$country}{$institution}{$area}{country}    				= $country;
			$inst_list{$country}{$institution}{$area}{country_without_accents}	= filter_non_valid_chars($country);
			$inst_list{$country}{$institution}{$area}{discipline} 				= $discipline;
			$inst_list{$country}{$institution}{$area}{filter}     				= $filter;
			$inst_list{$country}{$institution}{$area}{plan}       				= $plan;
			$inst_list{$country}{$institution}{$area}{version}    				= $version;
			$count++;

 			# $country = filter_non_valid_chars($country);
			@{$config{list_of_countries}{$country}} = [];

			# By Discipline
			$config{Curriculas}{disc}{$discipline}{$country}{$config{area}}{$institution}{order} = $count;
			if(not defined($config{Curriculas}{disc}{$discipline}{$country}{$config{area}}{$institution}{Plans}))
			{	$config{Curriculas}{disc}{$discipline}{$country}{$config{area}}{$institution}{Plans} = [];	}
			push(@{$config{Curriculas}{disc}{$discipline}{$country}{$config{area}}{$institution}{Plans}}, $plan);

			# By Country
			$config{Curriculas}{country}{$country}{$discipline}{$config{area}}{$institution}{order} = $count;
			#$config{Curriculas}{country}{$country}{$discipline}{$config{area}}{$institution}{Plans}{$plan} = ();
			$config{Curriculas}{country}{$country}{$discipline}{$config{area}}{$institution}{Plans}{$plan}{version} = $version;

			# By Area
			$config{Curriculas}{area}{$area} = "";

			$list_of_areas{$institution}{$config{area}} = "";
		}
		else
		{
			#print "No match \"$line\"\n";
		}
	}
	Util::print_message("read_inst_list ($count)");
	Util::check_point("read_institutions_list");
}

sub generate_html_index_by_country()
{
      #       $config{Curriculas}{country}{$country}{$discipline}{$area}{$institution}{order} = $count++;
      my $countries_list_html = "";
      my $list_of_institutions_html = "";
      foreach my $country (sort keys %{$config{Curriculas}{country}})
      {
	    my $list_of_institutions_by_country_in_html_global = "";
	    my @list_of_institutions_by_country_in_html = ("", "");
	    my $country_no_accents = no_accents($country);
	    my $country_in_html = special_chars_to_html($country);

	    Util::print_message("Processing country: $country ...");
	    my @counter_by_country = (0, 0);

	    foreach my $discipline (sort keys %{$config{Curriculas}{country}{$country}})
	    {
		  Util::print_message("  Processing discipline: $discipline ...");
		  foreach my $area (sort keys %{$config{Curriculas}{country}{$country}{$discipline}})
		  {
			foreach my $inst (sort keys %{$config{Curriculas}{country}{$country}{$discipline}{$area}})
			{
			      my @list_of_plans = ("", "");
			      my @sep = ("", "");
			      my @counter_by_inst = (0, 0);
			      foreach my $plan (sort keys %{$config{Curriculas}{country}{$country}{$discipline}{$area}{$inst}{Plans}})
			      {
				    if( $config{Curriculas}{country}{$country}{$discipline}{$area}{$inst}{Plans}{$plan}{version} eq "final" )
				    {
					  Util::print_message("\tProcessing institution: $area/$inst ($plan) ...");
					  $list_of_plans[0] .= " $sep[0]<a href=\"$country/$area/$inst/$plan\">$plan</a>";
					  $counter_by_country[0]++;
					  $counter_by_inst[0]++;
					  $sep[0] = ",";
				    }
				    else
				    {
					  $list_of_plans[1] .= " $sep[1]$plan (draft version)";
					  #Util::print_message("\t  Ignoring $area/$inst ($plan) (draft version) ...");
					  $counter_by_country[1]++;
					  $counter_by_inst[1]++;
					  $sep[1] = ",";
				    }
			      }
			      foreach my $i (0, 1)
			      {
				    if( $counter_by_inst[$i] > 0 )
				    {	  #$list_of_institutions_by_country_in_html .= "\t<ul>\n";
					  $list_of_institutions_by_country_in_html[$i] .= "\t<li>$area/$inst: $list_of_plans[$i]</li>\n";
					  #$list_of_institutions_by_country_in_html .= "\t</ul>\n";
				    }
			      }
			}
		  }
	    }
	    # Create the anchor ...
	    $countries_list_html .= "<a href=\"#$country_no_accents\">$country_in_html</a>\n ";

	    $country_no_accents =~ s/ //g;
	    my $country_lcase = lc($country_no_accents);
	    $list_of_institutions_by_country_in_html_global .= "<a name=\"$country_no_accents\"></a>\n ";
	    my $cmd = "cp \"".GetInCountryBaseDirExt($country)."/$country_lcase.gif\" ".GetTemplate("OutHtmlBase")."/.";
	    system($cmd);
	    my $flag = "<img src=\"$country_lcase.gif\">";
	    $list_of_institutions_by_country_in_html_global .= "<h1>$country_in_html $flag</h1>\n ";
	    $list_of_institutions_by_country_in_html_global .= "<ul>\n";
	    #$list_of_institutions_by_country_in_html_global .= "\t<li>$discipline</li>\n";
	    $list_of_institutions_by_country_in_html_global .= $list_of_institutions_by_country_in_html[0];
	    $list_of_institutions_by_country_in_html_global .= $list_of_institutions_by_country_in_html[1];
	    $list_of_institutions_by_country_in_html_global .= "</ul>\n";
	    $list_of_institutions_by_country_in_html_global .= "\n";

	    if( $counter_by_country[0] + $counter_by_country[1] > 0 )
	    {	$list_of_institutions_html .= $list_of_institutions_by_country_in_html_global;	}
# 	    Util::write_file(GetTemplate("OutHtmlBase")."/$country.html", $list_of_institutions_by_country_in_html);
      }
      my $output_html = "$countries_list_html\n\n";
      $output_html .= $list_of_institutions_html;

      Util::write_file(GetTemplate("OutHtmlBase")."/countries.html", $output_html);
#       $path_map{"OutputDisciplinesList-file"}	= $config{OutputHtmlDir}."/disciplines.html";

#       $config{Curriculas}{disc}{$discipline}{$country}{$area}{$inst}{order} = $count++;
#       $config{Curriculas}{disc}{$discipline}{$country}{$area}{$inst}{short_description} = "";
}

sub generate_index_for_this_discipline()
{
      my $disciplines_list_html = "";
      foreach my $discipline (keys %{$config{Curriculas}{disc}})
      {
	    Util::print_message("Processing discipline: $discipline ...");
	    my $countries_list_html = "";
	    foreach my $country (sort keys %{$config{Curriculas}{disc}{$discipline}})
	    {
		  Util::print_message("  Processing country: $country ...");

		  my $area_list_html = "";
		  foreach my $area (keys %{$config{Curriculas}{disc}{$discipline}{$country}})
		  {
			if(not $area eq $config{area})
			{    next;		}
			foreach my $inst (keys %{$config{Curriculas}{disc}{$discipline}{$country}{$area}})
			{
			      Util::print_message("      Processing institution: $inst ...");
			      foreach my $Plan (keys %{$config{Curriculas}{disc}{$discipline}{$country}{$area}{Plan}})
			      {
			      }
			      $countries_list_html .= "<a href=\" value=\"$country\">$country</option>\n";
			}
		  }
		  my $area_list_html_final .= "<SELECT NAME=\"$discipline-$country\">\n";
		  $area_list_html_final    .= "$area_list_html";
		  $area_list_html_final    .= "</SELECT>\n";
		  Util::write_file(GetTemplate("OutHtmlBase")."/$discipline-$country.html", $area_list_html_final);
	    }
	    Util::write_file(GetTemplate("OutHtmlBase")."/$discipline-countries.html", $countries_list_html);
      }
      Util::write_file(GetTemplate("OutputDisciplinesList-file"), $disciplines_list_html);
#       $path_map{"OutputDisciplinesList-file"}	= $config{OutputHtmlDir}."/disciplines.html";

#       $config{Curriculas}{disc}{$discipline}{$country}{$area}{$inst}{order} = $count++;
#       $config{Curriculas}{disc}{$discipline}{$country}{$area}{$inst}{short_description} = "";
}

sub generate_index_for_this_area_old()
{
      my $disciplines_list_html = "";
      foreach my $discipline (keys %{$config{Curriculas}{disc}})
      {
	    Util::print_message("Processing discipline: $discipline ...");
	    my $countries_list_html = "";
	    foreach my $country (sort keys %{$config{Curriculas}{disc}{$discipline}})
	    {
		  Util::print_message("  Processing country: $country ...");
		  $countries_list_html .= "<a href=\" value=\"$country\">$country</option>\n";
		  my $area_list_html = "";
		  foreach my $area (keys %{$config{Curriculas}{disc}{$discipline}{$country}})
		  {
			Util::print_message("    Processing area: $area ...");
			$area_list_html .= "\t<option value=\"$area\">$area</option>\n";
			my $insts_output = "";
			foreach my $inst (keys %{$config{Curriculas}{disc}{$discipline}{$country}{$area}})
			{
			      Util::print_message("      Processing institution: $inst ...");
			}
		  }
		  my $area_list_html_final .= "<SELECT NAME=\"$discipline-$country\">\n";
		  $area_list_html_final    .= "$area_list_html";
		  $area_list_html_final    .= "</SELECT>\n";
		  Util::write_file(GetTemplate("OutHtmlBase")."/$discipline-$country.html", $area_list_html_final);
	    }
	    Util::write_file(GetTemplate("OutHtmlBase")."/$discipline-countries.html", $countries_list_html);
      }
      Util::write_file(GetTemplate("OutputDisciplinesList-file"), $disciplines_list_html);
#       $path_map{"OutputDisciplinesList-file"}	= $config{OutputHtmlDir}."/disciplines.html";

#       $config{Curriculas}{disc}{$discipline}{$country}{$area}{$inst}{order} = $count++;
#       $config{Curriculas}{disc}{$discipline}{$country}{$area}{$inst}{short_description} = "";
}

sub load_meta_tags()
{
	my $country 								= $config{country_without_accents};
	$Common::config{meta_tags}{INST} 			= $config{institution};
	$Common::config{meta_tags}{FILTER}			= $inst_list{$country}{$config{institution}}{$config{area}}{filter};
	$Common::config{meta_tags}{VERSION}			= $inst_list{$country}{$config{institution}}{$config{area}}{version};
	$Common::config{meta_tags}{DISCIPLINE}		= $inst_list{$country}{$config{institution}}{$config{area}}{discipline};
	$Common::config{meta_tags}{AREA}			= $inst_list{$country}{$config{institution}}{$config{area}}{area};
	$Common::config{meta_tags}{OUTBIN}			= Common::GetTemplate("OutputBinDir");
	$Common::config{meta_tags}{IN_DIR}			= Common::GetTemplate("InDir");
    $Common::config{meta_tags}{IN_INST_DIR}		= Common::GetTemplate("InProgramDir");
	$Common::config{meta_tags}{IN_COUNTRY_DIR}	= Common::GetTemplate("InCountryDir");
	$Common::config{meta_tags}{OUTPUT_DIR}		= Common::GetTemplate("OutDir");
	$Common::config{meta_tags}{OUTPUT_PDF_INST_DIR}	= Common::GetTemplate("OutputPdfInstDir");
	$Common::config{meta_tags}{OUTPUT_INST_DIR}	= Common::GetTemplate("OutputInstDir");
	$Common::config{meta_tags}{OUT_LOG_DIR}		= Common::GetTemplate("OutputLogDir");
	$Common::config{meta_tags}{OUTPUT_TEX_DIR}	= Common::GetTemplate("OutputTexDir");
	$Common::config{meta_tags}{OUTPUT_DOT_DIR}	= Common::GetTemplate("OutputDotDir");
	$Common::config{meta_tags}{OUTPUT_FIGS_DIR}	= Common::GetTemplate("OutputFigsDir");
	#$Common::config{meta_tags}{OUTPUT_INST_FIGS_DIR}	= Common::GetTemplate("OutputInstFigsDir");
	$Common::config{meta_tags}{OUTPUT_SCRIPTS_DIR}= Common::GetTemplate("OutputScriptsDir");
	$Common::config{meta_tags}{OUTPUT_HTML_DIR}= Common::GetTemplate("OutputHtmlDir");
	$Common::config{meta_tags}{OUTPUT_HTML_DOCS_DIR}= Common::GetTemplate("OutputHtmlDocsDir");
	$Common::config{meta_tags}{OUTPUT_HTML_FIGS_DIR}= Common::GetTemplate("OutputHtmlFigsDir");
	$Common::config{meta_tags}{OUTPUT_CURRICULA_HTML_FILE}=Common::GetTemplate("output-curricula-html-file");
	$Common::config{meta_tags}{OUTPUT_INDEX_HTML_FILE}=Common::GetTemplate("output-index-html-file");
	$Common::config{meta_tags}{COUNTRY}			= Common::GetTemplate("country_without_accents");
	$Common::config{meta_tags}{LANG}			= Common::GetTemplate("language_without_accents");
	$Common::config{meta_tags}{IN_LANG_BASE_DIR}= Common::GetTemplate("InLangBaseDir");
	$Common::config{meta_tags}{IN_LANG_DIR}	= Common::GetTemplate("InLangDefaultDir");
	$Common::config{meta_tags}{IN_TEX_DIR}	= Common::GetTemplate("InTexDir");
	$Common::config{meta_tags}{HTML_FOOTNOTE}	= $Common::config{HTMLFootnote};
	$Common::config{meta_tags}{SEM_ACAD}		= $Common::config{Semester};
	$Common::config{meta_tags}{PLAN}			= $Common::config{Plan};
	$Common::config{meta_tags}{FIRST_SEM}		= $Common::config{SemMin};
	$Common::config{meta_tags}{LAST_SEM}		= $Common::config{SemMax};
	($Common::config{meta_tags}{UNIFIED_MAIN_FILE} = Common::GetTemplate("unified-main-file") ) =~ s/\.tex//g;
	($Common::config{meta_tags}{MAIN_FILE} 		 = Common::GetTemplate("curricula-main")    ) =~ s/\.tex//g;
	my ($listoflagsPrefixes, $sep) = ("", "");
	foreach my $lang (@{$config{SyllabusLangsList}})
	{
	      $listoflagsPrefixes .= "$sep'$config{dictionaries}{$lang}{lang_prefix}'";
		  $sep = " ";
	}
	$Common::config{meta_tags}{LIST_OF_LANGS}	= $listoflagsPrefixes;
	Util::check_point("meta_tags_loaded");
}

sub replace_meta_tags($$)
{
	my ($txt, $lang)	= (@_);
	Util::precondition("meta_tags_loaded");
	$Common::config{meta_tags}{IN_TEX_DIR}	= Common::GetExpandedTemplateWithLang("InTexDir", $lang);
	$Common::config{meta_tags}{LANG_PREFIX} = $Common::config{dictionaries}{$lang}{lang_prefix};
	my %meta_tags_expanded;
	# print Dumper (\%{$Common::config{meta_tags}});
	foreach my $key (keys %{$Common::config{meta_tags}})
	{	$meta_tags_expanded{$key} = ExpandTags2($Common::config{meta_tags}{$key}, 
												$config{country_without_accents}, $config{institution}, 
												$config{area}, $config{Semester}, 
												$config{CurriculaVersion}, $lang);
	}
	$txt = Common::replace_tags_from_hash($txt, "<", ">", %meta_tags_expanded);
	return $txt;
}

sub gen_batch($$$) 
{
	Util::precondition("read_institutions_list");
	my ($source, $target, $lang) = (@_);
	# Util::print_message("gen_batch: $source -> $target ...");
	my $txt = Util::read_file($source);
	$txt 	= replace_meta_tags($txt, $lang);
	Util::write_file($target, $txt);
	my ($path, $file) = Util::GetPathAndFile($target);
	Util::print_message("$Util::icons{ok} batch created $path".Util::green($file));
	system("chmod 774 $target");
}

sub read_copyrights($)
{
	my ($file) = (@_);
	my $txt  = Util::read_file($file);
	my %file_info = ();
	# Read the HTMLFootnote
	if($txt =~ m/\\newcommand\{\\HTMLFootnote\}\{\{(\s*(?:.|\n)*?)\}\}/)
	{
		$file_info{HTMLFootnote} = $1;
		$file_info{HTMLFootnote} =~ s/\n/ /g;
		$file_info{HTMLFootnote} =~ s/\t/ /g;
		$file_info{HTMLFootnote} =~ s/\s\s/ /g;
	}
	else
	{	Util::print_error("(read_copyrights): there is not \\HTMLFootnote configured in \"$file\" ...\n");
	}
	Util::check_point("read_copyrights");
	Util::print_message("read_copyrights ($file) ... OK !");
	return %file_info;
}

# ok
sub process_institution_info($$)
{
	# TODO Aqui me quede: hay que partir esta funcion en dos process porque regraba el archivo luego de leerlo y aumentarle cosas ...
	my ($txt, $file) = (@_);
	# Util::print_message("process_institution_info ... file=\n$file"); exit;
	my %this_inst_info = ();
	my %macros = parse_macros($txt);
	#print Dumper(\%macros); exit;

    # Read PlanConfig
	my $PlanConfig 			= "";
	my $PathForConfigFile	= "InProgramDir";
	if($txt =~ m/\\input\{\\$PathForConfigFile\/(Plan.*?-Sem.*?.config)\}/)
	{	$PlanConfig = $1;
		my $Plan = "";
		$this_inst_info{PlanConfig} = $PlanConfig;
		Util::print_message("$Util::icons{ok} Processing PlanConfig: $PlanConfig");
		$PlanConfig =~ m/(Plan.*?)-Sem(.*?).config/;	
		($Plan, $this_inst_info{Semester}) = ($1, $2);
		if( not $Plan eq $config{Plan})
		{	Util::print_message("$Util::icons{X} Something is wrong ...".
								Util::red("Plans don't match").
								" ($Plan, $config{Plan})\n".
								"See ".Util::red("$file"));
			Util::print_message("and also: ".Util::highlight_filename(GetInternalTemplate("institutions-list")) );
			Util::print_message("You just need to change the plan at: :".Util::highlight_filename(GetInternalTemplate("institutions-list")));
								exit;
		}
		Util::print_message("$Util::icons{ok} Semester=$this_inst_info{Semester} ...");
	}
	else
	{	Util::print_message("$Util::icons{X} Something is wrong. Did you configure: ".
							Util::red("\\input\{\\$PathForConfigFile\/$config{Plan}-Sem202x-##.config}"). 
							"\nSee file: $file");	
		exit;
	}
	my $PlanConfigFile = GetTemplate("$PathForConfigFile")."/$PlanConfig.tex";
	if(not -e $PlanConfigFile)
	{	Util::print_message("$Util::icons{X} ". Util::red("file not found! $PlanConfig")."\nSee $file ...");
		exit;
	}
	
	my %PlanConfigVars 			= read_macros($PlanConfigFile);
	$PlanConfigVars{Semester} 	= $this_inst_info{Semester};
	###################################################################################################
	# Read the Active Plan
	if( defined($PlanConfigVars{YYYY}) )
	{	($this_inst_info{YYYY}) = ($PlanConfigVars{YYYY} =~ m/(.*)\\.*/);
		 $PlanConfigVars{YYYY} = $this_inst_info{YYYY};
		 $this_inst_info{Plan}	=  $config{Plan};
	}
	else
	{	Util::print_error("Error (process_institution_info): there is no YYYY (Plan) configured in \"$file\"\n");	}
	Util::print_message("YYYY=$this_inst_info{YYYY}, this_inst_info{Plan}=$this_inst_info{Plan}");

	###################################################################################################
	# Read the Range of semesters to generate 
	if(defined($PlanConfigVars{Range})) # \newcommand{\Range}{4-7} %Plan
	{	($this_inst_info{SemMin}, $this_inst_info{SemMax}) = ($PlanConfigVars{Range} =~ m/(\d*)-(\d*)/);	}
	else
	{	Util::print_warning("(process_institution_info): does not contain Range of semesters to generate (assuming all) \n");	}
	Util::print_message("Range:$PlanConfigVars{Range},SemMin=$this_inst_info{SemMin}, SemMax=$this_inst_info{SemMax} ...");

	###################################################################################################
	# Read the CurriculaVersion 
	if(defined($PlanConfigVars{CurriculaVersion}))
	{	($PlanConfigVars{CurriculaVersion}) = ($this_inst_info{CurriculaVersion}) = ($PlanConfigVars{CurriculaVersion} =~ m/(.*)\\.*/);		}
	else
	{	Util::print_warning("(process_institution_info): there is not \\CurriculaVersion configured in \"$file\" ... assuming 3 ...\n");
		$this_inst_info{CurriculaVersion} = 3;
	}
	Util::print_message("CurriculaVersion=$this_inst_info{CurriculaVersion} ...");
	################################
	@{$Common::config{macros}}{keys %PlanConfigVars} = values %PlanConfigVars;

	################################
	foreach my $key (keys %PlanConfigVars)
	{	Util::print_message("Common::config{macros}{$key} = $Common::config{macros}{$key} ...");	}

	# Read the dictionary
	if(defined($macros{dictionary}))
	{	if($macros{dictionary} =~ m/(.*?)\\.*?/)
		{	$this_inst_info{language_without_accents} 	= no_accents($1);
			$this_inst_info{language} 			= $1;
		}
	}
	else
	{	Util::print_error("process_institution_info: there is not \\dictionary configured in \"$file\"\n");	}

	# Read the GraphVersion
	$this_inst_info{graph_version} = 1;
	$this_inst_info{sep} = "|";
	$this_inst_info{hline} = "\\hline";
	if( defined($macros{GraphVersion}) )
	{	if($macros{GraphVersion} =~ m/(.*?)\\.*?/)
		{	$this_inst_info{graph_version} = $1;
			if($this_inst_info{graph_version} == 2)
			{	$this_inst_info{sep} = "";
				$this_inst_info{hline} = "";
			}
		}
		else
		{	Util::print_warning("(process_institution_info): there is not \\GraphVersion configured in \"$file\" ... assuming 1 ...\n");
		}
	}

	# Read the OutcomesVersion
	if($txt =~ m/\\OutcomesVersion\{(.*?)\}/)
	{	$this_inst_info{OutcomesVersion} = $1;		}
	else
	{	Util::print_error("(process_institution_info): there is not \\OutcomesVersion configured in:\n\"$file\" ... may be V1? ...\n");
		#$txt .= "\n\\OutcomesVersion\{$config{OutcomesVersionDefault}\}\n";
		#$this_inst_info{OutcomesVersion} = $config{OutcomesVersionDefault};
	}
	#Util::print_message("this_inst_info{OutcomesVersion}=$this_inst_info{OutcomesVersion}");
	#exit;

	# Read the outcomes list
	my $OutcomesError = "(process_institution_info): there is not \\OutcomesList configured in \"$file\" ... I am expecting something like: \\OutcomesList\{V1\}\{a,b,c,CG1,CG2\} ...\n";

	my $txt_copy = $txt;
	my @outcomes_array = $txt_copy =~ m/\\OutcomesList(\{.*?)\n/g;
	foreach my $params (@outcomes_array)
	{
		my ($version, $outcomeslist) = ($this_inst_info{OutcomesVersion}, "");
		if( $params =~ m/\{(.*?)\}\{(.*?)\}/g )
		{	($version, $outcomeslist) = ($1, $2);		}
		elsif( $params =~ m/\{(.*?)\}/g )
		{	$outcomeslist = $1;
			$txt_copy =~ s/\\OutcomesList\{$outcomeslist\}/\\OutcomesList\{$version\}\{$outcomeslist\}/g;
			Util::print_error("Wrong \\OutcomesList\{$outcomeslist\} ... Do you mean: \\OutcomesList\{$version\}\{$outcomeslist\} ... verify:\n".Util::red($file));
		}
		else{	Util::print_error($OutcomesError);	}
		Util::print_message("this_inst_info{outcomes_list}{$version} = $outcomeslist");
		if( defined($this_inst_info{outcomes_list}{$version}) && not $this_inst_info{outcomes_list}{$version} eq "" )
		{	Util::print_error("Many \\OutcomesList for the same version??? (\"$file\")");	}
		$this_inst_info{outcomes_list}{$version} = $outcomeslist;
	}

	#print Dumper(\%this_inst_info); 	exit;
	$txt = $txt_copy;

	# Read the logowidth
	if( defined($macros{logowidth}) )
	{	if( $macros{logowidth} =~ m/(\d*\.?\d*)(.*)/)
		{       $this_inst_info{logowidth}       = $1;
				$this_inst_info{logowidth_units} = $2;
				#Util::print_message("macros{logowidth}=$macros{logowidth}");
				#Util::print_message("this_inst_info{logowidth}=$this_inst_info{logowidth}, this_inst_info{logowidth_units}=$this_inst_info{logowidth_units}"); exit;
				#exit;
		}
		else
		{       Util::print_error("(process_institution_info): there is not \\logowidth configured in \"$file\" ...\n");
		}
	}
#         if($txt =~ m/\\newcommand{\\Copyrights}{(.*?)}/)
#         {       $this_inst_info{Copyrights} = $1;             }
#         else
#         {       Util::print_error("(process_institution_info): there is not \\Copyrights configured in \"$file\" ...\n");
#         }
	$this_inst_info{SyllabusLangs} 					= $macros{SyllabusLangs};
	$this_inst_info{SyllabusLangs} 					=~ s/ //g;
	$this_inst_info{SyllabusLangs_without_accents} 	= no_accents($this_inst_info{SyllabusLangs});
	my @lang_prefixes = ();
	my $count = 0;
	foreach my $lang ( split(",", $this_inst_info{SyllabusLangs_without_accents}) )
	{	push( @{$this_inst_info{SyllabusLangsList}}, $lang);
		my $lang_prefix = "";
		if( $lang =~ m/(..)/g )
		{		$lang_prefix = uc($1);	      }
		#%{$config{dictionaries}{$lang}} 		= read_dictionary_file($lang);
		push(@lang_prefixes, $lang_prefix);
		#Util::print_message("config{dictionaries}{$lang}{lang_prefix} = $config{dictionaries}{$lang}{lang_prefix}"); 
		if( $count == 0 )
		{	$this_inst_info{DefaultLang} = $lang;	}
		$count++;
	}

	my @keys = ("fecha", "city", "country", "doctitle", "AbstractIntro", "OtherKeyStones",
				"equivalences", "underlogotext", 
				"SchoolURL", "InstitutionURL", "SyllabusLangs");
	for my $extra_key ( "mission", "profile", "vision", 
						"AcademicDegreeIssued", "TitleIssued", "AcademicDegreeAndTitle",
						"SchoolFullName", "SchoolShortName", "SchoolFullNameBreak",
					   "FacultadName", "DepartmentName", "University")
	{	foreach my $lang_prefix (@lang_prefixes)
		{	push( @keys, "$extra_key$lang_prefix");
		}
		push( @keys, $extra_key);
	}
	#print Dumper(\@keys);	exit;	
	foreach my $key (@keys)
	{	$this_inst_info{$key} = "";
		if( defined($macros{$key}) )
		{
			$this_inst_info{$key}	= $macros{$key};
			#Util::print_message("this_inst_info{$key} = $this_inst_info{$key}"); exit;
		}
		else
		{	my $ErrorMsg = "(process_institution_info): there is not :".Util::red("\\$key")." in: \n".Util::green("\"$file\"");
			Util::print_message($ErrorMsg);	
			push(@{$Common::error{general}}, $ErrorMsg);
		}
	}
	# Now post processing some of them
	if(	$this_inst_info{country} =~ m/(.*?)\\.*?/ )
	{	$this_inst_info{country} = $1;	}
	$this_inst_info{country_without_accents} 	= filter_non_valid_chars($this_inst_info{country});

# 	Util::print_message("After ($file)\n$txt");
	# TODO
	#Util::print_warning("process_institution_info() I am not updating this file anymore ... See \\OutcomesList above");
	#Util::write_file($file, $txt);
	
	Util::check_point("process_institution_info");
	Util::print_message("institution_info ($file) ... OK !");
	#print Dumper(\%this_inst_info); exit;
	return %this_inst_info;
}

sub read_specific_evaluacion_info()
{
	Util::precondition("filter_courses");
	my $specific_evaluation_file = GetTemplate("in-specific-evaluation-file");
	#Util::print_message("Common::config{SyllabusLangs_without_accents} = $Common::config{SyllabusLangs_without_accents}");
	if(not -e $specific_evaluation_file)
	{	Util::print_warning("No specific evaluation file ($specific_evaluation_file) ... you may create one to specify criteria for each course ...");	}
	else
	{
	      Util::print_message("Reading specific evaluation file ($specific_evaluation_file) ...");
	      my $specific_evaluation = Util::read_file($specific_evaluation_file);
	      while($specific_evaluation =~ m/\\begin\{evaluation\}\{(.*?)\}((?:.|\n)*?)\\end\{evaluation\}/g)
	      {
		      my ($cc, $this_evaluation_body) = ($1, $2);
		      my $codcour = unmask_codcour($cc);
		      #Util::print_message("this_evaluation_body=\n$this_evaluation_body");
		      if ( $this_evaluation_body  =~ m/\{(.*?)\}\{(.*?)\}\s*\n((?:.|\n)*)/g)
		      {
			    my ($listoflags, $parts, $eval) = ($1, $2, $3);
			    $parts =~ s/ //g;	$listoflags =~ s/ //g;
			    #Util::print_message("listoflags=$listoflags, $parts$parts, eval=\n$eval");
			    if( $listoflags eq "*" ){	$listoflags = $Common::config{SyllabusLangs_without_accents};		}
			    my $output_parts = "";
			    foreach my $onepart (split(",", $parts))
			    {
				  $output_parts .= "{\\noindent\\textbf{<<$onepart-SESSIONS>>:}}\\\\\n";
				  $output_parts .= "<<$onepart-SESSIONS-CONTENT>>\n";
				  $output_parts .= "\n\\vspace{2mm}\n";
			    }
			    foreach my $lang (split(",", $listoflags))
			    {
					if(not defined($config{dictionaries}{$lang}{lang_prefix}) )
					{	Util::print_error("$cc($codcour) has an undefined Language($lang) !...");		}
					my $evaluation_header = "\\vspace{2mm}\n";
					$evaluation_header .= "{\\noindent\\textbf{<<EVALUATION-SYSTEM>>:}}\\\\\n";
					$Common::course_info{$codcour}{$lang}{specific_evaluation} = "$output_parts\n$evaluation_header$eval\n";
					#$Common::course_info{$codcour}{$lang}{specific_evaluation} = "$output_parts\n$eval\n";

					Util::print_warning("$cc($codcour) specific_evaluation ($lang) detected!");
					#Util::print_message("$Common::course_info{$codcour}{$lang}{specific_evaluation}"); exit;
					#if($codcour eq "CS111") { 	Util::print_message("C. Common::course_info{$codcour}{specific_evaluation}=\n$Common::course_info{$codcour}{specific_evaluation}");	exit;}
					#Util::print_message("$Common::course_info{$codcour}{specific_evaluation}");
			    }
		      }
		      else
		      {
			    Util::print_error("Specific Evaluation for $cc($codcour) out of format?\nfile: $specific_evaluation_file ");
		      }
	      }
	}
	#Util::print_message("Reading specific evaluation file ($specific_evaluation_file) ok !...");
	#exit;
}

# ok
sub parse_input_command($)
{
	my ($command) = (@_);
	if($command =~ m/(.*)-(.*)-(.*)/)
	{
        ($config{country}, $config{area}, $config{institution}) = ($1, $2, $3);
		$config{country_without_accents} = $config{country};
	}
	else
	{	Util::halt("There is no command to process (i.e COUNTRY-AREA-INST)");
	}
}

sub process_filters()
{
	my $country 	= $config{country_without_accents};
	my $institution = $config{institution};
	my $area		= $config{area};
	if( defined($config{country_without_accents}) && defined($config{institution}) && defined($config{area})) 
	{
		if(not defined($inst_list{$country}{$institution}{$area}{filter}))
		{
			Util::print_message("Some problems ! country=".Util::red($country).", institution=".Util::red($institution).", area=".Util::red($area));
			Util::print_message("I guess* you forgot to add this institution at: ".Util::red(GetInternalTemplate("institutions-list")));
		 	exit;
		}
	}
	$inst_list{$config{country_without_accents}}{$config{institution}}{$config{area}}{filter} =~ s/ //g;
	my $priority = 100;
	foreach my $inst (split(",", $inst_list{$config{country_without_accents}}{$config{institution}}{$config{area}}{filter}))
	{
		$config{valid_institutions}{$inst}	= $priority;
		$config{filter_priority}{$inst}		= $priority;
		$priority--;
	}
}

sub verify_dependencies($)
{
	#my ($lang) = (@_);
	#my $lang_prefix = $config{dictionaries}{$lang}{lang_prefix};
    #my @files_to_verify = (Common::GetExpandedTemplateWithLang("InTexDir", $lang)."/abstract-$lang_prefix.tex");
    #foreach my $flag (keys %template_files)
    #{
	#	my $file = GetTemplate($template_files{$flag});
	#	if(-e $file)
	#	{	$config{flags}{$flag} = 1;	}
	#	else
	#	{	$config{flags}{$flag} = 0;	}
    #}
}

sub set_general_preconfiguration()
{
	$config{params}{"read_courses"} = 1;
	Util::check_point("set_initial_preconfiguracion");
}

sub set_preconfiguration_avoiding_courses()
{
	$config{params}{"read_courses"} = 0;
	Util::check_point("set_initial_preconfiguracion");
}

# First Parameter is something such as Peru-CS-SPC
sub set_initial_configuration($)
{
	my ($command) = (@_);
	Util::precondition("set_initial_preconfiguracion");
	$config{projectname} 	= "Curricula";
	($config{in}, $config{out})		= ("../$config{projectname}.in", "../$config{projectname}.out");
	($path_map{InDir}, $path_map{OutDir})	= ($config{in}, $config{out});
	$config{macros_file} 	= "";

	$config{encoding} 		= "latin1";
	$config{tex_encoding} 	= "utf8";
	#$config{lang_for_latex}{Espanol}   = "spanish";
	#$config{lang_for_latex}{English}   = "english";
	#$config{lang_for_latex}{Portugues} = "english";
	$config{empty_track} = "empty-track";
	$config{COL4LABS} = "lh";
    CreateDir("$config{out}/tex");

	# Parse the command
	parse_input_command($command);
	$path_map{"institutions-list"}	= "$config{in}/institutions-list.txt";
	read_institutions_list();

	my $country = $config{country_without_accents};
	if(not defined($inst_list{$country}{$config{institution}}{$config{area}}{plan}))
	{	Util::print_error("I couldnt find configuration for $command ... did you config at: ".$path_map{"institutions-list"}."?");		}
	$config{discipline}	  	= $inst_list{$country}{$config{institution}}{$config{area}}{discipline};
	$config{Plan}			= $inst_list{$country}{$config{institution}}{$config{area}}{plan};
	Util::print_message("config{Plan}=$config{Plan}");
    #Util::print_message("inst_list{$country}{$config{institution}}{$config{area}}{country}=$inst_list{$country}{$config{institution}}{$config{area}}{country}");

	$config{InProgramDir} 	= $path_map{InProgramDir} 	= GetProgramInDir();
	# Here ok this-institution-info-file
	$path_map{"this-institution-info-file"}   			= GetInCountryBaseDirExt($country)."/institutions/<INST>/<INST>.tex";
	# Here ok this-program-info-file
	$path_map{"this-program-info-file"}					= GetTemplate("InProgramDir")."/program-info.tex";
	$path_map{"copyrights"}								= "$config{in}/copyrights.tex";

	# Read copyrights
	my %copyrights_vars = read_copyrights( GetTemplate("copyrights") );
	foreach my $key (keys %copyrights_vars)	{	$config{$key} = $copyrights_vars{$key};	}

	# Read the config for this institution (name, URL)
	my $institution_file = GetTemplate("this-institution-info-file");
	Util::print_message("set_initial_configuration: Reading $institution_file ... ");
	my $institution_txt = Util::read_file( $institution_file );

	# Read the config for this program (lang, country, etc)
	my $program_file = GetTemplate("this-program-info-file");
	Util::print_message("set_initial_configuration: Reading $program_file ... ");
	my $program_txt  = Util::read_file( $program_file );
	my %inst_vars = process_institution_info( $institution_txt."\n".$program_txt, $institution_file."\n".$program_file );
	foreach my $key (keys %inst_vars)
	{	$config{$key} = $inst_vars{$key};
		$config{macros}{$key} = $inst_vars{$key};
	}
	# print Dumper(\%inst_vars);
	my $lang = $config{DefaultLang};
	my $this_lang = $lang;
	$config{language} = $lang;
	# Util::print_message( Util::red("Here ! lang=$config{DefaultLang}") ); exit;
 	#print Dumper(\%config); exit;
	
	$config{equivalences} =~ s/ //g;
# 	Util::print_message("config{equivalences} = \"$config{equivalences}\""); exit;

	$config{OutputInstDir}	    	= "$config{out}/$inst_list{$country}{$config{institution}}{$config{area}}{country}/$config{area}-$config{institution}/cycle/$config{Semester}/$config{Plan}";
	$config{LinkToCurriculaBase} 	= "http://education.spc.org.pe/$inst_list{$country}{$config{institution}}{$config{area}}{country}/$config{area}-$config{institution}/$config{Plan}";
	$config{OutHtmlBase}	    	= "$config{out}/html";

	
	# Set global variables, first phase
	set_global_variables();        #1st Phase
	
	# Parse filters for this institution
	process_filters();
	
	# set_initial_paths (useful for GetTemplate)
	set_initial_paths();
	read_dictionaries();

	# Verify dependencies
	# verify_dependencies($lang);

	Util::print_message(Util::yellow("Reading config files ..."));
	read_config(GetTemplate("all-config"));
	$path_map{"crossed-reference-file"}		= $config{main_file}.".aux";

	# Read configuration for this discipline
	read_discipline_config();

	my $ConfigFile = GetTemplate("in-area-all-config-file");
	my %area_vars = read_config($ConfigFile); 		# i.e. All.config 
	push(@{$config{config_file}}, $ConfigFile);
	while ( my ($key, $value) = each(%area_vars) ) # Overwrite some terms for this country !
	{	$config{$key} = $value; 	}

	$ConfigFile = GetTemplate("in-area-config-file");
 	read_config($ConfigFile);     		# i.e. CS.config
	push(@{$config{config_file}}, $ConfigFile);

	# Read specific config for its country
	$ConfigFile = GetExpandedTemplateWithLang("in-country-config-file", $lang);
	my %countryvars = read_config($ConfigFile);
	push(@{$config{config_file}}, $ConfigFile);
	while ( my ($key, $value) = each(%countryvars) ) # Overwrite some terms for this country !
	{	$config{dictionary}{$key} = $value; 	}
	#print Dumper(\%countryvars); exit;

	# Read customize vars for this institution (optional)
	my $inst_config_file = GetTemplate("in-institution-config-file");
	my %instvars = read_config_if_exists($inst_config_file);
	push(@{$config{config_file}}, $ConfigFile);

	# process_cycle_vars must be after process_courses

	#Util::print_message("CS=$config{dictionary}{AreaDescription}{CS}"); exit;
	%{$config{temp_colors}} = read_config_file(GetTemplate("colors"));
	my $InstitutionColorsFile = GetTemplate("institution-colors");
	if( -e $InstitutionColorsFile )
	{	my %inst_colors = read_config_file($InstitutionColorsFile);
		my ($key, $value) = ("", "");
		while( ($key, $value) = each (%inst_colors))
		{	$config{temp_colors}{$key} = $value;	}
	}
	#Util::print_color("Common::config{course_fields}=$Common::config{course_fields}");
	#exit;
	#Util::print_message("config{COL4LABS}=$config{COL4LABS}"); exit;
	$config{"country-environments-to-insert"} = "";
	my $file_to_insert = Common::GetExpandedTemplateWithLang("in-country-environments-to-insert-file", $lang);
	if(-e $file_to_insert)
	{	$config{"country-environments-to-insert"} = Util::read_file($file_to_insert);		}

        #Util::print_message($config{"country-environments-to-insert"}); exit;
 	process_config_vars();
	read_crossed_references();

	my $InStyDir = GetTemplate("InStyDir");
	my $InLangDefaultDir = GetTemplate("InLangDefaultDir");

	foreach my $file (split(",", $config{macros_file})) # read_bok is here
	{
		$file =~ s/<STY-AREA>/$InStyDir/g;
		$file =~ s/<LANG-AREA>/$InLangDefaultDir/g;
		my %macros = read_macros($file);
		@{$Common::config{macros}}{keys %macros} = values %macros;
	}
	#Util::print_message("Common::config{macros}{LearningOutcomesTxtEsFamiliarity}=$Common::config{macros}{LearningOutcomesTxtEsFamiliarity}");
	#exit;
	Util::print_color("Reading outcomes macros ..."); 
	foreach my $lang (@{$config{SyllabusLangsList}})
	{	
		#my $lang_prefix = $config{dictionaries}{$lang}{lang_prefix};
		my $outcomes_macros_file = Common::GetExpandedTemplateWithLang("in-outcomes-macros-file", $lang);
		if( not -e $outcomes_macros_file )
		{	printf("I have some problems opening: ".Util::red("$outcomes_macros_file")."\n");
			exit;
		}
		my %outcomes_macros = read_outcomes($outcomes_macros_file, $lang);
		my $noutcomes_read  = keys %outcomes_macros;
		foreach my $key (keys %outcomes_macros)
		{	# $Common::config{macros}{outcomes}{$lang}{outcomem}
			$Common::config{macros}{outcomes}{$lang}{$key} = $outcomes_macros{$key}; # ECV
			$Common::config{outcomes_keys}{$key} = "";	
		}
		@{$Common::config{macros}{$lang}}{keys %outcomes_macros} = values %outcomes_macros;
		if($lang eq $this_lang)
		{	foreach my $key (keys %outcomes_macros)
			{	$Common::config{macros}{$key} = $outcomes_macros{$key};		}
		}
		my %macros = read_macros($outcomes_macros_file);
		@{$Common::config{macros}}{keys %macros} = values %macros;
	}
	if(-e Common::GetTemplate("out-current-institution-file"))
	{	my %macros = read_macros(Common::GetTemplate("out-current-institution-file"));
		@{$Common::config{macros}}{keys %macros} = values %macros;
	}
	read_replacements($lang);
	$config{macros}{siglas}        = $config{institution};
	$config{macros}{spcbibstyle}   = $config{bibstyle};
	sort_macros();

	$config{recommended_prereq} = 1;
	$config{corequisites}       = 1;
	$config{verbose}            = 1;
	$config{except_file}{"config-hdr-foot-ES.tex"}     = ""; #Util::print_warning("Danger here ... Wilcards are missing for config-hdr-foot-<LANG>.tex");
	$config{except_file}{"config-hdr-foot-EN.tex"}     = "";
	$config{except_file}{"config-hdr-foot-BR.tex"}     = "";
	$config{except_file}{"current-institution.tex"}    = "";
	$config{except_file}{"outcomes-macros.tex"}        = ""; #Util::print_warning("Danger here ... Wilcards are missing for config-hdr-foot-<LANG>.tex");
	$config{except_file}{"program-info.tex"}		   = "";
	$config{except_file}{"$config{institution}.tex"}	       = "";
	#$config{except_file}{"outcomes-macros-ES.tex"}    = "";
	#$config{except_file}{"outcomes-macros-EN.tex"}    = "";
	#$config{except_file}{"outcomes-macros-BR.tex"}    = "";
	$config{except_file}{"custom-colors.tex"}          = "";

	#$config{change_file}{"topics-by-course.tex"}    = "topics-by-course-web.tex";
# 	@{$config{bib_files}}	                        = [];

	$config{subsection_label}	= "subsection";
	$config{bold_label}		= "textbf";

    $config{main_to_gen_fig}        = Util::read_file(GetTemplate("in-main-to-gen-fig"));
    Common::load_meta_tags();
	Util::check_point("set_initial_configuration");
}

sub read_crossed_references()
{
      my $crf = Common::GetTemplate("crossed-reference-file");
      return if(not -e $crf);
      my $txt = Util::read_file($crf);
      # \newlabel{out:Outcomed}{{d}{5}}
      while($txt =~ m/\\newlabel\{(.*?)\}\{\{(.*?)\}\{(.*?)\}\}/g)
      {
	    $config{references}{$1}{content}	= $2;
	    $config{references}{$1}{page}	= $3;
	    #Util::print_message("$1 value is $2");
      }
}

# ok
sub gen_only_macros()
{
	my $output_txt = "";

	$output_txt .= "% 1st by countries ...\n";
	foreach my $country (keys %{$config{list_of_countries}})
	{
		$country =~ s/ //g;
		$output_txt .= "\\newcommand{\\Only$country}[1]{";
		if($country eq $config{country_without_accents})
		{       $output_txt .= "\#1";   }
		$output_txt .= "\\xspace}\n";
		$output_txt .= "\\newcommand{\\Not$country}[1]{";
		if(not $country eq $config{country_without_accents})
		{       $output_txt .= "\#1";   }
		$output_txt .= "\\xspace}\n\n";
    }

    $output_txt .= "% 2st by areas ...\n";
	#print Dumper( \%{$config{Curriculas}{area}} ); 
	foreach my $onearea (keys %{$config{Curriculas}{area}})
	{
		$output_txt .= "\\newcommand{\\Only$onearea}[1]{";
		if($onearea eq $config{area})
		{       $output_txt .= "\#1";   }
		$output_txt .= "\\xspace}\n";

		$output_txt .= "\\newcommand{\\Not$onearea}[1]{";
		if(not $onearea eq $config{area})
		{       $output_txt .= "\#1";   }
		$output_txt .= "\\xspace}\n\n";
	}

	$output_txt .= "% And now by institutions ...\n";
	# $inst_list{$country}{$config{institution}}{$config{area}}
	foreach my $country (keys %inst_list)
	{
		foreach my $inst (keys %{$inst_list{$country}})
		{
			my $country_trimmed = $country;
			$country_trimmed =~ s/ //g;
			$output_txt .= "\\newcommand{\\Only$country_trimmed$inst}[1]{";
			if($inst eq $config{institution})
			{       $output_txt .= "\#1";   }
			$output_txt .= "\\xspace}\n";
			$output_txt .= "\\newcommand{\\Not$country_trimmed$inst}[1]{";
			if(not $inst eq $config{institution})
			{       $output_txt .= "\#1";   }
			$output_txt .= "\\xspace}\n\n";
		}
	}
	my $only_macros_file = GetTemplate("out-only-macros-file");
	Util::write_file($only_macros_file, $output_txt);
	Util::print_message("gen_only_macros ($only_macros_file) OK!");
}

sub gen_faculty_sql()
{
	my $output_sql = "";
	my ($user_count, $professor_count) = (10, 10);
	foreach my $email (keys %{$config{faculty}})
	{
		my ($username, $firstname, $lastname) = ("", "", "");
		if($email =~ /(.*)@.*/g)
		{	$username = $1;		}
		if($config{faculty}{$email}{name} =~ m/(.*?)\s(.*)\r/)
		{
			($firstname, $lastname) = ($1, $2);
		}
		$user_count++;
		$output_sql .= "INSERT INTO auth_user(id, username, first_name, last_name, email, password, ";
		$output_sql .= "is_staff, is_active, is_superuser)\n";
		$output_sql .= "\tVALUES($user_count, '$username', '$firstname', '$lastname', '$email', PASSWORD, 0, 0, 0);\n\n";

		my $shortcv = "";
		if( $config{faculty}{$email}{shortcv} =~ /(\\begin\{itemize\}(?:.|\n)*?\\end\{itemize\})/g )
		{	$shortcv = $1;	}
		my $title = "";
		if( $config{faculty}{$email}{title} =~ /(.*)\r/g )
		{	$title = $1;	}
		$professor_count++;
		$output_sql .= "INSERT INTO curricula_professor(id, user_id, shortBio, prefix_id)\n";
		$output_sql .= "\tVALUES($professor_count, $user_count, ";
		$output_sql .= "'$shortcv', '$title');\n\n";

	}
	Util::write_file("$config{OutputSqlDir}/docentes.sql", $output_sql);
}

# ok
sub read_faculty()
{
	my $faculty_file    		= GetTemplate("faculty-file");

	%{$config{degrees}} 		= ("PosDoc" => 7, "Doctor" => 6,      	"DoctorPT" => 5,
									"Master" => 4, "MasterPT" => 3,
									"Title"  => 2, "Degree" => 1,	"Bachelor" => 0);
	%{$config{degrees_description}} = (0 => "Bachelor",      1 => "Degree", 	1 => "Title",
										2 => "Master (Part Time)", 	3 => "Master (Full Time)",
										4 => "Doctor (Part Time)", 5 => "Doctor (Full Time)", 6 => "PosDoc");
	%{$config{prefix}}  		= ("Bachelor" => "Bach", "Degree" => "Prof.", "Title" => "Prof.",
									"MasterPT" => "Mag.", "Master" => "Mag.",
									"DoctorPT" => "Dr.", "Doctor" => "Dr.", "PosDoc" => "Post Doc.");
	%{$config{sort_areas}} 		= ("Computing" => 1, "Mathematics" => 2, "Science" => 3, "Engineering" => 4, "Enterpreneurship" => 5, "Business" => 6, "Humanities" => 7, "Empty" => 8 );

	%{$config{faculty}} = ();
	if(not -e $faculty_file)
	{
		Util::print_warning("There is no file for distribution: $faculty_file");
		Util::check_point("read_faculty");
		return;
	}
	my $input = Util::read_file($faculty_file);
	my $copy_input = $input;
	Util::print_message("Faculty file: $faculty_file found! processing now ...");
	while($input =~ m/--BEGIN-PROFESSOR--\s*\n\\email\{(.*?)\}((?:.|\n)*?)--END-PROFESSOR--?/g)
	{
		my ($email, $emailkey) = ($1, $1);
		if( $email eq "" )
		{    next;	}
		my $body  = "\\email{$email}\n$2";
		$emailkey =~ s/\@/./g;
 		# Util::print_message("Reading $email ...");
		($config{faculty}{$email}{fields}{prefix}, $config{faculty}{$email}{fields}{name}) 		= ("Prof.", "");

		foreach my $lang (@{$config{SyllabusLangsList}})
		{
		      ($config{faculty}{$email}{fields}{shortcv}{$lang}, $config{faculty}{$email}{fields}{shortcvhtml}{$lang})   	= ("", "");
		}
		my $emailwithoutat = $email; $emailwithoutat =~ s/[@\.]//g;
		$config{faculty}{$email}{fields}{emailwithoutat} = $emailwithoutat;

		$config{faculty}{$email}{fields}{degreelevel} = -1;
		$config{faculty}{$email}{fields}{degreelevel_description} = "";
		$config{faculty}{$email}{concentration} = "";
		$config{faculty}{$email}{sub_area_specialization} = ""; # Computing
		$config{faculty}{$email}{fields}{anchor} = "$emailwithoutat";
		$config{faculty}{$email}{fields}{active} = 0;
		$config{faculty}{$email}{fields}{position}   = "Professor";
		$config{faculty}{$email}{fields}{dedication} = "TP";
		%{$config{faculty}{$email}{fields}{courses_assigned}} = ();

		my ($titles_raw, $others) = ("", "");
		my $new_titles = "\\begin{titles}\n";
		if($body =~ m/\\begin\{titles\}\s*\n((?:.|\n)*?)\\end\{titles\}\s*\n((?:.|\n)*?)/g)
		{
			($titles_raw, $others) = ($1, $2);

			# First remove titles and process them separately
			#Util::print_message("Body Antes ...");
			#print Dumper(\$body);
			$body =~ s/\\begin\{titles\}\s*\n((?:.|\n)*?)\\end\{titles\}//g;
			#Util::print_message("Body despues ...");
			#print Dumper(\$body);
			#exit;
			my $count = 0;
			foreach my $line ( split("\n", $titles_raw) )
			{
			    $line =~ s/\n//g; $line =~ s/\r//g;
			    if( $line =~ m/\\(.*?)(\{.*)/g )
			    {
					my ($degreelevel, $tail) = ($1, $2);
					if( not defined($config{degrees}{$degreelevel}) )
					{
						Util::print_soft_error("I do not recognize this degree level ($email): \"\\$degreelevel\"\n");
						$new_titles .= $line;
					}
					else
					{
	# 				    Util::print_message("Processing $email tail ($tail)");
						my ($lang, $concentration, $area, $sub_area_specialization, $institution_of_degree, $country, $year) = ("", "", "", "", "", "", "");
						if( $tail =~ m/\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}/g )
						{	($lang, $concentration, $area, $sub_area_specialization, $institution_of_degree, $country, $year) = ($1, $2, $3, $4, $5, $6, $7);

						if(not defined($Common::config{dictionaries}{$lang}) )
						{
							Util::print_warning("Fixing language $lang->$Common::config{SyllabusLangsList}[0] in $line");
							$lang = $Common::config{SyllabusLangsList}[0];
						}
						}
						elsif ( $tail =~ m/\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}/g )
						{
							($concentration, $area, $sub_area_specialization, $institution_of_degree, $country, $year) = ($1, $2, $3, $4, $5, $6, $7);
							Util::print_warning("Adding language $Common::config{SyllabusLangsList}[0] in $line");
							$lang = $Common::config{SyllabusLangsList}[0];
						}
						else{
							Util::print_soft_error("Faculty $email has an error in the degree \\$degreelevel ... $tail\n");
							$new_titles .= $line;
							next;
						}
						if( $concentration eq "" )
						{	$concentration = "Empty";	}
						if($config{degrees}{$degreelevel} > $config{faculty}{$email}{fields}{degreelevel})
						{
							$config{faculty}{$email}{fields}{degreelevel}			= $config{degrees}{$degreelevel};
							$config{faculty}{$email}{fields}{degreelevel_description}	= $config{degrees_description}{$config{degrees}{$degreelevel}};
							$config{faculty}{$email}{fields}{prefix} 			= $config{prefix}{$degreelevel};
							$config{faculty}{$email}{concentration} 			= $concentration;
							$config{faculty}{$email}{sub_area_specialization}	 	= $sub_area_specialization;
						}

						# Add 1 to the counter of Doctors, Magisters, etc
						if( not defined($config{counters}{$degreelevel}) ) {	$config{counters}{$degreelevel} = 0;}
						$config{counters}{$degreelevel}++;
						$config{faculty}{$email}{fields}{shortcvline}{$degreelevel}{$lang}{txt} = "$area, $institution_of_degree, $country, $year.";
						$config{faculty}{$email}{fields}{shortcvline}{$degreelevel}{$lang}{concentration}	= $concentration;
						$config{faculty}{$email}{fields}{shortcvline}{$degreelevel}{$lang}{area}		= $area;
						$config{faculty}{$email}{fields}{shortcvline}{$degreelevel}{$lang}{sub_area_specialization}		= $sub_area_specialization;
						$config{faculty}{$email}{fields}{shortcvline}{$degreelevel}{$lang}{institution_of_degree}= $institution_of_degree;
						$config{faculty}{$email}{fields}{shortcvline}{$degreelevel}{$lang}{country}		= $country;
						$config{faculty}{$email}{fields}{shortcvline}{$degreelevel}{$lang}{year}		= $year;

						$count++;
						$new_titles .= "\t\\$degreelevel"."{$lang}{$concentration}{$area}{$sub_area_specialization}{$institution_of_degree}{$country}{$year}\n";
					}
			    }
			    else{ 	$new_titles .= $line;	}
			}
 			if( $count == 0 )
 			{
 				Util::print_soft_error("Professor $email does not contain recognized degrees ...\n")
 			}

			# Second, process the rest of fields such as name, WebPage, Phone, courses, facebook, twitter, etc
			while( $body =~ m/\\(.*?)\{(.*?)\}/g )
			{
			      my ($field, $val) = ($1, $2);
			      $field =~ s/ //g;
			      $field = lc $field;
			      if( $val ne "" )
			      {		$config{faculty}{$email}{fields}{$field} = $val;
			      }
			}
		}
		my $base_lang = $config{SyllabusLangsList}[0];
		foreach my $lang (@{$config{SyllabusLangsList}})
		{
			foreach my $degreelevel (sort {$config{degrees}{$b} <=> $config{degrees}{$a}}
						  keys %{$config{faculty}{$email}{fields}{shortcvline}})
			{
				if( not defined($config{faculty}{$email}{fields}{shortcvline}{$degreelevel}{$lang}) )
				{
					%{$config{faculty}{$email}{fields}{shortcvline}{$degreelevel}{$lang}} = %{ clone(\%{$config{faculty}{$email}{fields}{shortcvline}{$degreelevel}{$base_lang}})};

					my $concentration			= $config{faculty}{$email}{fields}{shortcvline}{$degreelevel}{$lang}{concentration};
					my $area					= $config{faculty}{$email}{fields}{shortcvline}{$degreelevel}{$lang}{area};
					my $sub_area_specialization	= $config{faculty}{$email}{fields}{shortcvline}{$degreelevel}{$lang}{sub_area_specialization};
					my $institution_of_degree	= $config{faculty}{$email}{fields}{shortcvline}{$degreelevel}{$lang}{institution_of_degree};
					my $country					= $config{faculty}{$email}{fields}{shortcvline}{$degreelevel}{$lang}{country};
					my $year					= $config{faculty}{$email}{fields}{shortcvline}{$degreelevel}{$lang}{year};

					$config{faculty}{$email}{fields}{shortcvline}{$degreelevel}{$lang}{txt} = "$area, $institution_of_degree, $country, $year.";
					$new_titles 	       .= "\t\\$degreelevel"."{$lang}{$concentration}{$area}{$sub_area_specialization}{$institution_of_degree}{$country}{$year}\n";
				}
				if( $Common::config{degrees}{$degreelevel} >= $Common::config{degrees}{MasterPT} )
				{
					my $degree_prefix = "<<".$degreelevel."In>>";
					$config{faculty}{$email}{fields}{shortcv}{$lang}     .= "\\item $degree_prefix $config{faculty}{$email}{fields}{shortcvline}{$degreelevel}{$lang}{txt}\n";
					$config{faculty}{$email}{fields}{shortcvhtml}{$lang} .= "\t<li>$config{faculty}{$email}{fields}{shortcvline}{$degreelevel}{$lang}{txt}</li>\n";
				}
			}
		}
		#print Dumper(\%{$config{faculty}{$email}{fields}{shortcvline}}); exit;
		$new_titles .= "\\end{titles}";
		$titles_raw = Common::replace_special_chars($titles_raw);
		$copy_input =~ s/\\begin\{titles\}\s*\n$titles_raw\\end\{titles\}/$new_titles/g;
 		#Util::print_message($new_titles);

		if( not defined($config{faculty}{$email}{fields}{courses}) )
		{	$config{faculty}{$email}{fields}{courses} = "";		}
		my $originalListOfCourses = $config{faculty}{$email}{fields}{courses};
		$config{faculty}{$email}{fields}{courses} 			=~ s/ //g;
		%{$config{faculty}{$email}{fields}{courses_assigned}} = ();
		my ($newListOfCourses, $sep) = ("", "");
		foreach my $codcour ( split(",", $config{faculty}{$email}{fields}{courses} ) )
		{
		      if( defined($config{map_file_to_course}{$codcour}) )
		      {
			    $newListOfCourses .= "$sep$config{map_file_to_course}{$codcour}";
		      }
		      else{
			    $newListOfCourses .= "$sep$codcour";
			    if( not defined($course_info{$codcour}) )
			    {	Util::print_warning("$email course: \"$codcour\" is not recognized ! ... just ignoring it !");	}
		      }
		      $sep = ",";
		}

		#print Dumper (%{$config{map_file_to_course}}); exit;
		#$copy_input =~ s/CS111,CS402/CS1100,CS4002/s;
		#Util::print_warning("$email Before: $config{faculty}{$email}{fields}{courses}. After: $newListOfCourses");
		$copy_input =~ s/\\courses\{$originalListOfCourses\}/\\courses\{$newListOfCourses\}/g;
		$config{faculty}{$email}{fields}{courses} = $newListOfCourses;
		foreach my $codcour ( split(",", $config{faculty}{$email}{fields}{courses} ) )
		{	$Common::config{faculty}{$email}{fields}{courses_i_could_teach}{$codcour} = "";
			$Common::config{courses_i_could_teach}{$codcour}{$email} = "";
		}
	}
										
	#Util::print_message("$copy_input");
	Util::write_file($faculty_file, $copy_input);
	Util::check_point("read_faculty");
#   print Dumper(\%{$config{faculty}{"ecuadros\@ucsp.edu.pe"}});
}

sub read_distribution()
{
	Util::precondition("set_initial_paths");
	my $distribution_file = GetTemplate("in-distribution-file");
	my $highlighted_text  = Util::highlight_filename($distribution_file);
	#Util::uncheck_point("read_distribution");
	Util::print_message(Util::yellow("read_distribution").": $highlighted_text");
	if( not -e "$distribution_file" )
	{
	    my $distribution_dir = GetTemplate("in-distribution-dir");
	    CreateDir($distribution_dir);
	    Util::write_file($distribution_file, "");
	    Util::print_warning("read_distribution: \"$distribution_file\" does not exist ... I created a new one :)");
	}
	if( not open(IN, "<$distribution_file") )
	{
	    Util::print_error("read_distribution: I can not open \"$distribution_file\"");
	    exit;
	}
	my $count   		= 0;
	my $line_number 	= 0;
	my $codcour 		= "";
	my $codcour_alias   = "";
	my $error_count 	= 0;
	while(<IN>)
	{
		$line_number++;
		my $line = $_;
		$line =~ s/\r//g;
		$line =~ s/\s//g;
		if($line =~ m/([A-Z|a-z|0-9]*)->\s*(.*)\s*/)
		{
			$codcour   = $1;
			my $emails = $2;
			$codcour_alias = $codcour;
			$codcour = unmask_codcour($codcour);
			if( not defined($course_info{$codcour}) )
			{	Util::print_message("Course ".Util::red("\"$codcour\"")." assigned in \"$distribution_file\" does not exist (line: $line_number) ... ");
				$error_count++;
				next;
			}
			$codcour = get_alias($codcour);
			if( $codcour eq "" )
			{	Util::print_message("Course ".Util::red("$codcour_alias ($codcour)")." is empty ! codcour=$codcour, $course_info{$codcour}{name}=$course_info{$codcour}{alias}");
				$error_count++;
				next;
			}
#
			if(not defined($config{distribution}{$codcour}))
			{
				$config{distribution}{$codcour} = ();
			}
			#print "\$config{distribution}{$codcour} ... = ";
			my $sequence = 1;
			foreach my $one_professor_assignment ( split(",", $emails) )
			{
				my $professor_email = "";
				my $professor_role  = "-";
				if($one_professor_assignment =~ m/(.*):(.*)/)
				{	$professor_email = $1;
					$professor_role  = $2;
				}
				else{
				      $professor_email = $one_professor_assignment;
				      Util::print_soft_error("distribution error($distribution_file) ... $codcour_alias($codcour):$one_professor_assignment ... no role assigned?");
					  $error_count++;
				}
 				if( defined($config{faculty}{$professor_email}) )
				{
				      if(not defined($config{distribution}{$codcour}{$professor_email}))
				      {		$config{distribution}{$codcour}{$professor_role}{$professor_email} = $sequence;
					  		$config{distribution}{$codcour}{list_of_professors}{$professor_email} = "";
						    $config{faculty}{$professor_email}{$codcour}{role} = $professor_role;
							$config{faculty}{$professor_email}{$codcour}{sequence} = $sequence;
							#print Dumper(\$config{faculty}{$professor_email}{fields}{courses_assigned});
							$config{faculty}{$professor_email}{fields}{courses_assigned}{$codcour} = "";
							$sequence++;
				      }
        		}
				else
				{
				    Util::print_message(Util::red("No professor information for email:").Util::yellow("\"$professor_email\" $codcour_alias($codcour).")." ... just ignoring it");
                    $config{ignored_email}{$codcour}  = "" if(not defined($config{ignored_email}{$codcour}));
                    $config{ignored_email}{$codcour} .= ",$professor_email";
					$error_count++;
				}
				#print "$professor_email ";
			}

			#print "\$config{distribution}{$codcour} .= ";
			#foreach my $email (%{$config{distribution}{$codcour}})
			#{
			#	print "$email ** ";
			#}
			#print "\n";
		}
		$count++;
	}
	close IN;
	
	if( $error_count > 0 )
	{	Util::print_message(Util::red("read_distribution")." some errors detected !");
	}
	Util::check_point("read_distribution");
	#print Dumper(\%{$config{faculty}{"ychirinos\@ucsp.edu.pe"}});
	#print Dumper(\%{$config{distribution}{"MA100"}});
	#print Dumper(\%{$config{distribution}{"CS404"}});
	#exit;
}

sub regenerate_distribution()
{
	my $distribution_file = GetTemplate("in-distribution-file");
	my $highlighted_text  = Util::highlight_filename($distribution_file);
	#system("rm $distribution_file");
	my $output_txt = "";
	for(my $semester= 1; $semester <= $config{n_semesters} ; $semester++)
	{
		my $this_sem_text  = "";
		my $this_sem_count = 0;
		my $ncourses       = 0;
		foreach my $codcour (@{$courses_by_semester{$semester}})
		{
			#Util::print_message("Regenerating distribution for $codcour ...");
			$codcour = get_alias($codcour);
			if( not defined($config{distribution}{$codcour}) )
			{
				#Util::print_warning("I do not find professor for course $codcour_alias ($codcour) ($semester sem) $course_info{$codcour}{$config{language_without_accents}}{course_name} ...");
			}
			else
			{	my $sep = "";
				$this_sem_text .= "% $codcour. $course_info{$codcour}{$config{language_without_accents}}{course_name} ($config{dictionary}{$course_info{$codcour}{course_type}})\n";
				$this_sem_text .= "$codcour->";
				my $faculty_list_of_emails = "";
				foreach my $professor_email (sort { $professor_role_order{$config{faculty}{$a}{$codcour}{role}} <=> $professor_role_order{$config{faculty}{$b}{$codcour}{role}} ||
													$Common::config{faculty}{$b}{fields}{degreelevel}           <=> $Common::config{faculty}{$a}{fields}{degreelevel} ||
													$Common::config{faculty}{$a}{$codcour}{sequence}            <=> $Common::config{faculty}{$b}{$codcour}{sequence}
												  }
						  		  keys %{ $Common::config{distribution}{$codcour}{list_of_professors}})
				{
										          #$config{distribution}{$codcour}{list_of_professors}{$professor_email} = "";
												  #$config{distribution}{$codcour}{$professor_role}{$professor_email} = $sequence;
												  #$config{faculty}{$professor_email}{$codcour}{role} = $professor_role;
												  #$config{faculty}{$professor_email}{$codcour}{sequence} = $sequence;
					#$config{distribution}{$codcour}{$professor_role}{$professor_email} = $sequence++;
					#foreach my $professor_email (sort {$config{faculty}{$b}{fields}{degreelevel} <=> $config{faculty}{$a}{fields}{degreelevel} ||
					#									$config{faculty}{$a}{$codcour}{sequence} <=> $config{faculty}{$b}{$codcour}{sequence}
					#								  }
					#							 #keys %{$config{distribution}{$codcour}{list_of_professors}}
					#			     			 keys %{$config{distribution}{$codcour}{$role}}
					#			    			)
					{
						$this_sem_text .= "$sep$professor_email:";
						$faculty_list_of_emails .= "$sep$professor_email";
						if(defined($config{faculty}{$professor_email}{$codcour}{role}))
						{	$this_sem_text .= $config{faculty}{$professor_email}{$codcour}{role};	}
						else{	$this_sem_text .= "-";		}

						$sep = ",";
						$config{faculty}{$professor_email}{fields}{active} 			= 1;
						$config{faculty}{$professor_email}{fields}{courses_assigned}{$codcour} 	= "";
					}
				}
				#Util::print_message("$this_sem_text ...");
				#print "\n";
				
				if( defined($config{ignored_email}{$codcour}) )
				{		$this_sem_text .= "$sep$config{ignored_email}{$codcour}\n";			}
				$this_sem_text .= "\n";

				# Set priority among professors
				$config{faculty_list_of_emails}{$codcour} = $faculty_list_of_emails;
				$ncourses++;
			}
		}
		if( $ncourses > 0 )
		{
			$output_txt .= "\n% Semester #$semester .\n";
			$output_txt .= "$this_sem_text\n";
		}
	}
	Util::print_message("$Util::icons{ok} Regenerating $highlighted_text OK!");
	Util::write_file("$distribution_file", $output_txt);
}

sub sort_faculty_list()
{
	Util::precondition("read_faculty");
	Util::precondition("read_distribution");
	my $faculty_priority = 0;
	my $error_count = 0;
	foreach my $email (	keys %{$Common::config{faculty}} )
	{
		if( not defined($position_ranking{$Common::config{faculty}{$email}{fields}{position}}) )
		{	Util::print_message("email:".Util::red($email).", position: ".Util::red("$Common::config{faculty}{$email}{fields}{position} not defined"));
			$error_count++;
		} 
	}
	if( $error_count > 0)
	{	exit;	}
	foreach my $email (	sort {    $config{faculty}{$b}{fields}{active}									 <=> $config{faculty}{$a}{fields}{active}								   
							   || $Common::config{faculty}{$b}{fields}{degreelevel}                     <=> $Common::config{faculty}{$a}{fields}{degreelevel}	                   
							   || $position_ranking{$Common::config{faculty}{$a}{fields}{position}}     <=> $position_ranking{$Common::config{faculty}{$b}{fields}{position}}     
							   || $dedication_ranking{$Common::config{faculty}{$a}{fields}{dedication}} <=> $dedication_ranking{$Common::config{faculty}{$b}{fields}{dedication}} 
							   || $Common::config{faculty}{$a}{fields}{name} cmp $Common::config{faculty}{$b}{fields}{name}
							  }
						keys %{$Common::config{faculty}} 
						)
	{
		$Common::config{faculty}{$email}{priority} = $faculty_priority++;
	}
	if( $error_count > 0)
	{	exit;	}
	#print Dumper(\%{$Common::config{faculty}{"ecuadros\@utec.edu.pe"}});
}

# ok
sub read_aditional_info_for_silabos()
{
	my $file = GetTemplate("in-additional-institution-info-file");
	Util::print_message("Reading $file ...");
	
	open(IN, "<$file") or return;
	my $codcour = "";
	my ($label, $body) = ("", "");
	while(<IN>)
	{	my ($line) = ($_);
		#Util::print_message("codcour=$codcour, label=$label");
		if(m/\s*(.*)\s*=\s*(.*)\s*/)
		{
			($label, $body) = ($1, $2);
			$body =~ s/\n//g;
			if( $label eq "COURSE" )
			{	$codcour = $body;	}
			else
			{	if($label =~ m/(OutcomesForOtherContent)(.*)/)
				{
					my ($key, $lang) = ($1, $2);
					$course_info{$codcour}{$lang}{extra_tags}{$key} = $body;
				}else
				{
					#$course_info{$codcour}{extra_tags}{$label} = "\\specialcell{$body}";
					$course_info{$codcour}{extra_tags}{$label} = $body;
					#print Dumper(\%{$course_info{$codcour}{extra_tags}});
					#print "Aditional $codcour > $label=\"$body\"\n";
				}
			}
		}
		else
		{
			if($label =~ m/(OutcomesForOtherContent)(.*)/)
			{
				my ($key, $lang) = ($1, $2);
				#Util::print_warning("course_info{$codcour}{$lang}{extra_tags}{$key}=$course_info{$codcour}{$lang}{extra_tags}{$key}");
				$course_info{$codcour}{$lang}{extra_tags}{$key} .= $line;
				#Util::print_warning("course_info{$codcour}{$lang}{extra_tags}{$key}=$course_info{$codcour}{$lang}{extra_tags}{$key}");
				#exit;
			}
		}
	}
	close IN;
	#print Dumper(\%{$course_info{CS1100}{extra_tags}});
	#print Dumper(\%{$course_info{CS103O}{extra_tags}});
	#exit;
}

# ok
sub replace_accents_in_file($)
{
	my ($filename) = (@_);
	my $fulltxt = Util::read_file($filename);
	$fulltxt = replace_accents($fulltxt);
	Util::write_file($filename, $fulltxt);
}

# sub read_outcomes_involved($$)
# {
# 	my ($codcour, $fulltxt) = (@_);
#  	if($fulltxt =~ m/\\begin\{outcomes\}\s*((?:.|\n)*?)\\end\{outcomes\}/)
# 	{
# 	    my $body = $1;
# 	    foreach my $line (split("\n", $body))
# 	    {
# 		if($line =~ m/\\ExpandOutcome(.*?)\}\{(.*?)\}/)
# 		{
# 		    $course_info{$codcour}{outcomes}{$1} = $2;
# 		}
# 	    }
# 	}
# }

# # ok
# sub preprocess_syllabus($)
# {
# 	Util::precondition("parse_courses");
# 	my ($filename) = (@_);
# # 	print "filename = $filename\n";
# 	my $codcour = "";
# 	if($filename =~ m/.*\/(.*)\.tex/)
# 	{	$codcour = $1;		}
# 	my @contents;
# 	my $line = "";
#
# 	my $fulltxt = Util::read_file($filename);
# # 	$fulltxt = replace_accents($fulltxt);
# # 	while($fulltxt =~ m/\n\n\n/)
# # 	{	$fulltxt =~ s/\n\n\n/\n\n/g;	}
#
# # 	Util::print_message("Verifying accents in: $codcour, $course_info{$codcour}{$Common::config{language_without_accents}}{course_name}");
# # 	if( not defined($course_info{$codcour}{course_type}) )
# # 	{	print "$codcour\n".Dumper(\%{$course_info{$codcour}}); exit;
# # 	}
# # 	my $codcour_label       = get_alias($codcour);
# # 	my $course_na{course_name}me = $course_info{$codcour}{$config{language_without_accents}}{course_name};
# # 	my $course_ty{course_name}pe = $Common::config{dictionary}{$course_info{$codcour}{course_type}};
# # 	my $header   {course_name}   = "\n\\course{$codcour_label. $course_name}{$course_type}{$codcour_label} % Common.pm";
# # 	my $newhead {course_name}	= "\\begin{syllabus}\n$header\n\n\\begin{justification}";
# # 	$fulltxt 	={course_name}~ s/\\begin\{syllabus\}\s*((?:.|\n)*?)\\begin\{justification\}/$newhead/g;
# 	read_outcomes_inv{course_name}olved($codcour, $fulltxt);
#{course_name}
# 	#system("rm $file{course_name}name");
# 	@contents = split{course_name}("\n", $fulltxt);
# 	my ($count,$inuni{course_name}t)  = (0, 0);
# 	my $output_txt = {course_name}"";
# 	foreach $line (@c{course_name}ontents)
# 	{{course_name}
# 		$line =~ s/\\{course_name}\s/\\/g;
# 		$output_txt .{course_name}= "$line\n";
# 		$count++;
# 	}
#         my $country_environments_to_insert = $Common::config{"country-environments-to-insert"};
#         $country_environments_to_insert =~ s/<AREA>/$Common::course_info{$codcour}{prefix}/g;
#         #$country_environments_to_insert = "hola raton abc";
#
#         my $newtext = "$country_environments_to_insert\n\n\\begin{coursebibliography}";
#         $output_txt =~ s/\\begin\{coursebibliography\}/$newtext/g;
#
# 	Util::write_file($filename, $output_txt);
#         #Util::print_message($filename); exit;
# }

# ok
# sub replace_special_characters_in_syllabi()
# {
# =====>	my $base_syllabi = GetExpandedTemplateWithLang("InSyllabiContainerDir", $lang);
#
# # 	foreach my $codcour (@codcour_list_sorted)
# =======> ? @{$config{SyllabiDirs}{$lang}} = get_list_of_dirs($lang);
# 	foreach my $localdir (@{$config{SyllabiDirs}{$lang}})
# 	{
# 		my $dir = "$base_syllabi/$localdir";
# 		my @filelist = ();
# 		if( -d $dir )
# 		{	opendir DIR, $dir;
# 			@filelist = readdir DIR;
# 			closedir DIR;
# 		}
# 		else
# 		{
# 			Util::print_error("I can not open directory: $dir ...");
# 		}
# 		foreach my $texfile (@filelist)
# 		{
# 			if($texfile=~ m/(.*)\.tex$/)
# 			{
# # 				my $codcour = $1;
# # 				if(defined($course_info{$codcour}))
# # 				{
#  					preprocess_syllabus("$dir/$texfile");
# # 					generate_prerequisitos($texfile);
# # 				}
# 			}
# 			elsif($texfile=~ m/(.*)\.bib$/)
# 			{
# 				replace_accents_in_file("$dir/$texfile");
# 			}
# 		}
# 	}
# }

sub replace_acronyms($)
{
	my ($label) = (@_);
	foreach my $acro (keys %{$config{dictionary}{Acronyms}})
	{
		$label =~ s/$config{dictionary}{Acronyms}{$acro}/$acro/g;
	}
	return $label;
}

# ok
sub wrap_label($)
{
	my ($label) = (@_);
	$label = replace_acronyms($label);
	$label =~ s/  / /g;
	my @words 		= split(" ", $label);
	my $output 		= "";
	my $acu_length 	= 0;
	my $nwords     	= 0;
	my $sep 		= "";
	my $nlines 		= 1;
	foreach my $word (@words)
	{
		if($acu_length+length($word)+1 > $config{label_size} and $nwords >0)
		{
			$output    .= "\\n";
			$acu_length = 0;
			$nwords 	= 0;
			$nlines++;
			$sep 		= "";
		}
		$nwords++;
		$output     .= "$sep$word";
		$acu_length += length($word)+length($sep);
		$sep 		 = " ";
	}
	return ($output,$nlines);
}

sub replace_tags_from_hash($$$%)
{
 	my ($txt, $before, $after, %map) = (@_);
	my $count = 1;

	if(not defined($txt)){
		return undef
	}

	#Util::print_color("replace_tags_from_hash ...");
	#print Dumper(\%map);
	foreach my $key (keys %map)
	{
		$txt =~ s/$before$key$after/$map{$key}/g;
	}
	#while($txt =~ m/$before(.*?)$after/g)
	#{
	#	my ($tag) = ($1);
# 	#	print "tag=$tag\n";
	#	if(defined($map{$tag}))
	#	{
	#	      $txt =~ s/$before$tag$after/$map{$tag}/g;
	#		  Util::print_message("Replacing $before$tag$after by $map{$tag}");
	#	      if($map{$tag} =~ m/$before$tag$after/g)
	#	      {
	#		    Util::print_error("Recursive tag ! $map{$tag} contains \"$before$tag$after\"");
	#	      }
	#	      #Util::print_warning("($count) $before$tag$after => $map{$tag}");
	#	      $count++;
	#	}
	#	else
	#	{
	#	}
	#}
	return $txt;
}

sub translate($$)
{
	my ($txt, $lang) = (@_);
	$txt = Common::replace_tags_from_hash($txt, "<<", ">>", %{$Common::config{dictionaries}{$lang}});
	return $txt;
}

# ok
sub count_number_of_tags($)
{
	my ($course_line) = (@_);
	my $count = 0;
	while($course_line =~ m/<(.*?)>/g)
	{
		$count++;
	}
	return $count;
}

# ok
sub find_credit_column($)
{
	my ($course_line) = (@_);
	my $count = 1;
	while($course_line =~ m/<<(.*?)>>/g)
	{
		my $tag = $1;
 		#Util::print_message("tag=$tag");
		if($tag eq "CR")
		{
#			Util::print_message("count=$count"); exit;
			return $count;
		}
		$count++;
	}
	#Util::print_message("$course_line"); exit;
	return 1;
}

# ok
sub read_bok_order()
{
	my $file = GetTemplate("in-macros-order-file");
	my $txt  = Util::read_file($file);

	my $count = 0;
	foreach my $line (split("\n", $txt))
	{
		if($line =~ m/(([a-z]|[A-Z])*)/)
		{
			$config{topics_priority}{$1} = $count++;
 		}
	}
	Util::print_message("TODO Common read_bok_order: $count topics read ...");
	exit;
}

# my $sql_topic  = "<prefix>INSERT INTO curricula_knowledgetopic(id, \"name\", unit_id, \"topicParent_id\")\n";
#    $sql_topic .= "<prefix>\t\tVALUES (<ctopic>, \'<body>\', <cunit>, <parent>);\n";
#
# sub gen_bok_normal_topic($$$$$)
# {
# 	my ($ctopic, $body, $cunit, $prefix, $parent) = (@_);
# 	while($body =~ m/  /)
# 	{	$body =~ s/  / /g;	}
# 	my $secret = "xyz1y2b3ytr";
# 	$body .= $secret;
#
# # 	print "0:\"$body\"\n"	if($body =~ m/pigeonhole/);
# 	if($body =~ m/(.*) $secret/) #delete spaces at the end
# 	{	$body = "$1$secret";	}
# # 	print "s:\"$body\"\n"	if($body =~ m/pigeonhole/);
#
# 	if($body =~ m/(.*)\.$secret/) #delete the point
# 	{	$body = "$1";		}
# # 	print "p:\"$body\"\n"	if($body =~ m/pigeonhole/);
#
# 	$body =~ s/$secret//g;
# # 	print "f:\"$body\"\n"	if($body =~ m/pigeonhole/);
#
# 	$ctopic++;
# 	my $this_sql = $sql_topic;
# 	$this_sql =~ s/<prefix>/$prefix/g;
# 	$this_sql =~ s/<ctopic>/$ctopic/g;
# 	$this_sql =~ s/<body>/$body/g;
# 	$this_sql =~ s/<cunit>/$cunit/g;
# 	$this_sql =~ s/<parent>/$parent/g;
# 	return ($this_sql, $ctopic);
# }
#
# sub gen_bok_subtopic($$$$$)
# {
# 	my ($ctopic, $body, $cunit, $prefix, $parent) = (@_);
# 	my $this_sql = "";
# 	my $sub_body = "";
#
# 	my @lines = split("\n", $body);
# 	foreach my $line (@lines)
# 	{
# 		if( $line =~ m/\\item\s+(.*?)\.\s*%/)
# 		{
# 			my $sql_tmp = "";
# 			($sql_tmp, $ctopic) = gen_bok_normal_topic($ctopic, $1, $cunit, "$prefix   ", $parent);
# 			$this_sql              .= $sql_tmp;
# 		}
# 	}
# 	return ($this_sql, $ctopic);
# }
#
# sub gen_bok_topic($$$$)
# {
# 	my ($ctopic, $body, $cunit, $prefix) = (@_);
# 	my ($sql, $this_sql) = ("", "");
# 	my $sub_body = "";
# 	if($body =~ m/\s*((?:.|\n)*?)\s*\\begin{inparaenum}\[.*?\]\s*((?:.|\n)*?)\s*\\end{inparaenum}/)
# 	{
# 		$body     = $1;
# 		$sub_body = $2;
#
# # 		print "\"$body\"\n";
# # 		print "\"$sub_body\"";  exit;
# 		($this_sql, $ctopic) = gen_bok_normal_topic($ctopic, $body, $cunit, $prefix, "null");
# 		$sql .= $this_sql;
# 		($this_sql, $ctopic) = gen_bok_subtopic($ctopic, $sub_body, $cunit, "$prefix   ", $ctopic);
# 		$sql .= $this_sql;
# 	}
# 	else
# 	{
# 		($this_sql, $ctopic) = gen_bok_normal_topic($ctopic, $body, $cunit, $prefix, "null");
# 		$sql .= $this_sql;
# 	}
# 	return ($sql, $ctopic);
# }
#
# sub generate_bok_sql($$)
# {
# 	my ($filename, $outfile) = (@_);
# 	my $txt_file = Util::read_file($filename);
# # 	print $txt_file;exit;
# 	my $sql = "";
#
# 	# Config
# 	my $bok_id = 1; #CS=1
# 	my ($carea, $cunit, $ctopic) = (0, 0, 0);
# 	# End config
# 	# Generate areas
# 	my $this_sql = "";
# 	foreach my $area (sort {$areas_priority{$a} <=> $areas_priority{$b}} keys %areas_priority)
# 	{
# 		$carea++;
# 		$this_sql = "INSERT INTO curricula_knowledgearea(id, \"name\", acronym, bok_id)\n";
# 		$this_sql.= "                            VALUES (<id>, \'<name>\', \'<acro>\', <bok_id>);\n";
# 		$this_sql =~ s/<id>/$carea/g;		$this_sql =~ s/<name>/$CS_Areas_description{$area}/g;
# 		$this_sql =~ s/<acro>/$area/g;		$this_sql =~ s/<bok_id>/$bok_id/g;
# 		$sql .= $this_sql;
#
# 	}
# 	$sql .= "\n";
#
# # 	print($sql);
# 	$carea = 0;
# 	my $curr_area = "";
# 	while($txt_file =~ m/\\newcommand{(.*?)}{/g)
# 	{
# 		my $command = $1;
# 		my $body = "";
# 		my $cPar = 1;
# 		while($cPar > 0)
# 		{
# 			$txt_file =~ m/((.|\s))/g;
# 			$cPar++ if($1 eq "{");
# 			$cPar-- if($1 eq "}");
# 			$body .= $1 if($cPar > 0);
# # 			{
# # 				if( $1 eq "\n" )
# # 				{	$body .= "\\n";		}
# # 				else{			}
# # 			}
# 		}
# # 		foreach (split("\n", $body))
# # 		{	print "\"$_\"\n";		}
# # # 		print "\"$body\"";
# # 		exit;
#
# # 		$body =~ s/\. }//g;
# # 		$body =~ s/\.}//g;
# # 		if( $body =~ m/(.*)\.(\s+)/)
# # 		{	$body = $1;		}
# 		my $subarea = "";
# 		if(	$command =~ m/\\(..).+Topic.+/)
# 		{
# 			$subarea = $1;
# 			#Flush existing header text
# 			if($this_sql =~ m/<nhoras>/)
# 			{
# 				$this_sql =~ s/<nhoras>/0/g;
# 				$sql     .= $this_sql;
# 				$this_sql = "";
# 			}
#
# 			#Process this topic
# # 			$this_sql = "   INSERT INTO curricula_knowledgetopic(id, \"name\", unit_id, \"topicParent_id\")\n";
# # 			$this_sql.= "\t\t\tVALUES ($ctopic, \"$body\", $cunit, null);\n";
# 			($this_sql, $ctopic) = gen_bok_topic($ctopic, $body, $cunit, "   ");
# 			$sql      .= $this_sql;
# 		}elsif(	$command =~ m/\\(..).*Hours/)
# 		{
# 			$this_sql =~ s/<nhoras>/$body/g;
# 			$sql     .= $this_sql;
# 			$this_sql = "";
# # 			print "H=$this_sql";exit;
# 		}elsif($command =~ m/\\(..).+Def/ )
# 		{
# 			$subarea = $1;
# 			$this_sql = "";
# 			if(not $subarea eq $curr_area)
# 			{	$carea++;
# 				$curr_area = $subarea;
# 				$this_sql  = "\n";
# # 				print "current_area=$curr_area\n";
# 			}
# 			$cunit++;
# 			$this_sql .= "\n-- $body --\n";
# 			$this_sql .= "INSERT INTO curricula_knowledgeunit(id, \"name\", area_id, hours)\n";
# 			$this_sql .= "\tVALUES ($cunit, \'$body\', $carea, <nhoras>);\n";
# # 			$sql      .= $this_sql;
#
# 		}
# 	}
# 	Util::write_file($outfile, $sql);
# }

# ok
sub remove_only_env($)
{
	my ($text_in) = (@_);
	while($text_in =~ m/\\Only([A-Z]*?)\{/g)
	{
		my $type      = $1;
		my $count = 1;
		my $body1  = "";
		while($count > 0 and $text_in =~ m/(.|\n)/g)
		{
			my $this_char = $1;
			++$count if( $this_char eq "{" );
			--$count if( $this_char eq "}" );
			$body1 .= $this_char if($count > 0 );
		}
		#print "*********************************\n";
		#print "body=<$body>\n";
		#print "*********************************\n";
        my $firstchars = $body1 =~ m/(.....)/g;
		my $body2 = replace_special_chars($body1);
		if( $type eq $config{institution} )
		{
			$text_in =~ s/\\Only$config{institution}\{$body2\}/$body1/g;
			print "\t\ttype =  \"$type\" \n";
            #print "\t\ttype =  \"$type\" processed\n\\Only$config{institution}\{$body2\}\n=>$body1\n";
		}
		else
		{
			$text_in =~ s/\\Only$type\{$body2\}//g;
			#print "\t\ttype =  \"$type\" (X)\n;
		}
	}
	return $text_in;
}

sub remove_only_and_not_env($$)
{
	my ($sub_filename, $_text_in) = (@_);
    foreach my $word ("Not", "Only")
    {
		my ($text_in) = ($_text_in);
        while( $text_in =~ m/\\$word([A-Z|a-z]*?)\{/g )
        {
            my $environment  = $1;
            my $count = 1;
			#print("\t\t\\$word$environment\{ ".Util::green("found !")."\n" );
            my $body1  = "";
            while($count > 0 and $text_in =~ m/(.|\n)/g)
            {
                my $this_char = $1;
                ++$count if( $this_char eq "{" );
                --$count if( $this_char eq "}" );
                $body1 .= $this_char if($count > 0 );
            }
            #print "*********************************\n";
            #print "body=<$body>\n";
            #print "*********************************\n";
            my $firstchars = substr($body1, 1, 50);
            my $body2 = replace_special_chars($body1);
            #Util::print_message("$word eq \"Not\" && not $inst eq $config{institution} || $word eq \"Only\" && $inst eq $config{institution}");
            my $snipped = "\\$word$environment\{$firstchars";
			if(    ($word eq "Not"  && not $environment eq "$config{country_without_accents}$config{institution}") 
			    || ($word eq "Only" &&     $environment eq "$config{country_without_accents}$config{institution}") 
				|| ($word eq "Not"  && not $environment eq "$config{area}")
				|| ($word eq "Only" &&     $environment eq "$config{area}")
			  )
            {	printf("\t\t%s %-035s (Kept)\n", "$Util::icons{ok}", Util::green($snipped));
                $text_in =~ s/\\$word$environment\{$body2\}/$body1/g;
            }
            else
            {
                printf("\t\t%s %-035s (Ignored)\n", "*", $snipped);
                $text_in =~ s/\\$word$environment\{$body2\}//g;
            }
            if( $firstchars eq "Test Test ")
            {   Util::print_message("$body2"); }
        }
		$_text_in = $text_in;
    }
	return $_text_in;
}

# sub replace_Pag_pagerefs($)
# {
# 	my ($text) = (@_);
# 	my $count  = 0;
# 	$text =~ s/\($Common::config{dictionary}{Pag}\.~\\pageref{.*?}\)//g;
# 	return ($text, $count);
# }
#
# sub replace_bok_pagerefs($)
# {
# 	my ($text) = (@_);
# 	my $count  = 0;
# 	if($text =~ m/\\item\s(.*?)\s\($Common::config{dictionary}{Pag}\.\s\\pageref{(.*?)}\)/g)
# 	{
# 		#my ($label1) = ($1);
# 		#print "label=\"$label1\" ... ";
# 		my ($title1, $label1) = ($1, $2);
# 		#print "title=\"$title1\"->\"$label1\"\n";
# 		my $title2 = replace_special_chars($title1);
# 		my $label2 = replace_special_chars($label1);
# 		$text =~ s/\\item\s$title2\s\($Common::config{dictionary}{Pag}\.\s\\pageref{$label2}\)/\\item \\htmlref{$title1}{$label1}/g;
# 		$count++;
# 	}
# 	return ($text, $count);
# }
#
# sub readfile($$)
# {
# 	my ($filename, $area) = (@_);
# 	my $line;
#
# 	if(not -e "$filename")
# 	{
# 		print "readfile: \"$filename\" no existe\n";
# 		return "";
# 	}
# 	open(IN, "<$filename") or die "readfile: $filename no abre \n";
# 	my @lines = <IN>;
# 	close(IN);
# 	my $changes;
# 	my $count = 0;
# 	foreach $line (@lines)
# 	{
# 		my $extratxt = "";
# 		if( $lines[$count] =~ m/^%/)
# 		{	$lines[$count] = "\n"; }
# 		elsif($filename eq "cs-bok-body.tex")
# 		{	($lines[$count], $changes)        = replace_bok_pagerefs($line);
# 		}
# 		elsif($filename eq "cs-tabla.tex" or $filename =~ m/pre\-prerequisites/)
# 		{
# 			($lines[$count], $changes)        = replace_Pag_pagerefs($line);
# 		}
# 		elsif( $lines[$count] =~ m/(^.*)(.)%(.*)/)
# 		{	if($2 eq "\\")
# 			{}
# 			else
# 			{
# 				$lines[$count] = "$1$2\n" ;
# 				#print "$line";
# 			}
# 		}
# 		$count++;
# 	}
# 	my $filetxt = join("", @lines);
# 	$filetxt =~ s/\\setmyfancyheader\s*\n//g;
# 	$filetxt =~ s/\\setmyfancyfoot\s*\n//g;
# 	$filetxt =~ s/\\hrulefill\s*//g;
# 	$filetxt =~ s/\\newcommand{\\siglas}{\\currentinstitution}//g;
# 	$filetxt =~ s/\\renewcommand{\\Only.*\n//g;
# 	$filetxt =~ s/\\renewcommand{\\OtherKeyStones/\\newcommand{\\OtherKeyStones/g;
# 	$filetxt =~ s/\\include{empty}//g;
# 	$filetxt =~ s/\\input{caratula}/\\input{caratula-web}/g;
# 	$filetxt =~ s/\\newcommand{\\currentarea}{.*?}//g;
# 	$filetxt =~ s/\\currentarea/$area/g;
# 	#$filetxt =~ s/\\begin{landscape}//g;
# 	#$filetxt =~ s/\\end{landscape}//g;
# 	$filetxt =~ s/cs-topics-by-course/cs-all-topics-by-course/g;
# 	$filetxt =~ s/cs-outcomes-by-course/cs-all-outcomes-by-course/g;
# 	return $filetxt;
# }

sub clean_file($)
{
	my ($filetxt) = (@_);
	$filetxt .= "\n";
	$filetxt =~ s/\\%/\\PORCENTAGE/g;
	$filetxt =~ s/%.*?\n/\n/g;
	$filetxt =~ s/\\PORCENTAGE/\\%/g;

	$filetxt =~ s/\\setmyfancyheader\s*\n//g;
	$filetxt =~ s/\\setmyfancyfoot\s*\n//g;
	$filetxt =~ s/\\hrulefill\s*//g;
	$filetxt =~ s/\\newcommand\{\\siglas\}\{\\currentinstitution\}//g;
	$filetxt =~ s/\\newcommand\{\\Only.*\n//g;
    $filetxt =~ s/\\newcommand\{\\Not.*\n//g;
# 	$filetxt =~ s/\\renewcommand{\\OtherKeyStones/\\newcommand{\\OtherKeyStones/g;
	$filetxt =~ s/\\include\{empty\}//g;
	$filetxt =~ s/\\input\{caratula\}/\\input\{caratula-web\}/g;
	$filetxt =~ s/\\newcommand\{\\currentarea\}\{.*?\}//g;
	$filetxt =~ s/\\currentarea/$config{area}/g;
	$filetxt =~ s/\\newcommand\{\\OutcomesVersion\}\[.*\]\{.*\}//g;

	$filetxt =~ s/\\begin\{comment\}\s*(?:.|\n)*?\\end\{comment\}//g;
	#while($filetxt =~ m/\\begin{unit}\s*\n((?:.|\n)*?)\\end{unit}/g)
	#$filetxt =~ s/\\begin{landscape}//g;
	#$filetxt =~ s/\\end{landscape}//g;
# 	$filetxt =~ s/cs-topics-by-course/cs-all-topics-by-course/g;
# 	$filetxt =~ s/cs-outcomes-by-course/cs-all-outcomes-by-course/g;
	return $filetxt;
}

# ok
sub expand_macros($$)
{
	my ($file, $text) = (@_);
	my $macros_changed = 0;
	Util::precondition("sort_macros");

	if(not defined($config{macros}{siglas}))
	{	Util::halt("\$config{macros}{siglas} does not exit !!!!\n");		}
	my $changes = "";
	my $ctemp = 1;
	while($ctemp > 0)
	{	$ctemp = 0;
		foreach my $key (sort {length($b) <=> length($a)} keys %{$config{macros}})
		{	# $text     =~ s/\\$key/$config{macros}{$key}/g;
			if($text =~ m/\\$key/)
			{	$text     =~ s/\\$key/$config{macros}{$key}/g;
				$changes .= "\\$key:$config{macros}{$key}\n";
				$macros_changed++;
				$ctemp++;
			}
		}
	}
	return ($text, $macros_changed);
}

# ok
sub expand($$$)
{
	my ($text, $macro, $key) = (@_);
	my $count = 0;

	$text =~ s/\\Show$macro\{(.*?)}/$1) $config{$key}{$1}/g;
	#print "siglas = $config{macros}{siglas} ... x7\n";
	return ($text, $count);
}

#
sub expand_sub_file($$)
{
	my ($text, $IncludeType) = (@_);
	my $count = 0;
    print "Expanding sub files 1\n";
    $text  = remove_only_and_not_env("", $text);
#     print "Expanding sub files 2\n";
#     $text  = remove_not_env($text);
#     print "Expanding sub files 3\n";

	#while($filetxt =~ m/\\begin{unit}{(.*)}{(.*)}\s*\n((?:.|\n)*?)\\end{unit}/g)
	my $prefix = "";
	#my $source_txt = "";
	while($text =~ m/\\$IncludeType\{(.*?)\}/)
	{
		my $sub_filename = $1;
		#Util::print_message("Replacing \\$IncludeType\{$sub_filename\}");
# 		my $source_txt = "\\\\$IncludeType"."{$sub_filename}";
		if($IncludeType eq "\\include")
		{	$prefix = "\\\\newpage\n";	}

		my $JustName = $sub_filename;
		$sub_filename .= ".tex";
		my $JustNameWithSpecialCharactersReplaced = replace_special_chars($JustName);
		if( $JustName =~ m/.*\/(.*)/ )
		{	$JustName = $1;		}

		if(defined($config{change_file}{$JustName}))
		{
			$sub_filename =~ s/$JustName/$config{change_file}{$JustName}/g;
			Util::print_color("Replacing $JustName => $config{change_file}{$JustName} in $sub_filename");
		}
		#print "Reading $sub_filename ...";
		if( defined($config{except_file}{"$JustName.tex"}) )
		{	print " $sub_filename (X): \\$IncludeType\{$JustName\}\n";
			$text =~ s/\\$IncludeType\{$JustNameWithSpecialCharactersReplaced\}//g;
			next;
		}
		if(not -e $sub_filename)
		{       Util::print_error("File \"$sub_filename\" does not exists ...");    }
		my $sub_filename_text = clean_file(Util::read_file($sub_filename));
		   $sub_filename_text = remove_only_and_not_env($sub_filename, $sub_filename_text);
#            $sub_filename_text = remove_not_env($sub_filename_text);
		my $macros_changed = 0;
		#print "$config{institution}: $sub_filename ";
		($sub_filename_text, $macros_changed) = expand_macros($sub_filename, $sub_filename_text);
		$count += $macros_changed;
		#print " ($macros_changed macros changed)\n" if($macros_changed > 0);
		#print "\n";
		$text =~ s/\\$IncludeType\{$JustNameWithSpecialCharactersReplaced\}/$prefix$sub_filename_text/g;
		$count++;
	}
	return ($text, $count);
}

# ok
sub expand_sub_files($)
{
	my ($text) = (@_);
	my ($count1, $count2) = (0, 0);
	($text, $count1) = expand_sub_file($text, "input");
	($text, $count2) = expand_sub_file($text, "include");
	return ($text, $count1+$count2);
}

sub parse_courses()
{
	Util::precondition("set_initial_configuration");
	my $input_file    = GetTemplate("list-of-courses");
	Util::print_message("Reading courses (".Util::highlight_filename($input_file).") ...");

 	my $file_txt = Util::read_file($input_file);
	my $flag 				= 0;
	my $active_semester 	= 0;
	my $courses_count 		= 0;
	$config{n_semesters}	= 0;
	$file_txt =~ s/\r/\n/g;
	foreach my $onecourse (split("\n", $file_txt))
	{
		if($onecourse =~ m/\\course(.*)/)
		{
			my ($course_line) = ($1);
			$course_line =~ s/\n//g; $course_line =~ s/\r//g;
			#                       {sem}{course_type}{area_country}{area_pie}{dpto}{cod}{alias}{name} {cr}{th}  {ph}  {lh} {ti}{Tot} {labtype}  {req} {rec} {corq}{grp} {axe} %filter
			if($course_line =~ m/\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}%(.*)/g)
			{
				# Util::print_color("\\course$course_line");
				my ($semester, $course_type, $area, $area_pie, $department)     = ($1, $2, $3, $4, $5);
				my ($codcour, $codcour_alias, $course_name_es, $course_name_en) = ($6, $7, $8, $9);
				my ($credits, $ht, $hp, $hl, $ti, $tot, $labtype)   		    = ($10, $11, $12, $13, $14, $15, $16);
				my ($prerequisites, $invis, $recommended, $coreq) 				= ($17, $18, $19, $20);
				my ($group, $track)												= ($21, $22);
				my ($axes, $inst_wildcard)			      		               	= ($23, $24);
				my $coursefile = $codcour;
				$inst_wildcard =~ s/\n//g; 	$inst_wildcard =~ s/\r//g;
	# 		  	Util::print_message("$axes");
	# 		  	Util::print_message("Labtype: $labtype");
	# 		  	Util::print_message("Wilcard: $inst_wildcard ");

				my @inst_array			= split(",", $inst_wildcard);
				my $count				= 0;
				my $priority 			= 0;
				if( $active_semester != $semester )
				{
					$active_semester = $semester;
					print "\n";
					Util::print_color("$semester: ");
				}
				foreach my $inst (@inst_array)
				{
					if( defined($config{valid_institutions}{$inst}) )
					{
						$count++;
						if($config{filter_priority}{$inst} > $priority)
						{		$priority = $config{filter_priority}{$inst};		}
						#Util::print_message("$inst matches ...");
					}
					#else{	#Util::print_message("$inst does not match ...");	}
				}
				if( $count == 0 )
				{	#Util::print_message(Util::red("$codcour ignored $inst_wildcard"));
					my $country	= $config{country_without_accents};
					my $filter  = $inst_list{$country}{$config{institution}}{$config{area}}{filter};
					#Util::print_message("$Util::icons{X} Ignoring \\course$course_line");
					next;
				}
				my $output_text = "$Util::icons{check} Processing \\course$course_line";
				foreach my $inst (@inst_array)
				{	if( defined($config{valid_institutions}{$inst}) )
					{	$output_text = Util::highlight($output_text, $inst, \&Util::yellow);	}
				}
				Util::print_message($output_text);
				if($codcour_alias eq "")
				{	$codcour_alias = $codcour; 	}
				else
				{   my $prev_codcour = $codcour;                     # A -> xyz
					$codcour = $codcour_alias;                       # $codcour = "xyz"
					$antialias_info{$prev_codcour} = $codcour_alias; # $antialias_info{xyz} = "A";
				}
				$Common::course_info{$codcour}{pathId} = -1;
		# 		  if( $flag == 1 )	{	Util::print_warning("codcour = $codcour");
		#  						print Dumper(\%{$course_info{$codcour}});	exit;
		# 					}
		# 		  my $codcour_alias = get_alias($codcour);
				if( $course_info{$codcour} ) # This course already exist, then verify if the new course has a higher priority
				{
					# 
					if( defined($course_info{$codcour}{priority}) )
					{	# Util::print_message("course_info{$codcour}{priority} = $course_info{$codcour}{priority}, priority = $priority");
						if( $priority < $course_info{$codcour}{priority} )
						{
							print "\n";
							Util::print_warning("Course $codcour (Sem #$course_info{$codcour}{semester},\"$course_info{$codcour}{inst_list}\"), ".
												"has higher priority than ".
														"$codcour (Sem #$semester, \"$inst_wildcard\")  ... ignoring the last one !!!");
							exit;
						}
					}
					else
					{
						#$course_info{$codcour}{priority}	= $priority;
					}
				}
				$config{n_semesters} = $semester if($semester > $config{n_semesters});
				$course_info{$codcour}{coursefile}	= $coursefile;
				$course_info{$codcour}{common_file} = "";
				if($axes eq "")
				{
					Util::halt("Course $codcour: $course_name_es (Sem: $semester) has not area defined, see dependencies");
				}
				$courses_count++;

				#print "wildcards = $inst_wildcard\n";
				#Util::print_message("coursecode = $codcour, semester = $semester\n");
				$prerequisites =~ s/ //g;
				$invis         =~ s/ //g;
				$recommended   =~ s/ //g;
				$coreq	       =~ s/ //g;

				$course_info{$codcour}{priority}	= $priority;
				$course_info{$codcour}{semester}    = $semester;
				$course_info{$codcour}{course_type} = $course_type; # $config{dictionary}{$course_type};
				$course_info{$codcour}{short_type}  = $config{dictionary}{MandatoryShort};
				$course_info{$codcour}{short_type}	= $config{dictionary}{ElectiveShort} if($course_info{$codcour}{course_type} eq $Common::config{dictionary}{Elective});
				$course_info{$codcour}{alias}		= $codcour_alias;
				$course_info{$codcour}{axes}        = $axes;
				$course_info{$codcour}{naxes}		= 0;
				my $prefix 							= get_course_prefix($codcour);
				$course_info{$codcour}{prefix}		= $prefix;
				$course_info{$codcour}{LearningModality}= "";

				if( not defined($config{SpiderChartAxesItems}{$prefix}) )
				{	$config{SpiderChartAxesItems}{$prefix} = ++$config{PrefixPriorityCount};
					my $config_file = GetTemplate("in-area-all-config-file");
					my $ErrorMsg = "There is no priority defined for ".Util::red($prefix)." See: ".Util::red($config_file);
					push(@{$Common::error{general}}, $ErrorMsg);
				}
		# 		print "coursecode= $codcour, area= $course_info{$codcour}{axe}\n";
		# 		$area_priority{$codcour}		= $axes;
				if( defined($config{colors}{$prefix}{bgcolor}) )
				{	$course_info{$codcour}{textcolor}	= $config{colors}{$prefix}{textcolor};
					$course_info{$codcour}{bgcolor}		= $config{colors}{$prefix}{bgcolor};
				}
				else
				{	print("Color is not configured for ".Util::red($codcour)." ... Verify files: ".Util::red(Common::GetTemplate("colors")));
					my $whichdoesnotexists = "";
					my $InstitutionColorsFile = Common::GetTemplate("institution-colors");
					if( -e $InstitutionColorsFile )
					{	Util::print_message(" and ".Util::red($InstitutionColorsFile)." ...");	}
					else
					{	Util::print_message(" OR ".Util::green("create: $InstitutionColorsFile ..."));	}
					$course_info{$codcour}{textcolor}	= "black";
					$course_info{$codcour}{bgcolor}		= "white";
					# exit;
				}
				$course_info{$codcour}{Espanol}{course_name} = $course_name_es;
				$course_info{$codcour}{English}{course_name} = $course_name_en;
				$course_info{$codcour}{area}				 = $area;
				$course_info{$codcour}{area_pie}			 = $area_pie;
				$course_info{$codcour}{department}			 = $department;
				$course_info{$codcour}{cr}             		 = $credits;

				($course_info{$codcour}{th}, $course_info{$codcour}{ph})   = (0, 0);
				($course_info{$codcour}{lh}, $course_info{$codcour}{phEx}) = (0, 0);
				$course_info{$codcour}{th}             		 = int($ht) if( looks_like_number($ht) );
				$course_info{$codcour}{ph}             		 = int($hp) if( looks_like_number($hp) );
				$course_info{$codcour}{lh}             		 = int($hl) if( looks_like_number($hl) );
				$course_info{$codcour}{phEx}				 = $course_info{$codcour}{ph} + $course_info{$codcour}{lh};

				($course_info{$codcour}{ti}, $course_info{$codcour}{tot})            = (0, 0);
				$course_info{$codcour}{ti}                  = $ti  if(not $ti eq "");
				$course_info{$codcour}{tot}                 = $tot if(not $tot eq "");

				$course_info{$codcour}{labtype}             = $labtype;
				$course_info{$codcour}{prerequisites}		= "";
				%{$course_info{$codcour}{prereq_to_hide}} 	= ();
				%{$course_info{$codcour}{prereq_invis}} 	= ();
				my $sep = "";
				foreach my $prereq (split(",", $prerequisites)) 
				{
					if( $prereq =~ m/(.*)\(H\)/g )
					{	$course_info{$codcour}{prereq_to_hide}{$1} = "";	}
				}
				foreach my $prereq_invis (split(",", $invis)) 
				{	$course_info{$codcour}{prereq_invis}{$prereq_invis} = "";
				}
				($course_info{$codcour}{prerequisites} = $prerequisites) =~ s/\(H\)//g;
				foreach my $lang ( @{$config{SyllabusLangsList}} )
				{
					$course_info{$codcour}{$lang}{full_prerequisites} = []; # # CS101F. Name1 (1st Sem, $Common::config{dictionary}{Pag} 56), CS101O. Name2 (2nd Sem, Pag 87), ...
					$course_info{$codcour}{$lang}{code_name_and_sem_prerequisites} = [];
				}
				$course_info{$codcour}{code_and_sem_prerequisites}	= "";

				$course_info{$codcour}{prerequisites_just_codes} = "";
				$course_info{$codcour}{prerequisites_for_this_course}	= [];
				$course_info{$codcour}{courses_after_this_course} 	= [];
				$course_info{$codcour}{short_prerequisites}	= ""; # CS101F (1st Sem), CS101O (2nd Sem), ...
	 		  	# Util::print_warning("codcour=$codcour, $recommended");
				$course_info{$codcour}{recommended}   		= "";
				if( not $recommended eq "" )
				{	$course_info{$codcour}{recommended}   		= unmask_codcour($recommended);	}
		# 		  Util::print_warning("course_info{$codcour}{recommended}=$course_info{$codcour}{recommended}"); exit;
				$course_info{$codcour}{corequisites}		= "";
				if( not $coreq eq "" )
				{	$course_info{$codcour}{corequisites}		= unmask_codcour($coreq);		}
				$course_info{$codcour}{group}          		= $group;
				$course_info{$codcour}{track}          		= $track;

				$course_info{$codcour}{inst_list}      		= $inst_wildcard;
				$course_info{$codcour}{equivalence}			= "";
				$course_info{$codcour}{specific_evaluation}	= "";

				if($codcour_alias eq $codcour)
				{	#Util::print_message("* $codcour $course_info{$codcour}{Espanol}{course_name} (prereq: $course_info{$codcour}{prerequisites})");	
				}
				else
				{	print "$codcour_alias($codcour) ";	}
				push(@codcour_list_sorted, $codcour);
			}
			else
			{	Util::print_message("$Util::icons{X} ".Util::red("# of parameters is wrong.")." course: \"\\course$course_line\" ");
			}
			#$flag = 0;
		}
	}
# 	close(IN);
	if(not defined($config{SemMin}) and not defined($config{SemMax}) )
	{
	    $config{SemMin} = 1;
	    $config{SemMax} = $config{n_semesters};
	}
	else
	{
	    #if( $config{SemMax} > $config{n_semesters} )
	    #{	$config{SemMax} = $config{n_semesters};		}
	}
	Util::print_message("config{SemMin} = $config{SemMin}, config{SemMax} = $config{SemMax}");
	Util::check_point("parse_courses");
	Util::print_message("Read courses = $courses_count ($config{n_semesters} semesters)");
	my $file = Common::GetTemplate("out-nsemesters-file");
    Util::write_file($file, "$config{n_semesters}\\xspace");
}

# ok
sub filter_courses($)
{
    my ($lang) = (@_);
	Util::precondition("set_initial_configuration");
	Util::precondition("parse_courses");
	Util::precondition("sort_courses");
	my $input_file    = GetTemplate("list-of-courses");
	Util::print_message("Filtering courses ...");

	$counts{credits}{count} 	= 0;
	$counts{hours}{count} 		= 0;
	%{$config{used_prefix}}		= ();	$config{number_of_used_prefix}	 = 0;
	%{$config{used_area_pie}}	= ();	$config{number_of_used_area_pie} = 0;

	my $courses_count 			= 0;
	my $active_semester 		= 0;
	my $maxE 					= 0;
	my ($elective_axes, $elective_naxes) = ("", 0);
	my $axe 					= "";
	$config{n_semesters}		= 0;
	foreach my $codcour (@codcour_list_sorted)
	{
		my $coursefile = $course_info{$codcour}{coursefile};
		#Util::print_message("config{map_file_to_course}{$coursefile} = $codcour;");
		$config{map_file_to_course}{$coursefile} = $codcour;
	}

	#print Dumper(\@codcour_list_sorted); Util::print_message("Qui stop"); exit;
	foreach my $codcour (@codcour_list_sorted)
	{
		#Util::print_message("codcour()=$codcour");
		if( not defined($course_info{$codcour}{semester}) )
		{
		      print Dumper (\%{$course_info{$codcour}});
		      Util::print_error("codcour=$codcour, semester not defined");
		}
		my $semester = $course_info{$codcour}{semester};

		$config{n_semesters} = $semester if($semester > $config{n_semesters});
		$courses_count++;
		#print "wildcards = $inst_wildcard\n";
		#Util::print_message("coursecode = $codcour, semester = $semester\n");
		#Util::print_message("$codcour($semester),");
		if($active_semester != $semester)
		{
			#print "Active Semester = $active_semester\n";
			if($active_semester != 0)
			{
				foreach $axe (split(",", $elective_axes))
				{	$counts{credits}{areas}{$axe}	+= $maxE/$elective_naxes;	}
				$counts{credits}{count}			+= $maxE;
				#print "contador hasta el $active_semester = $counts{credits}{count}, maxE = $maxE\n";
			}
			$active_semester = $semester;
			$maxE = 0;
		}

		#print_message("Processing coursecode=$codcour ...");
		my $prefix = get_course_prefix($codcour);
		if(not defined($config{used_prefix}{$prefix})) 
		{
			$config{used_prefix}{$prefix} = "";
			$config{number_of_used_prefix}++;
		}
		my $area_pie = $course_info{$codcour}{area_pie};
		if(length($area_pie) > 0 and not defined($config{used_area_pie}{$area_pie}))   # YES HERE
		{
			$config{used_area_pie}{$area_pie} = "";
			$config{number_of_used_area_pie}++;
		}

		# print "coursecode= $codcour, area= $course_info{$codcour}{axe}\n";
		$course_info{$codcour}{naxes}		= 0;
		foreach $axe (split(",", $course_info{$codcour}{axes}))
		{	$course_info{$codcour}{naxes}++;	}

		foreach $axe (split(",", $course_info{$codcour}{axes}))
		{
		      if(not defined($data{counts_per_standard}{$axe}))
		      {		$data{counts_per_standard}{$axe} 		= 0;
				$list_of_courses_per_axe{$axe}{courses} 	= [];
		      }
			  if( not looks_like_number($course_info{$codcour}{cr}) )
			  {	Util::print_error("course_info{$codcour}{cr} ($course_info{$codcour}{semester} Sem) is NOT a number ! ...");	}
		      $data{counts_per_standard}{$axe}     += $course_info{$codcour}{cr}/$course_info{$codcour}{naxes};
		      push(@{$list_of_courses_per_axe{$axe}{courses}}, $codcour);
		}
		if($course_info{$codcour}{course_type} eq "Elective")
		{
			$elective_axes 	= $course_info{$codcour}{axes};
			$elective_naxes = $course_info{$codcour}{naxes};
# 			my $credits = $course_info{$codcour}{cr};
# 			if($credits > $maxE)
# 			{	$maxE = $credits;
# 			}
            my $group = $Common::course_info{$codcour}{group};
			if( $group eq "" )
            {
			      Util::print_error("Course $codcour, Sem: $semester has NOT group being elective");
			}
			if( not defined($config{electives}{$semester}{$group}{cr}) )
			{
					$config{electives}{$semester}{$group}{cr}    = $Common::course_info{$codcour}{cr};
					$config{electives}{$semester}{$group}{prefix}= $Common::course_info{$codcour}{prefix};
					$config{electives}{$semester}{$group}{area_pie} = $Common::course_info{$codcour}{area_pie};
					#Util::print_message("config{electives}{$semester}{$group}{cr}=$config{electives}{$semester}{$group}{cr}");
					#$electives{$group}{prefix}= $Common::course_info{$codcour}{prefix};
					$counts{credits}{prefix}{$prefix}     += $Common::course_info{$codcour}{cr};
					$counts{credits}{area_pie}{$area_pie} += $Common::course_info{$codcour}{cr};
			}
			else
			{       #Util::halt("config{electives}{$semester}{$group}{cr}=$electives{$group}{cr},  Common::course_info{$codcour}{cr}=$Common::course_info{$codcour}{cr}");
					#Util::print_message("electives{$group}{prefix}=$electives{$group}{prefix}, Common::course_info{$codcour}{prefix}=$Common::course_info{$codcour}{prefix}");
			}
		}
		if($course_info{$codcour}{course_type} eq "Mandatory")
		{
			#Util::print_message("codcour=$codcour, cr=$toadd");
			foreach $axe (split(",", $course_info{$codcour}{axes}))
			{	$counts{credits}{areas}{$axe} += $course_info{$codcour}{cr}/$course_info{$codcour}{naxes};
				#print "$axe -> $course_info{$codcour}{cr}/$course_info{$codcour}{naxes}\n" if($codcour eq "CS225T");
			}
			$counts{credits}{count}	      += $course_info{$codcour}{cr};
			$counts{credits}{prefix}{$prefix}     += $Common::course_info{$codcour}{cr};
			$counts{credits}{area_pie}{$area_pie} += $Common::course_info{$codcour}{cr};
		}
		#print "codcour = $codcour, cr=$course_info{$codcour}{cr}, ($course_info{$codcour}{course_type}) $counts{credits}{count}, maxE = $maxE\n";
		#print "contador hasta el $active_semester = $counts{credits}{count}, maxE = $maxE\n";

		my $sep 						 = "";
		$course_info{$codcour}{n_prereq} = 0;
		my $new_prerequisites			 = "";
		$course_info{$codcour}{prerequisites_just_codes} = "";
		foreach my $codreq (split(",", $course_info{$codcour}{prerequisites}))
		{
			$codreq =~ s/ //g;
			if($codreq =~ m/(.*?)=(.*)/)
			{
				my ($inst, $prereq) = ($1, $2);
				if( $inst eq $config{institution})
				{
					$new_prerequisites .= "$sep$inst=$prereq";
					$course_info{$codcour}{prerequisites_just_codes} .= "$sep$inst=$prereq";
					foreach my $lang ( @{$config{SyllabusLangsList}} )
					{       push(@{$course_info{$codcour}{$lang}{full_prerequisites}}, $prereq);
							push(@{$course_info{$codcour}{$lang}{code_name_and_sem_prerequisites}}, $prereq );
					}
					$course_info{$codcour}{short_prerequisites}         .= "$sep$prereq";
					$course_info{$codcour}{code_and_sem_prerequisites}  .= "$sep$prereq";
					push( @{$course_info{$codcour}{prerequisites_for_this_course}}, "$sep$inst=$prereq");
					$course_info{$codcour}{n_prereq}++;
					$codreq = $prereq;
				}
				else
				{	my $semester_label = format_semester_label_in_plain_text($semester, $lang) ;	
					Util::print_warning("It seems that course $codcour ($semester_label) has an invalid req ($codreq) ... ignoring");
				}
			}
			else
			{	#print("codcour=$codcour (".format_semester_label_in_plain_text($course_info{$codcour}{semester}, $lang).")" );
				my $prereq_label = unmask_codcour2($codreq, "Processing prerrequisites for $codcour ($course_info{$codcour}{$lang}{course_name}, Sem: $course_info{$codcour}{semester})");
				#Util::print_message(", codreq=$codreq, prereq_label=$prereq_label");
				#if($prereq_label eq "")
				#{	Util::print_error("codcour=$codcour,sem=$semester ($course_info{$codcour}{English}{course_name})\n codreq=$codreq Did you forget to activate that prereq ($codreq) See: $input_file");	}
				$codreq = $prereq_label;
				#Util::print_message("codcour=$codcour,codreq=$codreq");
				$new_prerequisites .= "$sep$codreq";
				$course_info{$codcour}{prerequisites_just_codes} .= "$sep$codreq";
				if(defined($course_info{$codreq}))
				{
					#Util::print_message("codreq=$codreq, codreq_label=$codreq_label");
					my $semester_prereq = $course_info{$codreq}{semester};
					foreach my $lang ( @{$config{SyllabusLangsList}} )
					{
							my $prereq_course_link = get_course_link($codreq, $lang);
							push(@{$course_info{$codcour}{$lang}{full_prerequisites}}, $prereq_course_link);
							my $temp  = "\\htmlref{$codreq. $course_info{$codreq}{$lang}{course_name}}{sec:$codcour}.~";
							my $prereq_sem_label = format_semester_label_in_latex($semester_prereq, $lang);
							$temp .= "($prereq_sem_label)";
							push( @{$course_info{$codcour}{$lang}{code_name_and_sem_prerequisites}}, $temp );
					}
					my $prereq_sem_label = format_semester_label_in_latex($semester_prereq, $lang);
					$course_info{$codcour}{short_prerequisites}        .= "$sep\\htmlref{$codreq}{sec:$codreq} ($prereq_sem_label)";
					$course_info{$codcour}{code_and_sem_prerequisites} .= "$sep\\htmlref{$codreq}{sec:$codreq} ($prereq_sem_label)";

					push( @{$course_info{$codcour}{prerequisites_for_this_course}}, $codreq);
					push( @{$course_info{$codreq}{courses_after_this_course}}, $codcour);
					$course_info{$codcour}{n_prereq}++;
				}
				else
				{
					print Dumper(\%{$course_info{$codcour}});
					Util::halt("parse_courses: Course $codcour (sem #$semester) has a prerequisite \"$codreq\" not defined");
				}
			}
			$sep = ",";
		}
		$course_info{$codcour}{prerequisites} = $new_prerequisites;
		if($course_info{$codcour}{n_prereq} == 0)
		{	    foreach my $lang ( @{$config{SyllabusLangsList}} )
                {   $course_info{$codcour}{$lang}{full_prerequisites} = $config{dictionary}{None};	}
        }
		# Hours Accumulator
		my $hours = 0;
		$hours += $course_info{$codcour}{th};
		$hours += $course_info{$codcour}{ph};
		$hours += $course_info{$codcour}{lh};

		foreach $axe (split(",", $course_info{$codcour}{axes}))
		{
			if(not defined($counts{hours}{areas}{$axe}))
			{	$counts{hours}{areas}{$axe} = 0;		}
			$counts{hours}{areas}{$axe} += $hours/$course_info{$codcour}{naxes};
		}
		$counts{hours}{count} += $hours;
#         if( $codcour eq "CS2101" )
#         {
#                 print Dumper( \%{$Common::course_info{$codcour}} );
#                 Util::print_message("Common::course_info{$codcour}{n_prereq} = $Common::course_info{$codcour}{n_prereq}");
#                 #print Dumper( \%map );
#                 # $config{map_file_to_course}{$coursefile} = $codcour;
#                 print Dumper( \%{$config{map_file_to_course}} );
#                 exit;
#         }
	}

	foreach $axe (split(",", $elective_axes))
	{	$counts{credits}{areas}{$axe}	+= $maxE/$elective_naxes;	}
	$counts{credits}{count}		 	+= $maxE;

	my $semester;
	for($semester=1; $semester <= $config{n_semesters} ; $semester++)
	{	$config{semester_electives}{$semester} = ();		}

	for($semester=1; $semester <= $config{n_semesters} ; $semester++)
	{
        $config{credits_this_semester}{$semester} = 0;
		foreach my $codcour (@{$courses_by_semester{$semester}})
		{
			#print Dumper( \%{$course_info{$codcour}} );
			if($course_info{$codcour}{course_type} eq "Mandatory")
			{
					if( not $course_info{$codcour}{group} eq "")
					{
						my $course_name = $course_info{$codcour}{$lang}{course_name};
						Util::print_error("Course: $codcour ($course_name, ".format_semester_label_in_plain_text($semester, $lang).") is $course_info{$codcour}{course_type} ... its group MUST be empty ... ");
					}
					$Common::config{credits_this_semester}{$semester} += $course_info{$codcour}{cr};
					#Util::print_message("Sem=$semester,acu=$Common::config{credits_this_semester}{$semester}, course_info{$codcour}{cr}=$course_info{$codcour}{cr}");
			}
			else
			{
				if( $course_info{$codcour}{group} eq "" )
				{	Util::print_color("course_info{$codcour}{group}=\"$course_info{$codcour}{group}\", course_info{$codcour}{course_type}=$course_info{$codcour}{course_type} (Sem=$semester) It is an elective course. It MUST have a group ...");	
					Util::print_error("Error !");
				}
				assert(not $course_info{$codcour}{group} eq "");
				my $group = $course_info{$codcour}{group};
				if( not defined($config{semester_electives}{$semester}{$group}{list}) )
				{	$config{semester_electives}{$semester}{$group}{list} = [];	}
				push(@{$config{semester_electives}{$semester}{$group}{list}}, $codcour);
			}
			foreach $axe (split(",", $course_info{$codcour}{axes}))
			{
				if(not defined($list_of_courses_per_area{$axe}))
				{	$list_of_courses_per_area{$axe} = [];	}
				push(@{$list_of_courses_per_area{$axe}}, $codcour);
				$counts{credits}{areas}{$axe} += $course_info{$codcour}{cr}/$course_info{$codcour}{naxes};
				#Util::print_message("codcour=$codcour, axe=$axe");
			}
		}
		#Util::print_message("config{credits_this_semester}{$semester}=$config{credits_this_semester}{$semester}");
		if( defined($config{electives}{$semester}) )
		{
				foreach my $group (keys %{$config{electives}{$semester}})
				{
					#Util::print_message("config{electives}{$semester}{$group}{cr} = $config{electives}{$semester}{$group}{cr}");
					$config{credits_this_semester}{$semester}                    += $config{electives}{$semester}{$group}{cr};
				}
		}
		#Util::print_message("config{credits_this_semester}{$semester}=$config{credits_this_semester}{$semester}");
	}
	if($courses_count < 1)
	{
	      Util::halt("It seems that I did not read many courses ($courses_count) ... verify file \"$input_file\" ...");
	}
	$config{ncourses} = $courses_count;
	Util::check_point("filter_courses");
	Util::print_message("Read courses = $courses_count ($config{n_semesters} semesters)");
#     print Dumper( \%{$config{map_file_to_course}} );
	#Util::print_message("$course_info{CS221}{prerequisites_just_codes} abc");
}

sub sort_courses()
{
	my $count = 0;
	foreach my $codcour (@codcour_list_sorted)
	{
		my $prefix = $Common::course_info{$codcour}{prefix};
		if(not defined($config{prefix_priority}{$prefix}) )
		{	$count++;
			Util::print_message("$Util::icons{X} No prefix_priority defined for ".Util::red($prefix)." $codcour (Sem: $Common::course_info{$codcour}{semester})");
		}
	}
	if( $count > 0 )
	{	print_keyLog("SpiderChartAxes");
		exit;	
	}

	@codcour_list_sorted = sort {$Common::course_info{$a}{semester} <=> $Common::course_info{$b}{semester} ||
								 $Common::config{prefix_priority}{$Common::course_info{$a}{prefix}} <=> $Common::config{prefix_priority}{$Common::course_info{$b}{prefix}} ||
								 $Common::course_info{$b}{course_type} cmp $Common::course_info{$a}{course_type} ||
								 $a cmp $b
							}
				@codcour_list_sorted;
	#@{$Common::courses_by_semester{$semester}})
        #$codcour_label
	#print Dumper(\@codcour_list_sorted);
	my $course_priority = 0;
	foreach my $codcour (@codcour_list_sorted)
	{
		my $semester = $course_info{$codcour}{semester};
		#Util::print_message("$codcour, Sem:$course_info{$codcour}{semester}");
		if(not defined($courses_by_semester{$semester}))
		{	$courses_by_semester{$semester} = [];		}
		push(@{$courses_by_semester{$semester}}, $codcour);
		$codcour_list_priority{$codcour} = $course_priority++;
	}
	Util::check_point("sort_courses");
}

sub get_list_of_bib_files($)
{
	my ($lang) = (@_);
    my $syllabus_container_dir 	= Common::GetExpandedTemplateWithLang("InSyllabiContainerDir", $lang);
    for(my $semester = 1; $semester <= $Common::config{n_semesters}; $semester++)
    {
		foreach my $codcour (@{$Common::courses_by_semester{$semester}})
		{#	Util::print_message("codcour = $codcour, bibfiles=$Common::course_info{$codcour}{bibfiles}");
			foreach (split(",", $Common::course_info{$codcour}{bibfiles}))
			{
				$Common::config{allbibfiles}{"$syllabus_container_dir/$_"} = "";
			}
		}
    }
    my ($all_bib_items, $sep) = ("", "");
    foreach my $bibfile (keys %{$Common::config{allbibfiles}})
    {
	$all_bib_items .= "$sep$bibfile";
	$sep = ",";
    }
    return $all_bib_items;
}

sub read_min_max($$)
{
	my ($SpiderChartInfoDir, $standard) = (@_);
	my $input_file = "$SpiderChartInfoDir/$standard-MinMax.tex";
	if( -r $input_file )
	{	Util::print_message("$Util::icons{ok} Reading $input_file");	}
	else
	{	Util::print_message("$Util::icons{X} I cann't read: ".Util::red($input_file));
		my $ConfigFile = GetTemplate("in-area-all-config-file");
		Util::print_message("Guess: look at:".Util::red($ConfigFile));
		exit;
	}
	my $filetxt = Util::read_file("$input_file");

	# This accumulator is only to calculate the final % compared with the total
	$config{StdInfo}{$standard}{min} = 0;
	$config{StdInfo}{$standard}{max} = 0;
	my $axe;
	foreach $axe (split(",", $config{SpiderChartAxes}))
	{
		$config{StdInfo}{$standard}{$axe}{min} = 0;
		$config{StdInfo}{$standard}{$axe}{max} = 0;
	}
	while($filetxt =~ m/\\topic\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}/g)
	{
		$axe = $1;
		$config{StdInfo}{$standard}{$axe}{min} += $3;
		$config{StdInfo}{$standard}{$axe}{max} += $4;

		# This accumulator is only to calculate the final % compared with the total
		$config{StdInfo}{$standard}{min} += $3;
		$config{StdInfo}{$standard}{max} += $4;
	}
}

sub read_all_min_max($)
{
	my ($lang) = (@_);
	my $SpiderChartInfoDir = GetExpandedTemplateWithLang("SpiderChartInfoDir", $lang);
	Util::print_color("SpiderChartInfoDir=$SpiderChartInfoDir");
	Util::print_color("Reading Min-Max Info in sequence: $config{Standards}");
	foreach (split(",", $config{Standards}))
	{	read_min_max($SpiderChartInfoDir, $_);
	}
	Util::print_message("read_all_min_max($lang) OK!");
}

# ok
sub replace_generic_environments($$$$$)
{
	my ($text, $env_name, $label_text, $label_type, $new_env_name) = (@_);
	my $count  = 0;
	#Replace environment
	#print "(2) $env_name being processed ... \n" if($env_name eq "outcomes");
	while($text =~ m/\\begin\{$env_name\}\s*\n((.|\t|\s|\n)*?)\\end\{$env_name\}/g)
	{
 		#print "(3) $env_name processed OK !\n" if($env_name eq "outcomes");
		$count++;
		my $env_body_in  = $1;
		my $env_body_out = $env_body_in;
		$env_body_in = replace_special_chars($env_body_in);
		my $out_text = "\\$label_type\{$label_text\}";
		$text =~ s/\\begin\{$env_name\}\s*\n$env_body_in\\end\{$env_name\}/$out_text\n\\begin\{$new_env_name\}\n$env_body_out\\end\{$new_env_name\}/g;
	}
	return ($text, $count);
}

# ok
sub replace_bold_environments($$$$)
{
	my ($text, $env_name, $label_text, $label_type) = (@_);
	my $count  = 0;
	#Replace Sumillas
	while($text =~ m/\\begin\{$env_name\}\s*\n((?:.|\n)*?)\\end\{$env_name\}/g)
	{
		my $env_body_in = $1;
		my $env_body_out = $env_body_in;
		#print "### ($count)\n$env_body\n---\n";
		$env_body_in = Common::replace_special_chars($env_body_in);
		my $text_out = "\\$config{subsection_label}"."{$label_text}\n\n$env_body_out";
		$text =~ s/\\begin\{$env_name\}\s*\n$env_body_in\\end\{$env_name\}/$text_out/g;
		#print "*";
		$count++;
	}
	return ($text, $count);
}

sub replace_enumerate_environments($$$$)
{
	my ($text, $env_name, $label_text, $label_type) = (@_);
	my $count = 0;
	#print "(1) $env_name being processed ... $env_name, $label_text, $label_type,\n";
	($text, $count) = replace_generic_environments($text, $env_name, $label_text, $label_type, "enumerate");
	#print "(3) $env_name being processed ... $env_name, $label_text, $label_type,   (text, $count)\n";
	return ($text, $count);
}

sub replace_description_environments($$$$)
{
	my ($text, $env_name, $label_text, $label_type) = (@_);
	#print "(1) $env_name being processed ...\n" if($env_name eq "outcomes");
	return replace_generic_environments($text, $env_name, $label_text, $label_type, "description");
}

sub check_preconditions()
{
	for(my $semester = 1; $semester <= $Common::config{n_semesters}; $semester++)
	{
                foreach my $codcour ( @{$Common::courses_by_semester{$semester}} )
		{
			#Util::print_message("$codcour=>\"$Common::course_info{$codcour}{prefix}\"");
			if(not defined($Common::config{prefix_priority}{$Common::course_info{$codcour}{prefix}}))
			{
				my $area_all_config = GetTemplate("in-area-all-config-file");
				Util::print_error("Course $codcour has an unknown prefix \"$Common::course_info{$codcour}{prefix}\" ... VERIFY $area_all_config");
			}
		}
	}
}

sub change_number_by_text($)
{
      my ($label) = (@_);
      my $count = 0;
      $count = $label =~ s/(\d)/$Numbers2Text{$1}/g;
      #Util::print_message($count);
      return $label;
}

sub generate_course_info_in_dot($$$)
{
	my ($codcour, $this_item, $lang) = (@_);
	# ! Pending Er Pasa muchas veces por aqui !
	my %map = ();

	$map{CODE}	= $codcour;
	if( not defined($course_info{$codcour}{$lang}{course_name}))
	{	Util::print_error("Who is calling this course?");	}
	my $course_name = $course_info{$codcour}{$lang}{course_name};
	my ($newlabel,$nlines) = wrap_label("$codcour. $course_name");
	my @height = (0, 0, 0.6, 0.9, 1.2, 1.5);
# 	my $height = 0.3*$nlines+0.1*($nlines-1) + 0.3*$config{extralevels}+0.05*($config{extralevels}-1);
	$map{FULLNAME}	= $newlabel;
 	# Util::print_message("$nlines+$config{dictionary}{extralevels}");
	$map{HEIGHT}	= 0.3*($nlines+$config{dictionary}{extralevels});
	$map{FONTCOLOR}	= $course_info{$codcour}{textcolor};

	if($config{graph_version} >= 2)
	{	$map{SHAPE}			= "Mrecord";
		if( $course_info{$codcour}{short_type} eq $config{dictionaries}{$lang}{MandatoryShort})
		{	$map{PERIPHERIES}	= 2;			}
		else
		{	$map{PERIPHERIES}	= 1;			}
		$map{SHORTTYPE}	= $course_info{$codcour}{short_type};
	}
	$map{BORDERCOLOR} = "white";
	$map{FILLCOLOR}	 = $course_info{$codcour}{bgcolor};
	$map{NumberOfCr} = $course_info{$codcour}{cr};
	$map{CR}		 = $config{dictionaries}{$lang}{CR};

	$map{Theory} = $config{dictionaries}{$lang}{Theory};
	if($course_info{$codcour}{th} > 0)
	{		$map{NumberOfTH}	= $course_info{$codcour}{th};	}
	else{	$map{NumberOfTH}	= "";	}

	$map{Practice} = $config{dictionaries}{$lang}{Practice};
	if($course_info{$codcour}{ph} > 0)
	{		$map{NumberOfPH}	= $course_info{$codcour}{ph};	}
	else{	$map{NumberOfPH}	= "";	}

	$map{Laboratory} = $config{dictionaries}{$lang}{Laboratory};
	if($course_info{$codcour}{lh} > 0)
	{		$map{NumberOfLH}	= $course_info{$codcour}{lh};	}
	else{	$map{NumberOfLH} 	= "";	}

	if($course_info{$codcour}{phEx} > 0)
	{		$map{NumberOfPHEx}	= $course_info{$codcour}{phEx};	}
	else{	$map{NumberOfPHEx}	= "";	}

	$map{NAME}	= $course_info{$codcour}{$lang}{course_name};
	$map{TYPE}	= $config{dictionaries}{$lang}{$course_info{$codcour}{course_type}};
	$map{Pag}	= $config{dictionaries}{$lang}{Pag};
	$map{PAGE}	= "";			#"--PAGE$codcour--";

	my ($outcome_txt, $sep) = ("", "");
	foreach my $outcome (@{$course_info{$codcour}{outcomes_array}})
	{	$outcome_txt	.= "$sep\\outcome{$outcome}";
		$sep 		 = ",";
	}
	$map{OUTCOMES}	= $outcome_txt;
	return replace_tags_from_hash($this_item, "<", ">", %map);
}

sub generate_course_info_in_dot_with_sem($$$)
{
	my ($codcour, $this_item, $lang) = (@_);
	my $output_txt = generate_course_info_in_dot($codcour, $this_item, $lang);

	#my $sem_label = format_semester_label_in_plain_text($Common::course_info{$codcour}{semester}, $lang);
    #$output_txt  =~ s/\(<SEM>\)/\($sem_label\)/g;
	return $output_txt;
}

sub update_page_numbers($)
{
	my ($file)     = (@_);
        Util::precondition("read_pagerefs");
	my $file_txt  = Util::read_file($file);
# 	Util::print_message("update_page_numbers: replacing $file ... pages replaced ok !");
	#$file_txt =~ s/--PAGEFG102--/$Common::config{pages_map}{"sec:FG102"}/g;
	while( $file_txt =~ m/--PAGE(.*?)--/)
	{
		my $course = $1;
		#Util::print_message("Replacing $course ...");
		if( defined($Common::config{pages_map}{"sec:$course"}) )
		{	$file_txt =~ s/--PAGE$course--/$Common::config{pages_map}{"sec:$course"}/g;	}
		else
		{	$file_txt =~ s/--PAGE$course--/  /g;	}
 	}
	#$file_txt =~ s/--PAGE(.*?)--/$Common::config{pages_map}{"sec:$1"}/g;
	foreach my $outcome (keys %{$Common::config{outcomes_map}})
	{
# 		Util::print_message("Outcome: $outcome being replaced ...");
		$file_txt =~ s/\\outcome\{$outcome\}/$Common::config{outcomes_map}{$outcome}/g;
	}
# 	print Dumper(\%{$Common::config{outcomes_map}});
	Util::write_file($file, $file_txt);
	Util::print_message("File $file ... pages replaced ok !");
}

sub update_page_numbers_for_all_courses_maps()
{
	my $OutputDotDir  = Common::GetTemplate("OutputDotDir");
	foreach my $codcour (@codcour_list_sorted)
	{
		Common::update_page_numbers("$OutputDotDir/$codcour.dot");
	}
}

our %bok = ();
sub parse_bok_from_raw_text($)
{
	my ($lang) = (@_);
	my $bok_in_file = GetExpandedTemplateWithLang("in-bok-macros-V0-file", $lang); 
 	Util::print_message("$Util::icons{ok} Processing ".Util::highlight_filename($bok_in_file)." ...");  #ABC
	my $bok_in = Util::read_file($bok_in_file);
	my $output_txt = "";

	my %counts = ();
	my $KAorder = 0;
	while($bok_in =~ m/\\(.*?)\{(.*?)\}/g)
	{
	    my ($cmd, $ka)  = ($1, $2);
	    if($cmd eq "KA") # \KA{AL}{<<Algoritmos y Complejidad>>}{crossref}
	    {
			$bok_in =~ m/\{<<(.*?)>>\}\{(.*?)\}/g;
			my ($body, $crossref)  = ($1, $2);
			if( $body =~ m/(.*)\.$/ )
			{	$body = $1;	}

			$bok{$lang}{$ka}{name} 	= $body;
			$bok{$lang}{$ka}{order} 	= $KAorder++;
			($bok{$lang}{$ka}{nhTier1}, $bok{$lang}{$ka}{nhTier2}) = (0, 0);
			$counts{$cmd}++;

			#if( not $crossref eq "" )
			#{	Util::print_message("Area: $ka, cros$bok_output_filesref: \"$crossref\"");		}
			#Util::print_message("$body");
	    }
	    elsif( $cmd eq "KADescription")
	    {
			$bok_in =~ m/{<<((.|\n)*?)>>}/g;
			my ($body)  = ($1);
	# 		if( $body =~ m/(.*)\.$/ )
	# 		{	$body = $1;	}

			$bok{$lang}{$ka}{description} = $body;
			$counts{$cmd}++;
	    }
	    elsif( $cmd eq "KU") # \KU{AL}{BasicAnalysis}{<<Análisis Básico>>}{}{#hours Tier1}{#hours Tier2}
	    {
			$bok_in =~ m/\{(.*?)\}\{<<(.*?)>>\}\{(.*?)\}\{(.*?)\}\{(.*?)\}/g;
			my ($p2, $body, $crossref, $nhTier1, $nhTier2)  = ($1, $2, $3, $4, $5);
			if( $body =~ m/(.*)\.$/ )
			{	$body = $1;	}

			my $ku 			= "$ka$p2";
			%{$bok{$lang}{$ka}{KU}{$ku}} 	= ();
			my $KUPos 		= scalar keys %{$bok{$lang}{$ka}{KU}};
			$bok{$lang}{$ka}{KU}{$ku}{name}= $ku;
			$bok{$lang}{$ka}{KU}{$ku}{order}= $KUPos;
			$bok{$lang}{$ka}{KU}{$ku}{body} = $body;
			$bok{$lang}{$ka}{KU}{$ku}{nhTier1} 	 = $nhTier1;
			#Util::print_message("bok{$ka}{nhTier1} 		+= $nhTier1;");
			$bok{$lang}{$ka}{nhTier1} 			+= $nhTier1;
			$bok{$lang}{$ka}{KU}{$ku}{nhTier2} 	 = $nhTier2;
			$bok{$lang}{$ka}{nhTier2} 			+= $nhTier2;

			$ku_info{$lang}{$ku}{ka} 		= $ka;
			$ku_info{$lang}{$ku}{nhTier1}	= $nhTier1;
			$ku_info{$lang}{$ku}{nhTier2}	= $nhTier2;

			$counts{$cmd}++;
	# 		Util::print_message("KU ($ka, $ku, $KUPos, $crossref, Tier1=$nhTier1, Tier2=$nhTier2) ...");
	    }
	    elsif( $cmd eq "KUDescription") # \KUDescription{AL}{BasicAnalysis}{<<~>>}
	    {
			$bok_in =~ m/\{(.*?)\}\{<<((.|\n)*?)>>\}/g;
			my ($p2, $body)  = ($1, $2);
			#if( $body =~ m/(.*)\.$/ )
			#{	$body = $1;	}

			my $ku			= "$ka$p2";
			$bok{$lang}{$ka}{KU}{$ku}{description}= $body;
			$counts{$cmd}++;
	# 		Util::print_message("KU ($ka, $ku, KUDescription) ...");
	    }
	    elsif( $cmd eq "KUItem") # \KUItem{AL}{BasicAnalysis}{Core-Tier2}{Recurrence}{crossrefs}{<<Relaciones recurrentes \begion{topic} ... \n \end{topic}.>>}
	    {
			$bok_in =~ m/\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{<<((.|\n)*?)>>\}/g;
			my ($kubase, $tier, $kuposfix, $crossref, $body)  = ($1, $2, $3, $4, $5);
			#if( $body =~ m/(.*)\.$/ )
			#{	$body = $1;	}

			my $ku 			= "$ka$kubase";
			my $kuitem		= $ku."Topic".$kuposfix;
			my $KUItemPos 		= scalar keys %{$bok{$lang}{$ka}{KU}{$ku}{items}{$tier}};
			$bok{$lang}{$ka}{KU}{$ku}{items}{$tier}{$kuitem}{body}  = $body;
			$bok{$lang}{$ka}{KU}{$ku}{items}{$tier}{$kuitem}{order} = $KUItemPos;
	# 		$crossref =~ s/\s//g;
			$bok{$lang}{$ka}{KU}{$ku}{items}{$tier}{$kuitem}{crossref} = $crossref;
	# 		if( not $bok{$lang}{$ka}{KU}{$ku}{items}{$tier}{$kuitem}{crossref} eq "" )
	# 		{	Util::print_message("kuitem = $kuitem, bok{$ka}{KU}{$ku}{items}{$tier}{$kuitem}{crossref} = $bok{$lang}{$ka}{KU}{$ku}{items}{$tier}{$kuitem}{crossref} ... ");			
	# 		}
			$counts{$cmd}++;
			#Util::print_message("$cmd, $ka, $kubase, $kuposfix, $tier, $body ...");
	    }
	    elsif( $cmd eq "LO") # \LO{AL}{BasicAnalysis}{Core-Tier1}{Familiarity}{State}{<<Indique la definicion formal de Big O.>>}
	    {
			$bok_in =~ m/\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{<<((.|\n)*?)>>\}/g;
			my ($kubase, $tier, $lolevel, $kuposfix, $body)  = ($1, $2, $3, $4, $5);
			if( $body =~ m/(.*)\.$/ )
			{	$body = $1;	}

			my $ku 			= "$ka$kubase";
			my $LOitem		= $ku."LO".$kuposfix;
			my $LOItemPos 	= scalar keys %{$bok{$lang}{$ka}{KU}{$ku}{LO}{$tier}};
			$bok{$lang}{$ka}{KU}{$ku}{LO}{$tier}{$LOitem}{body}  	= $body; 		# $tier = Core-Tier1, Core-Tier2, Elective
			$bok{$lang}{$ka}{KU}{$ku}{LO}{$tier}{$LOitem}{lolevel} = $lolevel; 		# $lolevel = Familiarity
			$bok{$lang}{$ka}{KU}{$ku}{LO}{$tier}{$LOitem}{order} 	= $LOItemPos;
			$counts{$cmd}++;
			#Util::print_message("$cmd, $ka, $kubase, $kuposfix, $tier, $lolevel ...");
			#Util::print_message("KU ($ka, $ku, $KUPos) ...");
	    }
	    #Util::print_message("Processing macro #$count: $cmd ...");
	}
	foreach my $count_name (keys %counts)
	{	printf("\t$Util::icons{ok} counts{%-13s} = %d ...\n", Util::yellow("$count_name"), $counts{$count_name});	}
	Util::check_point("parse_bok_from_raw_text");
	#print Dumper(\%bok);
	#Util::print_message("parse_bok_from_raw_text($bok_in_file) $count macros processed ... OK!");
	#Util::print_message("bok{SE}{order} = $bok{$lang}{SE}{order}");
# 	Util::print_message("bok{$lang}");
# 	foreach my $key (keys %{$bok{Espanol}{SP}{KU}})
# 	{	Util::print_warning("key=$key");	}
 	#print Dumper (\%{$Common::bok{"Espanol"}{DS}{KU}});
}

sub format_general_ku_label($$)
{
	my ($lang, $ku) = (@_);
	#my $ka = $Common::ku_info{$lang}{$ku}{ka};
	if(not defined($Common::ku_info{$lang}{$ku}{ka}))
	{
		my $bok_in_file = Common::GetExpandedTemplateWithLang("in-bok-macros-file", $lang);
 		Util::print_message("TODO Common: format_ku_label($lang, $ku) ... Processing $bok_in_file ...");
		Util::print_message("Not defined ".Util::yellow("Common::ku_info{$lang}{$ku}{ka}")." (see file: ".Util::yellow($bok_in_file)." ...)");
		print Dumper(\%{$Common::ku_info{$lang}});
		exit;
	}
	my $ka = $Common::ku_info{$lang}{$ku}{ka};
	my $ku_label = "$ka \\$bok{$lang}{$ka}{KU}{$ku}{name}";
	my $nhours_txt = "";
	my $sep = "";

	if(defined( $bok{$lang}{$ka}{KU}{$ku}{nhTier1} ) )
	{
		if( $bok{$lang}{$ka}{KU}{$ku}{nhTier1} > 0 )
		{	$nhours_txt .= "$sep$bok{$lang}{$ka}{KU}{$ku}{nhTier1} $Common::config{dictionary}{hours} Core-Tier1";	$sep = ",~";
		}
	}
	if(defined( $bok{$lang}{$ka}{KU}{$ku}{nhTier2} ) )
	{
		if( $bok{$lang}{$ka}{KU}{$ku}{nhTier2} > 0 )
		{	$nhours_txt .= "$sep$bok{$lang}{$ka}{KU}{$ku}{nhTier2} $Common::config{dictionary}{hours} Core-Tier2";	$sep = ",~";
		}
	}
	if( not $nhours_txt eq "" )
	{	$ku_label .= " ($nhours_txt)";
	}
	return $ku_label ;
}

sub format_ku_label($$)
{
	my ($lang, $ku) = (@_);
	if($config{area} eq "CS" or $config{area} eq "DS" )
	{	return format_general_ku_label($lang, $ku);		}
	elsif( $config{area} eq "IS" )
	{	
		my $ka = $Common::ku_info{$lang}{$ku}{ka};
		my $ku_label = "$ka \\$ku";
		# Util::print_message("ka=$ka, ku=$ku, ku_label=$ku_label");
		# my $ka1 = $Common::ku_info{$lang}{LU}{ka};
		# my $ku_label1 = "$ka1 \\$bok{$lang}{LU}{KU}{LU10}{name}";
		# Util::print_message("ka1=$ka1, ku=LU10, ku_label1=$ku_label1");
		return $ku_label;	
	}
	else
	{	Util::print_error("config{area}=$config{area} not supported !");	
	}
}

sub get_standard_title($)
{
	my ($standard) = (@_);
	my $caption = $Common::config{dictionary}{ComparisonWithStandardCaption};
	#Comparacin por area de \\SchoolShortName de la \\siglas~con la propuesta de {\\it <STANDARD_LONG_NAME>} <STANDARD> de <STANDARD_REF_INSTITUTION>.
	$caption =~ s/<STANDARD_LONG_NAME>/$Common::config{dictionary}{standards_long_name}{$standard}/g;
	$caption =~ s/<STANDARD>/$standard/g;
	$caption =~ s/<STANDARD_REF_INSTITUTION>/$Common::config{dictionary}{InstitutionToCompareWith}/g;
	$caption =~ s/<AREA>/$Common::config{area}/g;
	$caption =~ s/<INST>/$Common::config{institution}/g;
	return $caption;
}

sub gen_bok($)
{
	my ($lang) = (@_);
	Util::precondition("parse_bok_from_raw_text");
	#foreach my $key (sort {$config{degrees}{$b} <=> $config{degrees}{$a}} keys %{$config{faculty}{$email}{fields}{shortcvline}})
	my $macros_txt = "";
	my $bok_index_txt = "";
	my $bok_output_txt = "";

	$bok_index_txt .= "\\begin{multicols}{2}\n";
	$bok_index_txt .= "\\scriptsize\n";
	$bok_index_txt .= "\\noindent\n";
	my ($max_ntopics, $maxLO) = (0, 0);
	foreach my $ka (sort {$bok{$lang}{$a}{order} <=> $bok{$lang}{$b}{order}} keys %{$bok{$lang}})
	{
		#til::print_message("Generating KA: $ka (order=$bok{$lang}{$ka}{order} ...)");
		my $macro = $ka;
		$macros_txt .= "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
		$macros_txt .= "% Knowledge Area: $ka\n";
		$macros_txt .= "\\newcommand{\\$macro}{$bok{$lang}{$ka}{name} ($ka)\\xspace}\n";

		$bok_output_txt .= "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
		$bok_output_txt .= "% Knowledge Area: $ka\n";
		$bok_output_txt .= "\\section{\\$macro}\\label{sec:BOK:$ka}\n";
		$bok_index_txt .= "\\textbf{\\ref{sec:BOK:$ka} \\htmlref{\\$macro}{sec:BOK:$ka}\\xspace ($Common::config{dictionary}{Pag}.~\\pageref{sec:BOK:$ka})}\n";
		my $hours_by_ku_file = "$ka-hours-by-ku";

		$macro = $ka."BOKDescription";
		$macros_txt .= "\\newcommand{\\$macro}{$bok{$lang}{$ka}{description}\\xspace}\n\n";
		$bok_output_txt .= "\\$macro\n\n";

		my $hours_by_ku_rows = "";
		$bok_output_txt .= "\\input{\\OutputTexDir/$hours_by_ku_file}\n";

		$bok_index_txt .= "\\begin{itemize}\n";
		foreach my $ku (sort {$bok{$lang}{$ka}{KU}{$a}{order} <=> $bok{$lang}{$ka}{KU}{$b}{order}}
				keys %{$bok{$lang}{$ka}{KU}})
		{
		      #print Dumper(\%{$bok{$lang}{$ka}{KU}{$ku}});
		      #Util::print_message("bok{$ka}{KU}{$ku}{order} = $bok{$lang}{$ka}{KU}{$ku}{order}");
		      $Common::config{topics_priority}{$ku} = $Common::config{topics_priority_counter}++;

		      my $ku_macro = "$bok{$lang}{$ka}{KU}{$ku}{name}";
		      $macros_txt .= "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
		      $macros_txt .= "% KU: $ka:$bok{$lang}{$ka}{KU}{$ku}{body}\n";
		      $macros_txt .= "\\newcommand{\\$ku_macro}{$bok{$lang}{$ka}{KU}{$ku}{body}\\xspace}\n";

		      my ($nhours_txt, $sep) = ("", "");
		      #Util::print_message("bok{$ka}{KU}{$ku}{nhTier1}=$bok{$lang}{$ka}{KU}{$ku}{nhTier1} ...");
		      $Common::config{ref}{$ku} = "sec:BOK:$ku_macro";
		      my $ku_line = "\\ref{sec:BOK:$ku_macro} \\htmlref{\\$ku_macro}{$Common::config{ref}{$ku}}\\xspace ($Common::config{dictionary}{Pag}.~\\pageref{sec:BOK:$ku_macro}) & <CORETIER1> & <CORETIER2> & <ELECTIVES> \\\\ \\hline\n";
		      $bok_index_txt .= "\\item \\ref{sec:BOK:$ku_macro} \\htmlref{\\$ku_macro}{sec:BOK:$ku_macro}\\xspace ($Common::config{dictionary}{Pag}.~\\pageref{sec:BOK:$ku_macro})\n";
		      if( $bok{$lang}{$ka}{KU}{$ku}{nhTier1} > 0 )
		      {		$nhours_txt .= "$sep$bok{$lang}{$ka}{KU}{$ku}{nhTier1} $Common::config{dictionary}{hours} Core-Tier1";	$sep = ",~";
				$ku_line     =~ s/<CORETIER1>/$bok{$lang}{$ka}{KU}{$ku}{nhTier1}/g;
		      }
		      if( $bok{$lang}{$ka}{KU}{$ku}{nhTier2} > 0 )
		      {		$nhours_txt .= "$sep$bok{$lang}{$ka}{KU}{$ku}{nhTier2} $Common::config{dictionary}{hours} Core-Tier2";	$sep = ",~";
				$ku_line     =~ s/<CORETIER2>/$bok{$lang}{$ka}{KU}{$ku}{nhTier2}/g;
		      }

		      if( defined($bok{$lang}{$ka}{KU}{$ku}{items}{Elective}) )
		      {		$ku_line     =~ s/<ELECTIVES>/$Common::config{dictionary}{Yes}/g;      }
		      else{ 	$ku_line     =~ s/<ELECTIVES>/$Common::config{dictionary}{No}/g;	}
		      $ku_line =~ s/<CORETIER.?>/~/g;

		      $hours_by_ku_rows .= $ku_line;

		      if( not $nhours_txt eq "" )
		      {		$nhours_txt = "~($nhours_txt)";	}

		      $bok_output_txt .= "\\subsection{$ka/\\$ku_macro$nhours_txt}\\label{sec:BOK:$ku_macro}\n";

		      my $ku_description_macro = "$bok{$lang}{$ka}{KU}{$ku}{name}Description";
		      $bok{$lang}{$ka}{KU}{$ku}{description} =~ s/_/\\_/g;

		      $macros_txt .= "\\newcommand{\\$ku_description_macro}{$bok{$lang}{$ka}{KU}{$ku}{description}\\xspace}\n";
		      if( not $bok{$lang}{$ka}{KU}{$ku}{description} eq "~" )
		      {  	$bok_output_txt .= "\\$ku_description_macro\\\\\n";	}

		      #my $kuitem		= $ku."Topic".$p3;
# 		      $bok{$lang}{$ka}{KU}{$ku}{items}{$tier}{$kuitem}{body}  = $body;
# 		      $bok{$lang}{$ka}{KU}{$ku}{items}{$tier}{$kuitem}{order} = $KUItemPos;
		      my $level 	= "";
		      my $level_txt 	= "";
		      #$bok{$lang}{$ka}{KU}{$ku}{items}{$tier}{$kuitem}{body}
		      my $alltopics = "";
		      $bok_output_txt .= "\\noindent \\textbf{$Common::config{dictionary}{Topics}:}\\\\\n";
		      foreach my $level (sort {$a cmp $b}
				         keys %{$bok{$lang}{$ka}{KU}{$ku}{items}})
		      {
				#Util::print_message("Generating $level ...");
				my $list_of_items = "";
			       	foreach my $kuitem (sort { $bok{$lang}{$ka}{KU}{$ku}{items}{$level}{$a}{order} <=> $bok{$lang}{$ka}{KU}{$ku}{items}{$level}{$b}{order} }
						    keys %{$bok{$lang}{$ka}{KU}{$ku}{items}{$level}} )
				{
					$bok{$lang}{$ka}{KU}{$ku}{items}{$level}{$kuitem}{crossref} =~ s/\s//g;
					my $xref_txt = "";
					if( not $bok{$lang}{$ka}{KU}{$ku}{items}{$level}{$kuitem}{crossref} eq "" )
					{
						#Util::print_message("bok{$ka}{KU}{$ku}{items}{$level}{$kuitem}{crossref} = $bok{$lang}{$ka}{KU}{$ku}{items}{$level}{$kuitem}{crossref} ... ");
						my $sep = "";
						foreach my $xref (split(",", $bok{$lang}{$ka}{KU}{$ku}{items}{$level}{$kuitem}{crossref}))
						{	$xref_txt .= "$sep\\xref{$xref}";
							$sep = ", ";
						}
						#Util::print_message("xref_txt = $xref_txt");
					}
					if( not $xref_txt eq "" )
					{	$xref_txt = "\\xspace \\\\ \\textbf{Ref:} $xref_txt";		}
					$list_of_items .= "\t\\item \\$kuitem$xref_txt\\label{sec:BOK:$kuitem}\n";
					$macros_txt	.= "\\newcommand{\\$kuitem}{$bok{$lang}{$ka}{KU}{$ku}{items}{$level}{$kuitem}{body}\\xspace}\n";
					$alltopics 	.= "\t\\item \\$kuitem\\xspace\n";
					#$macros_txt	.= "\\newcommand{\\$kuitem"."Level}{$level}\n";
				}
				$bok_output_txt .= "\\noindent \\textbf{$Common::config{dictionary}{$level}}\n";
				$bok_output_txt .= "\\begin{itemize}\n";
				$bok_output_txt .= $list_of_items;
				$bok_output_txt .= "\\end{itemize}\n\n";
				$macros_txt	.= "\n";
		      }
		      $macros_txt	.= "\\newcommand{\\$ku_macro"."AllTopics}{%\n";
		      $macros_txt	.= "\\begin{topics}%\n";
		      $macros_txt	.= $alltopics;
		      $macros_txt	.= "\\end{topics}\n}\n";
		      $bok_output_txt .= "\n";

		      #$bok{$lang}{$ka}{KU}{$ku}{LO}{$p4}{$LOitem}{body}  = $body; 	# $p4 = Familiarity
		      #$bok{$lang}{$ka}{KU}{$ku}{LO}{$p4}{$LOitem}{order} = $LOItemPos;
		      my $all_lo = "";
		      $bok_output_txt .= "\\noindent \\textbf{$Common::config{dictionary}{LearningOutcomes}:}\\\\\n";
		      my $count_of_items = 0;
			  #$bok{$lang}{$ka}{KU}{$ku}{LO}{$tier}{$LOitem}{body}  	= $body; 		# $tier = Core-Tier1, Core-Tier2, Elective
			  #$bok{$lang}{$ka}{KU}{$ku}{LO}{$tier}{$LOitem}{lolevel} = $lolevel; 		# $lolevel = Familiarity
			  #$bok{$lang}{$ka}{KU}{$ku}{LO}{$tier}{$LOitem}{order} 	= $LOItemPos;
		      foreach my $level (sort {	$bok{$lang}{$ka}{KU}{$ku}{LO}{$a} cmp $bok{$lang}{$ka}{KU}{$ku}{LO}{$b} }
				                 keys %{$bok{$lang}{$ka}{KU}{$ku}{LO}})
		      {
				$bok_output_txt .= "\\noindent \\textbf{$level:}\n";
				my $all_the_items = "";
				my $count_of_items_local = 0;
			    foreach my $loitem (sort { $bok{$lang}{$ka}{KU}{$ku}{LO}{$level}{$a}{order} <=> $bok{$lang}{$ka}{KU}{$ku}{LO}{$level}{$b}{order} }
						    keys %{$bok{$lang}{$ka}{KU}{$ku}{LO}{$level}} )
				{
					$all_the_items .= "\t\\item \\$loitem\\xspace[\\".$loitem."Level]\\label{sec:BOK:$loitem}\n";
					$macros_txt	.= "\\newcommand{\\$loitem}{$bok{$lang}{$ka}{KU}{$ku}{LO}{$level}{$loitem}{body}\\xspace}\n";
					my $loitemlevel  = $loitem."Level";
					my $thisloitemlevel = $Common::config{dictionaries}{$lang}{$bok{$lang}{$ka}{KU}{$ku}{LO}{$level}{$loitem}{lolevel}};
					$macros_txt	.= "\\newcommand{\\$loitemlevel}{$thisloitemlevel}\n";
					$all_lo 	.= "\t\\item \\$loitem\\xspace[\\".$loitem."Level] %\n";
					$count_of_items_local++;
				}
				$bok_output_txt .= "\\begin{enumerate}\n";
				$bok_output_txt .= "\t\\setcounter{enumi}{$count_of_items}\n";
				$bok_output_txt .= $all_the_items;
				$bok_output_txt .= "\\end{enumerate}\n";
				$count_of_items += $count_of_items_local;
				$macros_txt	.= "\n";
		      }
		      $macros_txt	.= "\\newcommand{\\$ku_macro"."AllLearningOutcomes}{%\n";
		      $macros_txt	.= "\\begin{learningoutcomes}%\n";
		      $macros_txt	.= $all_lo;
		      $macros_txt	.= "\\end{learningoutcomes}%\n}\n\n";
		      $bok_output_txt .= "\n\n";
		} # ku loop
		$bok_index_txt .= "\\end{itemize}\n\n";

		$macros_txt     .= "\n\n";
		$bok_output_txt .= "\n\n";

		$hours_by_ku_file = Common::GetTemplate("OutputTexDir")."/$hours_by_ku_file.tex";
		#Util::print_message("Generating $hours_by_ku_file ...");
		my $hours_by_ku_table = "\\begin{center}\n";
		$hours_by_ku_table .= "\\begin{tabularx}{\\textwidth}{|X|p{1cm}|p{1cm}|p{1.4cm}|}\\hline\n";
		$hours_by_ku_table .=  "\\textbf{\\acf{KA}} & \\textbf{".$Common::config{dictionary}{"Core-Tier1"}."} & \\textbf{".$Common::config{dictionary}{"Core-Tier2"}."} & \\textbf{$Common::config{dictionary}{Elective}} \\\\ \\hline\n";
		$hours_by_ku_table .=  $hours_by_ku_rows;
		$hours_by_ku_table .= "\\end{tabularx}\n";
		$hours_by_ku_table .= "\\end{center}\n";

		Util::write_file($hours_by_ku_file, $hours_by_ku_table);
	}
	$bok_index_txt .= "\\end{multicols}\n";

	my $bok_index_file = Common::GetExpandedTemplateWithLang("out-bok-index-file", $lang);
	Util::print_message("Creating BOK ".Util::yellow("index")."  (".Util::highlight_filename($bok_index_file)." ...");
	Util::write_file($bok_index_file, $bok_index_txt);

	my $bok_output_file = Common::GetExpandedTemplateWithLang("out-bok-body-file", $lang);
	Util::print_message("Creating BOK ".Util::yellow("file")."   (".Util::highlight_filename($bok_output_file)." ...");
	#Util::write_file($bok_output_file, $bok_output_txt);

	my $bok_macros_output_file = Common::GetExpandedTemplateWithLang("in-bok-macros-file", $lang);
	Util::print_message("Creating BOK ".Util::yellow("macros")." (".Util::highlight_filename($bok_macros_output_file)." ...");

	$macros_txt .= "\\newcommand{\\finaltest}{...}\n";
	#Util::write_file($bok_macros_output_file, $macros_txt);

	Util::check_point("gen_bok");
# 	Util::write_file();
 	#print Dumper(\%{$Common::config{topics_priority}});
}

sub generate_books_links()
{
	my $OutputPdfInstDir = GetTemplate("OutputPdfInstDir");
	my $OutputDocsDirRelativePath = GetTemplate("OutputDocsDirRelativePath");
	my $FigsDirRelativePath 	  = GetTemplate("FigsDirRelativePath");
	my $tabs = "\t\t";
	my $output_links  = "<CENTER>\n";
	$output_links    .=	"<TABLE BORDER=0 BORDERCOLOR=RED>\n";
	$output_links    .=	"<TR>\n";
	foreach my $lang (@{$Common::config{SyllabusLangsList}})
	{
		my $lang_prefix   = $Common::config{dictionaries}{$lang}{lang_prefix};
		my $poster_link	  = "$tabs<TD align=\"center\"> <a href=\"$OutputDocsDirRelativePath/$config{area}-$config{institution}-poster-$lang_prefix.pdf\">\n";
		$poster_link	 .= "$tabs$tabs<IMG SRC=\"$FigsDirRelativePath/$config{area}-$config{institution}-poster-$lang_prefix-P1.png\" border=\"1\" ALT=\"Ver p&oacute;ster de toda la carrera en PDF\" height =\"280\"><BR>P&oacute;ster </a>\n";
		$poster_link	 .= "$tabs$tabs".get_language_icon($lang)."\n";
		$poster_link	 .= "$tabs</TD>\n";
		$output_links    .= $poster_link;
	}
	$output_links    .=	"</TR>\n";
	$output_links    .=	"</TABLE>\n";

	foreach my $book ("Syllabi", "Bibliography", "Descriptions")
	{
			$output_links .= "$tabs<TABLE>\n";
			$output_links .= "$tabs<TR>\n";
			my $book_link = "";
			foreach my $lang (@{$Common::config{SyllabusLangsList}})
			{
				my $lang_prefix = $Common::config{dictionaries}{$lang}{lang_prefix};
				my $filename 	= "BookOf$book-$lang_prefix";
				my $size 		= Common::get_size("$OutputPdfInstDir/$filename.pdf");
				my $PdfnPages	= Common::getPDFnPages("$OutputPdfInstDir/$filename.pdf");
				#my $pdflink	= Common::get_link_with_language_icon("$pdf_name.pdf ($size)", "$pdf_name.pdf", $lang);
				my $BookTitle = "$config{dictionaries}{$lang}{BookOf} $config{dictionaries}{$lang}{$book}";
				$book_link .= "$tabs\t<TD align=\"center\">\n";
				$book_link .= "$tabs$tabs<A HREF=\"$OutputDocsDirRelativePath/$filename.pdf\">\n";
				$book_link .= "$tabs$tabs<IMG SRC=\"$FigsDirRelativePath/$filename-P1.png\" BORDER=\"1\" BORDERCOLOR=RED ALT=\"$BookTitle\" height=\"500\"><br>$BookTitle ($PdfnPages $config{dictionaries}{$lang}{pages}, $size)\n";
				$book_link .= "$tabs$tabs".get_language_icon($lang)."\n";
				$book_link .= "$tabs$tabs</A>\n";
				$book_link .= "$tabs\t</TD>\n";
				$book_link  = Common::special_chars_to_html($book_link);
			}
			$output_links .= $book_link;
			$output_links .= "$tabs</TR>\n";
			$output_links .= "$tabs</TABLE>\n";
			$output_links .= "$tabs<BR>\n";
			$output_links .= "$tabs<BR>\n\n";
	}
	$output_links .= "</CENTER>";
	return $output_links;
}

sub generate_information_4_professor($$)
{
      my ($email, $lang) = (@_);
      if( scalar (keys %{$Common::config{faculty}{$email}{fields}{courses_assigned}}) == 0 )
      {	return "";	}
      my $this_professor = $Common::config{faculty_tpl_txt};
      my $more = "";
      my $OutputFacultyFigDir = Common::GetTemplate("OutputFacultyFigDir");
	  my $InFacultyPhotosDir  = Common::GetExpandedTemplateWithLang("InFacultyPhotosDir", $lang);
      if( -e "$InFacultyPhotosDir/$email.jpg" )
      {
		system("cp $InFacultyPhotosDir/$email.jpg $OutputFacultyFigDir/.");
		$Common::config{faculty}{$email}{fields}{photo} = "fig/$email.jpg";
      }
      else
      {		system("cp $Common::config{NoFaceFile} $OutputFacultyFigDir/.");
		    $Common::config{faculty}{$email}{fields}{photo} = "fig/noface.gif";
      }
      my $email_png = "$OutputFacultyFigDir/$Common::config{faculty}{$email}{fields}{emailwithoutat}.png";
      #http://www.imagemagick.org/script/convert.php
      my $email_length = length($email);
      my $width = int($email_length * 8.6);
      system("convert -size $width"."x16 canvas:none -background white -font Bookman-Demi -pointsize 14 -draw \"text 0,12 '$email'\" $email_png&");

      my $concentration = $Common::config{faculty}{$email}{concentration};
      my $degreelevel	= $Common::config{faculty}{$email}{fields}{degreelevel};

      if(not defined($Common::config{faculty_groups}{$concentration}{$degreelevel}) )
      {		 $Common::config{faculty_groups}{$concentration}{$degreelevel} = [];	      }
      push(@{$Common::config{faculty_groups}{$concentration}{$degreelevel}}, $email);

      #my $cict = $Common::config{faculty}{"ecuadros\@ucsp.edu.pe"}{fields}{courses_i_could_teach};
      #Util::print_message("Courses I could teach: $cict");
      my $codcour = "";
      foreach $codcour ( keys %{$Common::config{faculty}{$email}{fields}{courses_assigned}} )
      {
	    if( not defined($Common::config{faculty}{$email}{fields}{courses_i_could_teach}{$codcour} ) )
	    {	$Common::config{faculty}{$email}{fields}{courses_i_could_teach}{$codcour} = "";
		Util::print_warning("Professor $email has assigned course $codcour but he is not able to teach that course ...");
	    }
      }

      foreach $codcour (keys %{$Common::config{faculty}{$email}{fields}{courses_i_could_teach}} )
      {		if( not defined($Common::course_info{$codcour}) )
		{
		    Util::print_warning("Course $codcour assigned to $email does not exist ...");
		}
      }

      foreach $codcour ( sort  {$Common::course_info{$a}{semester} <=> $Common::course_info{$b}{semester}}
                         keys %{$Common::config{faculty}{$email}{fields}{courses_i_could_teach}} )
      {
	    my $link = $Common::course_info{$codcour}{link};
	    if( defined($Common::config{faculty}{$email}{fields}{courses_assigned}{$codcour} ) )
	    {	$Common::config{faculty}{$email}{fields}{list_of_courses_assigned}    .= Common::GetCourseHyperLink($codcour, $link);	}
	    else
	    {	$Common::config{faculty}{$email}{fields}{other_courses_he_may_teach}  .= Common::GetCourseHyperLink($codcour, $link);	}
      }
      foreach my $field (keys %{$Common::config{faculty}{$email}{fields}})
      {
		my ($before, $after) = ("", "");
		$before = $Common::config{faculty_icons}{before}{$field} if( defined($Common::config{faculty_icons}{before}{$field}) );
		$after  = $Common::config{faculty_icons}{after}{$field} if( defined($Common::config{faculty_icons}{after}{$field}) );
		my $field_formatted = "$before";
		$field_formatted .= "$Common::config{faculty}{$email}{fields}{$field}";
		$field_formatted .= "$after";
		if( $this_professor =~ m/--$field--/g )
		{
		    $this_professor =~ s/--$field--/$field_formatted/g;
		}
		else
		{
		    $this_professor =~ s/--$field--//g;
		}
      }
      $this_professor =~ s/--.*?--//g;
      return $this_professor;
}

sub generate_faculty_info($)
{
	my ($lang)= (@_);
	Util::precondition("read_distribution");
 	%{$Common::config{faculty_icons}{before}} = ("shortcvhtml" => "<ul>\n",
						     "email" => "<img style=\"width: 16px; height: 16px;\" title=\"email\" alt=\"email\" src=\"icon/email.png\">",
						     "emailwithoutat" => "<img style=\"width: 16px; height: 16px;\" title=\"email\" alt=\"email\" src=\"icon/email.png\">\n\t<img style=\"height: 16px;\" title=\"email\" alt=\"email\" src=\"fig/",
						     "phone" => " <img style=\"width: 16px; height: 16px;\" title=\"phone\" alt=\"phone\" src=\"icon/phone.png\">",
						     "mobile" => " <img style=\"width: 16px; height: 16px;\" title=\"mobile\" alt=\"mobile\" src=\"icon/mobile.png\">",
					         "office" => " <img style=\"width: 16px; height: 16px;\" title=\"office\" alt=\"office\" src=\"icon/office.png\"> ",
						     "webpage" => "  <a title=\"Webpage\" href=\"",
					         "facebook" => " <a title=\"Facebook\" href=\"",
						     "twitter" => " <a title=\"Twitter\" href=\"https://www.twitter.com/",
						     "blog" => " <a title=\"Blog\" href=\"",
					         "research" => " <img style=\"width: 16px; height: 16px;\" title=\"email\" alt=\"email\" src=\"icon/research.png\">",
					         "courses" => " <img style=\"width: 16px; height: 16px;\" title=\"email\" alt=\"email\" src=\"icon/courses.png\">",
					         "list_of_courses_assigned" => "<b>Courses assigned:</b>\n<ul>\n",
					         "other_courses_he_may_teach" => "<b>Other courses he/she can teach:</b>\n<ul>\n"
	);
	%{$Common::config{faculty_icons}{after}}  = ("shortcvhtml" => "\t</ul>",
						     "email" => "",
						     "emailwithoutat" => ".png\">",
						     "phone" => "<br>",
						     "mobile" => "",
						     "office" => "<br>",
					         "webpage"  => "\"> <img style=\"width: 16px; height: 16px;\" title=\"webpage\" alt=\"webpage\" src=\"icon/webpage.png\">Webpage</a> ",
					         "facebook" => "\"> <img style=\"width: 16px; height: 16px;\" title=\"facebook\" alt=\"facebook\" src=\"icon/facebook.png\"></a> ",
						     "twitter" => "\"> <img style=\"width: 16px; height: 16px;\" title=\"twitter\" alt=\"twitter\" src=\"icon/twitter.png\"></a> ",
						     "blog" => "\"> <img style=\"width: 16px; height: 16px;\" title=\"blog\" alt=\"blog\" src=\"icon/blog.png\"></a> ",
					             "research" => "",
					             "courses" => "",
					             "list_of_courses_assigned" => "</ul>\n",
					             "other_courses_he_may_teach" => "</ul>\n"
	);

	my $faculty_tpl_file 		= Common::GetTemplate("faculty-template.html");

	$Common::config{faculty_tpl_txt}= Util::read_file($faculty_tpl_file);

	$Common::config{InFacultyPhotosDir} 	= Common::GetExpandedTemplateWithLang("InFacultyPhotosDir", $lang);
	$Common::config{InFacultyIconsDir}		= Common::GetExpandedTemplateWithLang("InFacultyIconsDir", $lang);
	$Common::config{NoFaceFile}				= Common::GetTemplate("NoFace-file");
	$Common::config{OutputFacultyDir} 		= Common::GetTemplate("OutputFacultyDir");

	#my $faculty_output_general_txt 	= "<table style=\"width: 600px;\" border=\"0\" align=\"center\">\n";
	my $faculty_output_general_txt 	= "\n";
	my $faculty_general_output 	= Common::GetTemplate("faculty-general-output-html");
	my $email = "";
	Util::print_message("Generating faculty file: $faculty_general_output  ...");

	# 1st verify if all professors have concentration ...
	my $count_of_errors = 0;
	my $concentration_rank = 100;
	foreach $email (keys %{$Common::config{faculty}})
	{
	      my $concentration = $Common::config{faculty}{$email}{concentration};
	      if($concentration eq "" or not defined($Common::config{sort_areas}{$concentration}) )
	      {		Util::print_warning("Professor $email:  I do not recognize this concentration area (\"$concentration\") ...");
			$count_of_errors++;
			$Common::config{faculty}{$email}{concentration_rank} 	= $concentration_rank;
			$Common::config{sort_areas}{$concentration} 		= $concentration_rank++;
	      }
	      else{
			$Common::config{faculty}{$email}{concentration_rank} = $Common::config{sort_areas}{$concentration};
	      }
	}

	if($count_of_errors > 0)
	{	Util::print_warning("Some professors ($count_of_errors in total) have not concentration area or have invalid ones ...");		}

	# 2nd sort them by areas, degreelevel, name
	my @faculty_sorted_by_priority = sort {  ($Common::config{faculty}{$a}{concentration_rank} <=> $Common::config{faculty}{$b}{concentration_rank}) ||
			     ($Common::config{faculty}{$b}{fields}{degreelevel} <=> $Common::config{faculty}{$a}{fields}{degreelevel}) ||
			     ($Common::config{faculty}{$a}{fields}{name} cmp $Common::config{faculty}{$b}{fields}{name})
			  } keys %{$Common::config{faculty}};
	my $concentration 		= "";
	my $degreelevel;

	# 3rd Generate information for each professor
	my $OutputFacultyIconDir = Common::GetTemplate("OutputFacultyIconDir");
	system("cp $Common::config{InFacultyIconsDir}/*.png $OutputFacultyIconDir");
	foreach $email ( @faculty_sorted_by_priority )
	{
	    my $this_professor = generate_information_4_professor($email, $lang);
	    if( scalar (keys %{$Common::config{faculty}{$email}{fields}{courses_assigned}}) > 0 )
	    {	      $faculty_output_general_txt .= $this_professor;		}
	}

	# 4th Generate information for the main index of professors by area, etc
# 	push(@{$Common::config{faculty_groups}{$concentration}{$degreelevel}}, $email);

# my @faculty_sorted_by_priority = sort {  ($Common::config{sort_areas}{$Common::config{faculty}{$a}{concentration}} <=> $Common::config{sort_areas}{$Common::config{faculty}{$b}{concentration}}) ||
# 			     ($Common::config{faculty}{$b}{fields}{degreelevel} <=> $Common::config{faculty}{$a}{fields}{degreelevel}) ||
# 			     ($Common::config{faculty}{$a}{fields}{name} cmp $Common::config{faculty}{$b}{fields}{name})
# 			  } keys %{$Common::config{faculty}};

# 	print Dumper (\%{$Common::config{faculty_groups}});
	foreach $concentration (keys %{$Common::config{faculty_groups}})
	{
	      if(not defined($Common::config{sort_areas}{$concentration}) )
	      {		Util::print_warning("Concentration area \"$concentration\" not defined ...");		}
	}

	my $index_of_professors = "<table border=\"1\" align=\"center\">\n";
	foreach $concentration (sort {$Common::config{sort_areas}{$a} <=> $Common::config{sort_areas}{$b}} keys %{$Common::config{faculty_groups}})
 	{	$index_of_professors .= "<th>$concentration</th>\n";		}

	$index_of_professors .= "<tr>\n";
 	foreach $concentration (sort {$Common::config{sort_areas}{$a} <=> $Common::config{sort_areas}{$b}} keys %{$Common::config{faculty_groups}})
 	{
		$index_of_professors .= "<td>\n";
		foreach $degreelevel ( sort {$b <=> $a} keys %{$Common::config{faculty_groups}{$concentration}} )
		{
			my $count = 0;
			my $this_group_txt = "";
			foreach $email ( @{$Common::config{faculty_groups}{$concentration}{$degreelevel}} )
			{
				if( scalar (keys %{$Common::config{faculty}{$email}{fields}{courses_assigned}}) > 0 )
				{
					$this_group_txt .= "<li>";
					$this_group_txt .= "<a href=\"#$Common::config{faculty}{$email}{fields}{emailwithoutat}\">";
					$this_group_txt .= "$Common::config{faculty}{$email}{fields}{prefix} $Common::config{faculty}{$email}{fields}{name}";
					$this_group_txt .= "</a>";
					$this_group_txt .= "</li>\n";
					$count++;
				}
			}
			if( $count > 0 )
			{
				$index_of_professors .= "<ul>\n";
				$index_of_professors .= $this_group_txt;
				$index_of_professors .= "</ul>\n";
			}
		}
		#$Common::config{faculty}{$email}{fields}{anchor}
		$index_of_professors .= "</td>\n";
 	}
 	$index_of_professors .= "</tr>\n";
 	$index_of_professors .= "</table>\n";

	Util::print_message("Generating file: $faculty_general_output ...");
	#$faculty_output_general_txt 	.= "</table>\n";
	$faculty_output_general_txt 	.= "\n";
	my $html_output  = "<h2 id=\"top\"></h2>";
	   $html_output .= "$index_of_professors\n";
	   $html_output .= "$faculty_output_general_txt";

	$html_output = special_chars_to_html($html_output);

	Util::write_file($faculty_general_output, $html_output);
	Util::check_point("generate_faculty_info");
	Util::print_message("generate_faculty_info OK! ...");
}

sub detect_link_for_courses()
{
	my $html_index 	= Common::GetTemplate("output-curricula-html-file");
	if( not -e $html_index )
	{		Util::print_error("File $html_index does not exist ! ... Run latex2html first ... ");
	}
	Util::print_message("Reading $html_index");
	my $html_file_input 	= Util::read_file($html_index);

	for(my $semester= 1; $semester <= $Common::config{n_semesters} ; $semester++)
	{
		Util::print_message("Sem: $semester");
		foreach my $codcour (@{$Common::courses_by_semester{$semester}})
		{
			$codcour = unmask_codcour($codcour);
			my $courselabel = $codcour;
			my $link = "";
			#   <A NAME="tex2html315" HREF="4_1_CS105_Estructuras_Discr.html"><SPAN CLASS="arabic">4</SPAN>.<SPAN CLASS="arabic">1</SPAN> CS105. Estructuras Discretas I (Obligatorio)</A>

			$Common::course_info{$codcour}{link} = "";
			# 		  <A NAME="tex2html972"
			#   		HREF="5_65_CS3P2_Cloud_Computing_.html"><SPAN CLASS="arabic">5</SPAN>.<SPAN CLASS="arabic">65</SPAN> CS3P2. Cloud Computing (Obligatorio)</A>
			#print Dumper(\$Common::course_info{$codcour}{$Common::config{language_without_accents}}{course_name});
			my $course_type = $Common::config{dictionary}{$Common::course_info{$codcour}{course_type}};
			my $coursefullname = "$courselabel. $Common::course_info{$codcour}{$Common::config{language_without_accents}}{course_name} ($course_type)";
			printf("Searching link for: %-s ", $coursefullname);
			my $html_file = $html_file_input;
			if( $html_file =~ m/HREF="(.*?$courselabel.*?html)">/g)
			{
				$Common::course_info{$codcour}{link} = $link = $1;
				Util::print_success("$link");
				# Util::print_message("codcour=$codcour ($Common::config{dictionary}{$Common::course_info{$codcour}{course_type}}), link = $link");
			}
			else
			{
				Util::print_error("Not found ($Common::course_info{$codcour}{semester} Sem) ... ");
			}
			#print "\n";
		}
	}
	print "\n";
	Util::check_point("detect_link_for_courses")
}

sub update_dot_links()
{
	my $OutputDotDir = Common::GetTemplate("OutputDotDir");
	Util::print_message("Updating dot files @ $OutputDotDir ...");
	foreach my $file (<$OutputDotDir/*.dot>)
	{
		print "Updating $file ...";
		my $file_txt = Util::read_file($file);
		while( $file_txt =~ m/\"URL(.*?)\"/ )
		{
			my $codcour = $1;
			my $link = $Common::course_info{$codcour}{link};
			$file_txt =~ s/\"URL$codcour\"/\"\.\.\/$link\"/g;
		}
		Util::write_file($file, $file_txt);
		Util::print_success(" ok!");
	}
}

sub update_svg($$)
{
	my ($svg_file, $output_file) = (@_);
	Util::print_message("$Util::icons{ok} Updating ".Util::highlight_filename($svg_file)." ... ");
	my ($width, $height, $count_svg) = ("", "", 0);
	my $svg_txt = Util::read_file($svg_file);
	if ($svg_txt =~ m/<svg\s*width="(.*?)"\s*height="(.*?)"/g )
	{	($width, $height) = ($1, $2);
		#print("width=$width, height=$height -> $output_file");
		$count_svg = $svg_txt =~ s/<svg\s*width=\".*?\"\s*height=\".*?\"/<svg /g;
	}
	my $count_links = $svg_txt =~ s/(<a xlink:href=".*?\.html") (xlink:title=".*?">)/$1 target="_parent" $2>/g;
	#Util::print_color("ok! ($count_svg)");
	Util::write_file($output_file, $svg_txt);
	return ($width, $height);
}

sub add_size_to_svg_link($$$$)
{
	my ($file, $html_file, $width, $height) = (@_);				
	my $html_txt 	= Util::read_file($html_file);
	$html_txt 	    =~ s/$file.svg" width="<WIDTH>" height="<HEIGHT>">/$file.svg" width="$width" height="$height">/g;
	Util::write_file($html_file, $html_txt);
	Util::print_message("$Util::icons{ok} Updating ".Util::highlight_filename($html_file)." ...");
}

sub update_svg_links($)
{
	my ($lang) = (@_);
	my $lang_prefix			= $Common::config{dictionaries}{$lang}{lang_prefix};
	my $OutputHtmlDir 		= Common::GetTemplate("OutputHtmlDir");
	my $OutputFigsDir 		= Common::GetTemplate("OutputFigsDir");
	my $OutputHtmlFigsDir 	= Common::GetTemplate("OutputHtmlFigsDir");
	Util::print_message("Updating svg links files @ $OutputHtmlDir ...");
	for(my $semester= 1; $semester <= $Common::config{n_semesters} ; $semester++)
	{
		foreach my $codcour (@{$Common::courses_by_semester{$semester}})
		{
			my $svg_file        = "$OutputFigsDir/$codcour.svg";
			my $svg_output_file = "$OutputHtmlFigsDir/$codcour.svg";
			my ($width, $height) = update_svg($svg_file, $svg_output_file);
			if(not $width eq "" && not $height eq "")
			{
				my $html_file 	= "$OutputHtmlDir/$Common::course_info{$codcour}{link}";
				add_size_to_svg_link($codcour, $html_file, $width, $height);
			}
			else{
				Util::print_success("No match!");
			}
			#else{	Util::print_error("SVG missing ($svg_file)");	}
		}
	}
	foreach my $size ("small", "big")
	{
		my $input_svg_file  = "$OutputFigsDir/$size-graph-curricula-$lang_prefix.svg";
		my $output_svg_file = "$OutputHtmlFigsDir/$size-graph-curricula-$lang_prefix.svg";
		my ($width, $height) = update_svg($input_svg_file, $output_svg_file);
	}
}

my %LU_info = ();
my $replacements    = "";
sub format_IS_body($@)
{
	my ($env, @list) = (@_);
 	#print "Env = $env\n";
	my $out_txt = "";
	$out_txt .= "\\begin{$env}\n";
	my $count = 0;
	foreach my $item (@list)
	{
		if($item =~ m/-(.*)/)
		{
			$out_txt .= "\\item $1\n";
			$count++;
		}
		else
		{	if($item =~ m/^\s*$/)
			{		}
			else
			{	Util::print_message(Util::red("Line out of format")." \"$item\"\n");	}
		}
	}
	$out_txt .= "\\end{$env}\n";
	if($count > 0)
	{	return ($out_txt, $count);	}
	return ("", 0);
}

sub generate_IS_LU($$$)
{
	my ($in_file, $out_file, $lang) = (@_);
	Util::print_message("Reading $in_file ...");
	my $fulltxt = Util::read_file($in_file);
	$fulltxt =~ s/\n\n/\n/g;
	
	my $out_txt = "";
	$out_txt    = "% File generated by generate_IS_LU ... do not modify manually !!!\n";
	my $count   = 0;
	#                    \begin {LU4}     {Tec...}{Turban2005ITforManagement}{}
	my $ka 		= "LU";
	my $KUPos 	= 0;
	while($fulltxt =~ m/\\begin\{LU(.*?)\}(.*?)\{(.*?)\}\{(.*?)\}\{(.*?)\}\s*((?:.|\n)*?)\\end\{LU\}/g)
	{
		my $unit_number  = $1;
		my $subsection   = $2;
		my $unit_title   = $3;
		my $unit_bib     = $4;
		my $unit_others  = $5;
		my $body 	     = $6;
		my $ku  		 = "$ka$unit_number";
		my $sec_label    = "sec:BOK-$ka$unit_number";

		#Util::print_message("LU$unit_number, $unit_title, $unit_bib");
		my ($goal_body, $obj_body) = ("", "");
		my (@goal_v   , @obj_v) = ((), ());
		my $prefix = "";
		if($subsection =~ m/\[(.*?)\]/)
		{	$prefix = "sub";	}
		$unit_title = $Common::config{dictionary}{UnitNotDefined} if($unit_title eq "");
		$out_txt .= "\\$prefix"."subsection{LU$unit_number. $unit_title}\\label{$sec_label}";
		#$out_txt .= "\\$prefix"."subsection*{\\thesubsection~$unit_title (Unidad de Aprendizaje \\\#$unit_number)}";
		$out_txt .= "\\label{sec:LU$unit_number}\n";
		#$out_txt .= "\\addtocounter{subsection}{1}\n";
		
		# Processing goals ...
		if($body =~ m/\\begin\{goal\}\s*((?:.|\n)*?)\\end\{goal\}/)
		{	#print "$1\n"; 
			@goal_v    = split(/\n/, $1); 	
		}
		else{		Util::print_message("UN = $unit_number there is something wrong in {goal} environment ...\n");	}
		
		my ($goals_tex, $ngoals) = format_IS_body("LUGoal", @goal_v);

		#print "$goals_tex\n"; 
		$LU_info{$unit_number}{LUGoal} = $goals_tex;
		
		# Processing objectives ...
		if($body =~ m/\\begin\{objectives\}\s*((?:.|\n)*?)\\end\{objectives\}/)
		{	#print "$1\n"; 
			@obj_v    = split(/\n/, $1);		
		}
		else{		Util::print_message("UN = $unit_number there is something wrong in {objectives} environment\n");	}
		my ($obj_tex, $nobj) = format_IS_body("LUObjective", @obj_v);
		#print "$obj_tex\n"; 
		$LU_info{$unit_number}{LUObjective} = $obj_tex;
		
		if( ($ngoals+$nobj) > 0)
		{
		      $out_txt .= "\\begin{LearningUnit}\n";
		      $out_txt .= "$goals_tex\n";
		      $out_txt .= "$obj_tex";	
		      $out_txt .= "\\end{LearningUnit}\n\n";
		}
		$count++;
		$bok{$lang}{$ka}{KU}{$ku}{name}  		= $unit_title;
		$bok{$lang}{$ka}{KU}{$ku}{description}	= "";
		$bok{$lang}{$ka}{KU}{$ku}{order} 		= $KUPos++;
		$ku_info{$lang}{$ku}{ka} 				= $ka;

		$Common::config{ref}{$ku} = $sec_label;
		my $ku_with_letters = Common::change_number_by_text($ku)."Def";
		$Common::config{ref}{$ku_with_letters} = $sec_label;
		# $out_txt .= "\n\n\\subsection{$ka$topic_number. $topic_name}\\label{$sec_label}\n";
	}

	Util::write_file($out_file, $out_txt);
	Util::check_point("generate_IS_LU");
	Util::print_message("generate_IS_LU ($in_file => $out_file) ($count LU processed) (ready for Chapter BOK!) OK!");
}

sub generate_IS_LU_macros($$$)
{
	my ($in_file, $out_file, $lang) = (@_);
	Util::precondition("generate_IS_LU");
	my $fulltxt = Util::read_file($in_file);
	$fulltxt =~ s/\n\n/\n/g;
	my $out_txt = "";
	
	while($fulltxt =~ m/\\begin\{LU(.*?)\}(.*?)\{(.*?)\}\{(.*?)\}\{(.*?)\}\s*((?:.|\n)*?)\\end\{LU\}/g)
	{
		my ($unit_number, $subunit_number)  = ($1,$2);
		#Util::print_message("LU$unit_number       \r");
		my $unit_title   = $3;
		my $unit_bib     = $4;
		my $unit_hours   = $5;
		my $newunit = Common::change_number_by_text($unit_number);

		my $prefix = "LU$newunit";
		$prefix =~ s/\./x/g;
		my $ku = "$prefix"."Def";
		$out_txt .= "\\newcommand{\\$ku}{LU$unit_number $unit_title}\n";
		$Common::config{topics_priority}{$ku} = $Common::config{topics_priority_counter}++;

		#Util::print_message("$prefix"."Def");
		$replacements .=  "LU".$newunit."Name=>LU".$newunit."Def\n";

# 		print "LU$newunit"."Name\n";;
		$unit_bib =~ s/ //g;
		$unit_bib = "I do not find bib-item in $in_file" if($unit_bib eq "");
		$out_txt .= "\\newcommand{\\$prefix"."Bib}{$unit_bib}\n";
		$out_txt .= "\\newcommand{\\$prefix"."Hours}{$unit_hours}\n\n";
		$out_txt .= "\\newcommand{\\$prefix"."Goal}{%\n";
		$out_txt .= "$LU_info{$unit_number}{LUGoal}";
		$out_txt .= "$LU_info{$unit_number}{LUObjective}}\n\n";

		$Common::ku_info{$lang}{$ku}{ka} 	= "LU";
		$bok{$lang}{LU}{KU}{$ku}{name}		= $unit_title;
		# # ! Pending Er (qui!)
	}
	Util::write_file($out_file, $out_txt);
	Util::check_point("generate_IS_LU_macros");
	Util::print_message("generate_IS_LU_macros OK!( $in_file => $out_file) OK!");
}

sub process_IS_topics($)
{
	my ($txt) = (@_);
	my $out_txt 	  = "";
	my @lines = split "\n", $txt;
	my $count = 0;
	foreach my $line (@lines)
	{
		if($line =~ m/^-(.*)/)
		{
			$lines[$count] = "\\item $1";
		}
		$count++;
	}
	
	return join("\n", @lines);
}

sub generate_IS_BOK($$$)
{
	my ($in_file, $out_file, $lang) = (@_);
	my $fulltxt = Util::read_file($in_file);
	Util::print_message("Reading $in_file ..."); 	
 	$fulltxt =~ s/\n\n/\n/g;
	# Pending Er !
	#$fulltxt = Common::replace_accents($fulltxt);
	#@contents = split("\n", $fulltxt);
	my $out_txt  = "";
	#					 \begin  {BKL2}  {TDS            13    } {Tecnologías Emergentes}
	my $KUPos = 0;
	while($fulltxt =~ m/\\begin\{BKL2\}\{(.*?)(\d*)\}\{(.*?)\}\s*((?:.|\n)*?)\\end\{BKL2\}/g)
	{
		my $ka   		 = $1;
		my $topic_number = $2;
		my $topic_name   = $3;
		my $topic_body   = $4;
		my $ku 			 = "$ka$topic_number";
		
		#Util::print_message(Util::yellow("ka=")." $ka, ".Util::yellow("topic_number=")." $topic_number, ".Util::yellow("topic_name=")." $topic_name");
		#Util::print_message("ka = $ka, topic_number=$topic_number, topic_name = $topic_name, topic_body=$topic_body");
		$topic_body = process_IS_topics($topic_body);
		#Util::print_color("topic_body");
		
		my $topic_env = "boktopic";
		$topic_body =~ s/\(begin_topics\)/\\begin{$topic_env}/g;
		$topic_body =~ s/\(end_topics\)/\\end{$topic_env}/g;
		
		$topic_env = "boksubtopic";
		$topic_body =~ s/\(begin_subtopics\)/\\begin{$topic_env}/g;
		$topic_body =~ s/\(end_subtopics\)/\\end{$topic_env}/g;
		$topic_body =~ s/\(begin_goals\)\s*((?:.|\n)*?)\(end_goals\)\s*\n*?//g;
		#Util::print_message("$topic_body");
		while($topic_body =~ m/\\begin\{$topic_env\}\s*((?:.|\n)*?)\\end\{$topic_env\}/g)
		{
			my $subtopic_body = $1;
			my $count = 0;
			while($subtopic_body =~ m/\\item /g)
			{
				$count++;
			}
			if($count == 0)
			{
				$topic_body =~ s/\\begin\{$topic_env\}\s*$subtopic_body\\end\{$topic_env\}//g;
			}
		}
		
		$topic_body =~ s/\(inicio_objetivo\)//g;
		$topic_body =~ s/\(fin_objetivo\)//g;

		my $sec_label = "sec:BOK-$ka$topic_number";
		$Common::config{ref}{$ku} = $sec_label;
		$out_txt .= "\n\n\\subsection{$ka$topic_number. $topic_name}\\label{$sec_label}\n";
		$bok{$lang}{$ka}{KU}{$ku}{name}  		= $topic_name;
		$bok{$lang}{$ka}{KU}{$ku}{description}	= "";
		$bok{$lang}{$ka}{KU}{$ku}{order} 		= $KUPos++;
		
		$ku_info{$lang}{$ku}{ka} 				= $ka;
		$out_txt .= $topic_body;
	}
	Util::print_message("generate_IS_BOK OK!( $in_file => $out_file) OK! (ready for Chapter BOK!)");
	Util::write_file($out_file, $out_txt);
}

sub generate_IS_BOK_macros($$$)
{
	my ($in_file, $out_file, $lang) = (@_);
	my $fulltxt = Util::read_file($in_file);
	$fulltxt =~ s/\n\n/\n/g;

	my @contents = split(/\n/, $fulltxt);
	my $out_txt  = "";
	my $level    = 0;
	my @prefix   = (0, 0, 0, 0, 0);
	my ($BLK1, $BLK2, $BLK3, $BLK4) = (1, 2, 3, 4);
	my $curr_area = "";
	my $current_BOKArea = "";
	my $current_topic   = "";
	foreach my $linea (@contents)
	{
		# if($linea =~ m/\\begin\{BKL2\}\{(.*?)(\d+)\}\{(.*?)\}/g)
		#		        \begin {BKL2 } {TDS      13} {Tecnologías Emergentes}
		if($linea =~ m/\\begin\{BKL2\}\{(.*?)(\d*)\}\{(.*?)\}\s*((?:.|\n)*?)\\end\{BKL2\}/g)
		{
			my $ka 			= $1;
			my $topic_code  = $2;
			my $topic_name  = $3;
			#Util::print_message(sprintf("topic_code = %3s, topic_name = %s", $topic_code, $topic_name));

			$prefix[$BLK2] = $topic_code;
			$prefix[$BLK3] = 0;
			# It is a new area
			if(not $ka eq $curr_area)
			{
				$curr_area = $ka;
				$prefix[$BLK1]++;
			}
			if(not $current_BOKArea eq $ka)
			{
				$current_BOKArea = $ka;
				#Util::print_message("ka=$ka");
				if( defined($Common::config{dictionaries}{$lang}{ISBOKAreas}{$ka}) )
				{	my $ka = $ka."BOKArea";
					$out_txt .= "\n";
					$out_txt .= "\\newcommand{\\$ka}{";
					$out_txt .= $Common::config{dictionaries}{$lang}{ISBOKAreas}{$ka};
					$out_txt .= "}\n";
					$Common::config{topics_priority}{$ka} = $Common::config{topics_priority_counter}++;
				}
				else
				{	Util::halt("It seems you did not defined prefix \"$ka\" ... see file $in_file");	}
				my $kaDescription = $ka."Description";
				#$out_txt .= "\\newcommand{\\$kaDescription}{}\n\n";
				$Common::config{topics_priority}{$kaDescription} = $Common::config{topics_priority_counter}++;
			}
			$level = 2;
			$current_topic  = "$ka$topic_code";
		}
		elsif($linea =~ m/\(begin_topics\)/){	$level++;	}
		elsif($linea =~ m/\(end_topics\)/){	$level--;	}
		elsif($linea =~ m/\(begin_subtopics\)/)
		{	
			$prefix[$BLK4] = 0;
			$level++;
		}
		elsif($linea =~ m/\(end_subtopics\)/){	$level--;	}
		elsif($linea =~ m/^-(.*)/)
		{
			my $item = $1;
			$prefix[$level]++;
			my $label = "$prefix[$BLK1].$prefix[$BLK2]";
			if($level >= 3)
			{	$label .= ".$prefix[$BLK3]";
				if($level >= 4) {	$label .= ".$prefix[$BLK4]";	}
			}
			#$out_txt .= "\n";
			my $old_command = "$current_topic"."Topic$label";
			my $new_command    = Common::change_number_by_text($old_command);
			$new_command =~ s/\./x/g;
			my $this_replacement = "$old_command=>$new_command";
			#$out_txt .= "\% rep: $this_replacement\n";
			$out_txt .= "\\newcommand{\\$new_command}{$item} \%level = $level, prefix[level] = $label\n";
			$Common::config{topics_priority}{$new_command} = $Common::config{topics_priority_counter}++;
			$replacements  .= "$this_replacement\n";
		}
# 		$topic_body =~ s/\(inicio_objetivo\)//g;
# 		$topic_body =~ s/\(fin_objetivo\)//g;
	}
	$replacements  .= "\n";
	Util::write_file($out_file, $out_txt);
	Util::print_message("generate_IS_BOK_macros( $in_file => $out_file) OK!");
}

sub process_IS_BOK($)
{
	my ($lang) = (@_);
	my $OutputTexDir = Common::GetTemplate("OutputTexDir");

	my $LU_unprocessed_file = Common::GetExpandedTemplateWithLang("InTexDir", $lang)."/learning-units.tex";
	my $bok_in_file 		= Common::GetExpandedTemplateWithLang("InTexDir", $lang)."/IS-bok-in.tex";
	#$Common::config{topics_priority}{$ku} = $Common::config{topics_priority_counter}++;
	generate_IS_BOK       ($bok_in_file, "$OutputTexDir/IS-bok.tex", $lang);
	generate_IS_BOK_macros($bok_in_file, Common::GetExpandedTemplateWithLang("InStyDir", $lang)."/bok-macros.sty", $lang);
	
	generate_IS_LU		  ($LU_unprocessed_file, Common::GetExpandedTemplateWithLang("InTexDir", $lang)."/LU.tex", $lang);
	generate_IS_LU_macros ($LU_unprocessed_file, Common::GetExpandedTemplateWithLang("InStyDir", $lang)."/LU-macros.sty", $lang);

	my $replacements_file = Common::GetExpandedTemplateWithLang("in-replacements-file", $lang);
	Util::print_message("Generating: $replacements_file ... OK!");
    Util::write_file($replacements_file, $replacements);
	Util::check_point("gen_bok");
}

sub generate_bok($)
{
	my ($lang) = (@_);
	$Common::config{topics_priority_counter} = 0;
	if($config{area} eq "CS" or $config{area} eq "DS" )
	{
		Common::parse_bok_from_raw_text($lang);
		Common::gen_bok($lang);
	}
	elsif($config{area} eq "IS")
	{
		# process_IS_BOK($lang);
	}
	else
	{
		my $bok_in_file = Common::GetExpandedTemplateWithLang("in-bok-macros-V0-file", $lang);
		if( -e $bok_in_file )
		{	Util::print_error("generate_bok($lang): I found the file: ($bok_in_file) but there is no instructions to process it ...");		}
		else
		{	Util::print_error("generate_bok($lang): I have not BOK for $config{area} ($bok_in_file) ...");	}
	}
}

sub dump_dictionary_errors()
{
	my $output_txt = "Dictionaries (Missing keys)\n";
	foreach my $lang (@{$config{SyllabusLangsList}})
	{
		$output_txt .= "$lang\n";
		my $count = 0;
		foreach my $key (keys %{$config{dictionaries}{terms}})
		{
			if( not defined($config{dictionaries}{$lang}{$key}) )
			{
				$output_txt .= sprintf("\t%-15s\n", $key);
				$count++;
			}
		}
		if( $count == 0 )
		{	$output_txt .= "\tThis language is complete !\n";	}
	}
	$output_txt .= "\n";
	return $output_txt;
}

sub dump_outcomes_errors_log()
{
	#foreach my $key (keys %outcomes_macros)
	#	{	$Common::config{outcomes_keys}{$key} = "";	}
	#	@{$Common::config{macros}{$lang}}{keys %outcomes_macros} = values %outcomes_macros;
	my $output_txt 			= "";
	foreach my $lang (@{$config{SyllabusLangsList}})
	{
		my $program_info_file   = Common::GetExpandedTemplateWithLang("this-program-info-file", $lang);
		my $outcomes_macros_file = Common::GetExpandedTemplateWithLang("in-outcomes-macros-file", $lang);
		$output_txt .= "Outcomes (Missing keys) cited in $program_info_file (\\OutcomesList)\n";
		$output_txt .= "$lang ($outcomes_macros_file)\n";
		my $count = 0;
		foreach my $key (sort {$a cmp $b} keys %{$Common::config{outcomes_keys}})
		{
			if( not defined($Common::config{macros}{outcomes}{$lang}{$key}) )
			{
				$output_txt .= sprintf("\t%-15s\n", $key);
				$count++;
			}
		}
		if( $count == 0 )
		{	$output_txt .= "\tThis language is complete !\n";	}
	}
	$output_txt .= "\n";

	$output_txt .= "Outcomes, Competencies, Specificoutcomes cited in courses ".Util::yellow("but not defined !")."\n";
	foreach my $lang (@{$config{SyllabusLangsList}})
	{	my $outcomes_macros_file = Common::GetExpandedTemplateWithLang("in-outcomes-macros-file", $lang);
		$output_txt .= sprintf("%-10s (%s)\n", Util::yellow($lang), $outcomes_macros_file);
		#if( not defined($Common::config{macros}{$env}{$lang}{"$env$key"}) )
		#{	push(@{$Common::error{outcomes_and_competencies}{$lang}{$env}{$key}}, $codcour);	}
		foreach my $env (sort {$a cmp $b} keys %{$Common::error{outcomes_and_competencies}{$lang}})
		{	$output_txt .= "\t".Util::yellow($env)."\n";
			foreach  my $key (sort {$a cmp $b} keys %{$Common::error{outcomes_and_competencies}{$lang}{$env}})
			{	# $output_txt .= sprintf("\t%-15s: (%s)\n", $env, join(", ", @{$Common::error{outcomes_and_competencies}{$lang}{$env}})) ;
				my ($list_of_courses, $sep, $count) = ("", "", 0);
				foreach  my $codcour ( @{$Common::error{outcomes_and_competencies}{$lang}{$env}{$key}})
				{	$list_of_courses .= "$sep$codcour";		$sep = ","; 	$count++;
				}
				$output_txt .= sprintf("\t\t%-5s(%d %s): %s\n", Util::yellow($key), $count, $config{dictionaries}{$lang}{Courses}, $list_of_courses);
			}
		}
	}
	
	$output_txt .= "\n";
	return $output_txt;
}

sub dump_outcomes_errors_markdown()
{
	#foreach my $key (keys %outcomes_macros)
	#	{	$Common::config{outcomes_keys}{$key} = "";	}
	#	@{$Common::config{macros}{$lang}}{keys %outcomes_macros} = values %outcomes_macros;
	my $output_txt 			= "## Errors detected in Outcomes\n";
	foreach my $lang (@{$config{SyllabusLangsList}})
	{
		my $program_info_file   = Common::GetExpandedTemplateWithLang("this-program-info-file", $lang);
		my $outcomes_macros_file = Common::GetExpandedTemplateWithLang("in-outcomes-macros-file", $lang);
		$output_txt .= "Outcomes (Missing keys) cited in $program_info_file (\\OutcomesList)\n";
		$output_txt .= "- $lang ($outcomes_macros_file)\n";
		my $count = 0;
		foreach my $key (sort {$a cmp $b} keys %{$Common::config{outcomes_keys}})
		{
			if( not defined($Common::config{macros}{outcomes}{$lang}{$key}) )
			{
				$output_txt .= sprintf("  - %-15s\n", $key);
				$count++;
			}
		}
		if( $count == 0 )
		{	$output_txt .= "    - ** This language is complete !**";	}
		$output_txt .= "\n\n";
	}
	$output_txt .= "\n";

	$output_txt .= "### Outcomes, Competencies, Specificoutcomes cited in courses **but not defined !**\n";
	foreach my $lang (@{$config{SyllabusLangsList}})
	{	$output_txt .= sprintf("- %-10s\n", $lang);
		#if( not defined($Common::config{macros}{$env}{$lang}{"$env$key"}) )
		#{	push(@{$Common::error{outcomes_and_competencies}{$lang}{$env}{$key}}, $codcour);	}
		my $count = 0;
		foreach my $env (sort {$a cmp $b} keys %{$Common::error{outcomes_and_competencies}{$lang}})
		{	$output_txt .= "  - $env\n";
			foreach  my $key (sort {$a cmp $b} keys %{$Common::error{outcomes_and_competencies}{$lang}{$env}})
			{	# $output_txt .= sprintf("\t%-15s: (%s)\n", $env, join(", ", @{$Common::error{outcomes_and_competencies}{$lang}{$env}})) ;
				my ($list_of_courses, $sep, $courses_count) = ("", "", 0);
				foreach  my $codcour ( @{$Common::error{outcomes_and_competencies}{$lang}{$env}{$key}})
				{	$list_of_courses .= "$sep$codcour";		$sep = ","; 	$courses_count++;
				}
				my $Courses = ($courses_count == 1 ? $config{dictionaries}{$lang}{Course} : $config{dictionaries}{$lang}{Courses});
				$output_txt .= sprintf("    - %-5s(%d %s): %s\n", $key, $courses_count, $Courses, $list_of_courses);
				$count += $courses_count;
			}
		}
		if( $count == 0 )
		{	$output_txt .= sprintf("  - Everything is well defined\n");	}
	}
	$output_txt .= "\n";
	return $output_txt;
}

sub dump_course_errors()
{
	my $output_txt = "## Errors detected in courses\n";
	foreach my $codcour (@codcour_list_sorted)
	{
		$output_txt .= "- Course=$codcour\n";
		#$output_txt .= "\tfile=$Common::error{courses}{$codcour}{file}\n";
		if( defined($Common::error{courses}{$codcour}{lang}) )
		{	foreach my $lang (sort {$a cmp $b} keys %{$Common::error{courses}{$codcour}{lang}})
			{	
				$output_txt .= "  - $lang ($course_info{$codcour}{$lang}{course_name}) [Link to file for $codcour here]($config{GithubMasterDir}/$Common::error{courses}{$codcour}{lang}{$lang}{file})\n";
				if( defined($Common::error{courses}{$codcour}{lang}{$lang}) )
				{
					foreach my $env (sort {$a cmp $b} keys %{$Common::error{courses}{$codcour}{lang}{$lang}})
					{
						if(not $env eq "file")
						{	$output_txt .= ("  "x2)."- $env=$Common::error{courses}{$codcour}{lang}{$lang}{$env}\n";	}
					}
				}
			}
		}
		if( defined($Common::error{courses}{$codcour}{others}) )
		{	$output_txt .= "\tOthers\n";
			foreach my $key (sort {$a cmp $b} keys %{$Common::error{courses}{$codcour}{others}})
			{	
				$output_txt .= ("\t"x2)."$key=$Common::error{courses}{$codcour}{others}{$key}\n";
			}
		}
		# TODO Check
		#if( defined($Common::error{courses}{$codcour}{competencies}) )
		#{	$output_txt .= "\tCompetencies\n";
		#	foreach my $key (sort {$a cmp $b} keys %{$Common::error{courses}{$codcour}{competencies}})
		#	{	
		#		$output_txt .= ("\t"x2)."$key=$Common::error{courses}{$codcour}{competencies}{$key}\n";
		#	}
		#}
		$output_txt .= "\n";
	}
	return $output_txt;
}

sub dump_general_errors()
{
	my $output_txt = "General errors ...\n";
	my $count = 0;
	foreach my $key (@{$Common::error{general}})
	{
		$output_txt .= "$key\n";
		$count++;
	}
	if( $count == 0 )
	{	$output_txt .= "\t".Util::green("None")."\n";	}
	else{	$output_txt .= "\n";	}

	return $output_txt;
}

sub save_batch_to_generate_dot_maps()
{
	my $batch_txt 	 = "#!/bin/csh\n\n";
	$batch_txt 		.= $Common::config{"dots_to_be_generated"};
	my $batch_map_for_course_file = Common::GetTemplate("out-dot-maps-batch");
	Util::print_message("$Util::icons{ok} Generating $batch_map_for_course_file at save_batch_to_generate_dot_maps");
	Util::write_file($batch_map_for_course_file, $batch_txt);
	system("chmod 774 $batch_map_for_course_file");
}

sub dump_errors()
{
	my $output_txt = "";
	$output_txt .= dump_course_errors();
	$output_txt .= dump_dictionary_errors();
	$output_txt .= dump_outcomes_errors_markdown();
	$output_txt .= dump_general_errors();
	my $output_errors_file = GetTemplate("output-errors-markdown-file");
	Util::write_file($output_errors_file, $output_txt);
	Util::print_message("Dumped errors ! ".Util::green($output_errors_file));
}

sub process_courses()
{
	if( $config{params}{"read_courses"} )
    {
		parse_courses(); 
	#	print Dumper( \%{$course_info{CS111}} );
	# 	print Dumper(\%{$course_info{"MA102"}});
		sort_courses();
		filter_courses($config{language_without_accents});
		process_cycle_vars();
	}
	Util::check_point("process_courses");
}

sub print_closing_message()
{
	#print("$Util::icons{ok}" x 30);
	print "\x1b[44m".("*"x60)."\x1b[49m\n";
	print "\x1b[44m**                      ". "Finishing $Util::icons{ok}"."                      **\x1b[49m\n";
	print "\x1b[44m".("*"x60)."\x1b[49m\n";
}

sub print_initial_message()
{
	print "\x1b[44m***********************************************************************\x1b[49m\n";
	print "\x1b[44m**                     Curricula generator                           **\x1b[49m\n";
	print "\x1b[44m***********************************************************************\x1b[49m\n";
}

sub setup()
{
	print_initial_message();
	set_initial_configuration($Common::command);
	Util::read_timestamps();

	read_pagerefs();
	process_courses();

	#foreach my $file ('../Curricula.out/Peru/CS-UCSP/cycle/2020-I/Plan2016/tex/ET301-EN.tex',
	#				  '../Curricula.out/Peru/CS-UCSP/cycle/2020-I/Plan2016/tex/ID101-ES.tex' )
	#{
	#	Util::print_message("Verificando: ".Util::highlight_filename($file)." ..." );
	#   my $timestamp = get_timestamp($source_file);
	#	if( Util::has_changed($file, $timestamp) )
	#	{	Util::print_message("has changed !");		}
	#	else
	#	{	Util::print_message("has NOT changed !");		}
	#}
	#exit;
	$Common::config{parallel} 	= 0;
}

sub shutdown()
{
	dump_errors();
	print_closing_message();
	#my $output_errors_file = GetTemplate("output-errors-file");
	#system("cat \"$output_errors_file\"");
	
	#my $output_errors = Util::read_file($output_errors_file);
	#print "$output_errors\nabc";
	Util::store_timestamps();
}

1;
