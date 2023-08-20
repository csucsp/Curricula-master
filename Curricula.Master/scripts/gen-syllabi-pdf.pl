#!/usr/bin/perl -w

use strict;
use Lib::Common;
use Lib::GenSyllabi;
use Lib::GeneralInfo;
use Data::Dumper;
use Text::Balanced qw(extract_multiple extract_bracketed);
use File::Path 'rmtree';

my $filter;
if(defined($ARGV[0])) { $Common::command = shift or Util::halt("There is no command to process (i.e. COUNTRY-AREA-INST)");	}
if(defined($ARGV[0])) { $filter          = shift;	}
if(not defined($filter))
{   $filter="all";  }

sub gen_batch_to_compile_syllabi_old($)
{
	my ($lang) = (@_);
	Util::precondition("set_global_variables");
 	Util::print_message("gen_batch_to_compile_syllabi starting ...");
	my $out_gen_syllabi = Common::GetTemplate("out-gen-syllabi.sh-file");

	my $output = "";
	#$output .= "rm *.ps *.pdf *.log *.dvi *.aux *.bbl *.blg *.toc\n\n";
	$output .= "#!/bin/csh\n";
	$output .= "set course=\$1\n";
	$output .= "if(\$course == \"\") then\n";
	$output .= "set course=\"all\"\n";
	$output .= "endif\n";
# 	$output .= "echo \"codigo=\$course\";\n";

	$output .= "\n";
	my $html_out_dir 		 = Common::GetTemplate("OutputHtmlDir");
	my $html_out_dir_syllabi = $html_out_dir."/syllabi";
	$output .= "if(\$course == \"all\") then\n";
	$output .= "\trm -rf $html_out_dir_syllabi\n";

	foreach my $TempDir ("OutputSyllabiDir", "OutputFullSyllabiDir")
	{
		my $tex_out_dir_syllabi	 = Common::GetTemplate($TempDir);
		#$output .= "if(\$course == \"all\") then\n";
		$output .= "\trm -rf $tex_out_dir_syllabi\n";
	}
	$output .= "endif\n\n";

	$output .= "mkdir -p $html_out_dir_syllabi\n";
	foreach my $TempDir ("OutputSyllabiDir", "OutputFullSyllabiDir")
	{
		my $tex_out_dir_syllabi	 = Common::GetTemplate($TempDir);
		#$output .= "if(\$course == \"all\") then\n";
		$output .= "mkdir -p $tex_out_dir_syllabi\n";
	}
	$output .= "\n";

	my ($gen_syllabi, $cp_bib) = ("", "");
	my $scripts_dir 			= Common::GetExpandedTemplateWithLang("InScriptsDir", $lang);
	my $OutputTexDir 			= Common::GetExpandedTemplateWithLang("OutputTexDir", $lang);
	my $OutputInstDir 			= Common::GetExpandedTemplateWithLang("OutputInstDir", $lang);
	my $OutputSyllabiDir		= Common::GetExpandedTemplateWithLang("OutputSyllabiDir", $lang);
	my $OutputFullSyllabiDir	= Common::GetExpandedTemplateWithLang("OutputFullSyllabiDir", $lang);
	my $syllabus_container_dir 	= Common::GetExpandedTemplateWithLang("InSyllabiContainerDir", $lang);
	my $count_courses 		= 0;
	my ($parallel_sep)   = ("");
        $parallel_sep = "&" if($Common::config{parallel} == 1);

	for(my $semester = $Common::config{SemMin}; $semester <= $Common::config{SemMax}; $semester++)
	{
		$output .= "#Semester #$semester\n";
		foreach my $codcour (@{$Common::courses_by_semester{$semester}})
		{
			$output .= "if(\$course == \"$codcour\" || \$course == \"all\") then\n";
# 			Util::print_message("codcour = $codcour, bibfiles=$Common::course_info{$codcour}{bibfiles}");
			foreach (split(",", $Common::course_info{$codcour}{bibfiles}))
			{
				$output .= "\tcp $syllabus_container_dir/$_.bib $OutputTexDir\n";
 				#Util::print_message("$syllabus_container_dir/$_");
			}
			foreach my $lang (@{$Common::config{SyllabusLangsList}})
			{
				my $lang_prefix		= $Common::config{dictionaries}{$lang}{lang_prefix};
				my $output_file 	= "$codcour-$lang_prefix";
				my $input_file		= "$OutputTexDir/$output_file.tex";
				my $output_pdf_file = "$OutputSyllabiDir/$output_file.pdf";
				$output .= "\n\t# $output_file ($lang)\n";
				
				# Full named pdf are only generated for courses with professor assigned
				if(defined($Common::config{distribution}{$codcour}))
				{	my $fullname = "$OutputFullSyllabiDir/$Common::config{Semester} $output_file - $Common::course_info{$codcour}{$Common::config{language_without_accents}}{course_name}.pdf";
					$output .= "\tcp \"$output_pdf_file\" \"$fullname\"\n";
				}
			}
			$output .= "endif\n\n";
			$count_courses++;
		}
	}
	#$output .= "\n$cp_bib\n$gen_syllabi";
	Util::write_file($out_gen_syllabi, $output);
	system("chmod 774 $out_gen_syllabi");
	Util::print_message("gen_batch_to_compile_syllabi $Common::config{institution} ($count_courses courses) OK!");
}

sub gen_batch_to_compile_syllabi($)
{
	my ($lang) = (@_);
	Util::precondition("set_global_variables");
 	Util::print_message("gen_batch_to_compile_syllabi starting ...");
	my $out_gen_syllabi      = Common::GetTemplate("out-gen-syllabi.sh-file");
    my $course               = $filter;
	my $output               = "";
	my $html_out_dir 		 = Common::GetTemplate("OutputHtmlDir");
	my $html_out_dir_syllabi = $html_out_dir."/syllabi";
    
    if( $course eq "all" )
	{   #rmtree("$html_out_dir_syllabi");
        #rmtree(Common::GetTemplate("OutputSyllabiDir"));
        #rmtree(Common::GetTemplate("OutputFullSyllabiDir"));
    }
	system("mkdir -p $html_out_dir_syllabi");
    system("mkdir -p ".Common::GetTemplate("OutputSyllabiDir"));
    system("mkdir -p ".Common::GetTemplate("OutputFullSyllabiDir"));

	my ($gen_syllabi, $cp_bib)  = ("", "");
	my $scripts_dir 			= Common::GetExpandedTemplateWithLang("InScriptsDir", $lang);
	my $OutputTexDir 			= Common::GetExpandedTemplateWithLang("OutputTexDir", $lang);
	my $OutputInstDir 			= Common::GetExpandedTemplateWithLang("OutputInstDir", $lang);
	my $OutputSyllabiDir		= Common::GetExpandedTemplateWithLang("OutputSyllabiDir", $lang);
	my $OutputFullSyllabiDir	= Common::GetExpandedTemplateWithLang("OutputFullSyllabiDir", $lang);
	my $syllabus_container_dir 	= Common::GetExpandedTemplateWithLang("InSyllabiContainerDir", $lang);
	my $count_courses 		    = 0;
	my ($parallel_sep)          = ("");
        $parallel_sep = "&" if($Common::config{parallel} == 1);
    my $command                 = "";
    my $execute                 = 1;
	for(my $semester = $Common::config{SemMin}; $semester <= $Common::config{SemMax}; $semester++)
	{
		Util::print_message(Util::yellow("#Semester #$semester"));
		foreach my $codcour (@{$Common::courses_by_semester{$semester}})
		{
			if( $course eq "all" or $course eq "$codcour" )
            {
    # 			Util::print_message("codcour = $codcour, bibfiles=$Common::course_info{$codcour}{bibfiles}");
                Util::print_message(Util::yellow("$codcour"));
                foreach my $lang (@{$Common::config{SyllabusLangsList}})
                {
                    my $lang_prefix			= $Common::config{dictionaries}{$lang}{lang_prefix};
                    my $output_file 		= "$codcour-$lang_prefix";
                    my $input_file			= "$OutputTexDir/$output_file.tex";
                    my $output_pdf_file   	= "$OutputSyllabiDir/$output_file.pdf";
					my $something_changed	= 0;
					foreach (split(",", $Common::course_info{$codcour}{bibfiles}))
					{
						my $bib_file 		= "$_.bib";
						my $bib_only_filename	= $bib_file;
						if( $bib_file =~ m/.*\/(.*?\.bib)/ )
						{	$bib_only_filename = $1;	}
						#Util::print_message("bib_file=$bib_file\nbib_only_filename=$bib_only_filename");
						#exit;
						if( Util::must_be_regenerated("$OutputTexDir/$bib_only_filename") )
						{	$command = "cp $syllabus_container_dir/$bib_file $OutputTexDir";
							Util::print_message("\t$command");
							if($execute)
							{  	system("$command");
								$something_changed++;
							}
						}
						Util::update_timestamp_for_dependency("$OutputTexDir/$bib_only_filename", "$syllabus_container_dir/$bib_file");
						Util::update_timestamp_for_dependency("$output_pdf_file", "$OutputTexDir/$bib_only_filename");   		
					}
                    Util::print_message(Util::yellow("Generating $output_file,pdf ($lang)"));
                    if( Util::must_be_regenerated($output_pdf_file) )
                    {	
                        $command = "$scripts_dir/gen-syllabus.sh $output_file $OutputInstDir$parallel_sep";
                        Util::print_message("\t$command");
                        if($execute) {  system($command);   }	
						$something_changed++;
					}
                    else
                    {	Util::print_message("\t".Util::highlight_filename($output_pdf_file)." ".Util::yellow("is already updated"));
						#Util::print_message("$input_file $output_pdf_file");
                    }
					Util::update_source_target_dependency($input_file, $output_pdf_file);
					if( $something_changed > 0 )
                    {	Util::store_timestamps();	}
                    # Full named pdf are only generated for courses with professor assigned
                    if(defined($Common::config{distribution}{$codcour}))
                    {	my $fullname = "$OutputFullSyllabiDir/$Common::config{Semester} $output_file - $Common::course_info{$codcour}{$Common::config{language_without_accents}}{course_name}.pdf";
                        $command = "cp \"$output_pdf_file\" \"$fullname\"";
                        if($execute) {  system($command);   }
                    }
                }
			    $count_courses++;
            }
		}
	}
	#$output .= "\n$cp_bib\n$gen_syllabi";
	Util::write_file($out_gen_syllabi, $output);
	system("chmod 774 $out_gen_syllabi");
	Util::print_message("gen_batch_to_compile_syllabi $Common::config{institution} ($count_courses courses) OK!");
}

sub main()
{	
	Util::begin_time();
	Common::set_general_preconfiguration();
	Common::setup();
    my $lang = $Common::config{language_without_accents};

    GenSyllabi::read_information_for_all_syllabi();
    Util::print_message("filter=$filter");
	gen_batch_to_compile_syllabi($lang);
    Common::shutdown();
}

main();