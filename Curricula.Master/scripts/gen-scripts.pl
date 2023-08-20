#!/usr/bin/perl -w

use strict;
use File::Path qw(make_path);
use Lib::Common;
use Cwd;

$Common::command = shift or Util::halt("There is no command to process (i.e.  COUNTRY-AREA-INST)");

# ok
sub gen_compileall_script()
{
	Util::precondition("read_institutions_list");
	my $compileall_file = Common::GetTemplate("out-compileall-file");
	open(OUT, ">$compileall_file") or Util::halt("gen_compileall_script: $compileall_file does not open");
	print OUT "#!/bin/csh\n\n";
	my $body = "";
	my $rm_list = "";
	foreach my $country (sort keys %Common::inst_list)
	{
		$body    .= "# $country\n";
		foreach my $institution (sort keys %{$Common::inst_list{$country}})
		{
			foreach my $area (sort keys %{$Common::inst_list{$country}{$institution}})
			{
				print OUT "rm -rf html/$Common::inst_list{$country}{$institution}{$area}{area}-$institution $Common::inst_list{$country}{$institution}{$area}{area}-$institution-big-main.*\n";
				$body    .= "./scripts/updatelog.pl \"$institution: Starting compilation ...\"\n";
				#$body   .= "set fecha = `date`\n";
				#$body   .= "./scripts/updatelog.pl \"$fecha\"\n";  ``
				$body    .= "./compile  $country-$Common::inst_list{$country}{$institution}{$area}{area}-$institution \n";
				$body    .= "./gen-html $country-$Common::inst_list{$country}{$institution}{$area}{area}-$institution\n\n";
			}
		}
	}
	#print OUT "rm -rf html";
	print OUT "\n$body";
	close(OUT);
	system("chmod 774 $compileall_file");
	Util::print_message("gen_compileall_script ok");
}

# ok
sub generate_institution($)
{
	my ($lang) = (@_);
	#my $lang = $Common::config{language_without_accents};
	Util::precondition("read_institutions_list");
	my $current_inst_file = Common::GetTemplate("out-current-institution-file");

    my $output_txt = "";
	$output_txt .= "% This file was generated by gen-scripts.pl ... DO NOT TOUCH !!!\n";
	$output_txt .= "\\newcommand{\\currentinstitution}{$Common::config{institution}}\n";
	$output_txt .= "\\newcommand{\\siglas}{\\currentinstitution}\n";

	$output_txt .= "\\newcommand{\\currentarea}{$Common::config{area}}\n";
	$output_txt .= "\\newcommand{\\CountryWithoutAccents}{$Common::config{country_without_accents}}\n";
	$output_txt .= "\\newcommand{\\Country}{$Common::config{country}}\n";
	$output_txt .= "\\newcommand{\\LanguageWithoutAccent}{$Common::config{language_without_accents}}\n";
	$output_txt .= "\\newcommand{\\LANG}{$Common::config{dictionaries}{$lang}{lang_prefix}}\n";
	$output_txt .= "\\newcommand{\\Plan}{$Common::config{Plan}}\n";
	$output_txt .= "\\newcommand{\\PlanConfig}{$Common::config{PlanConfig}}\n";
	$output_txt .= "\n";

	$output_txt .= "\\newcommand{\\basedir}{".getcwd()."}\n";
	$output_txt .= "\\newcommand{\\InDir}{\\basedir/".Common::GetExpandedTemplateWithLang("InDir", $lang)."}\n";
	$output_txt .= "\\newcommand{\\InLangBaseDir}{\\basedir/".Common::GetExpandedTemplateWithLang("InLangBaseDir", $lang)."}\n";
	$output_txt .= "\\newcommand{\\InLangDefaultDir}{\\basedir/".Common::GetExpandedTemplateWithLang("InLangDefaultDir", $lang)."}\n";
	$output_txt .= "\\newcommand{\\InAllTexDir}{\\basedir/".Common::GetExpandedTemplateWithLang("InAllTexDir", $lang)."}\n";
	$output_txt .= "\\newcommand{\\InTexDir}{\\basedir/".Common::GetExpandedTemplateWithLang("InTexDir", $lang)."}\n";
	$output_txt .= "\\newcommand{\\InStyDir}{\\basedir/".Common::GetExpandedTemplateWithLang("InStyDir", $lang)."}\n";
	$output_txt .= "\\newcommand{\\InCSStyDir}{\\basedir/".Common::GetExpandedTemplateWithLang("InCSStyDir", $lang)."}\n";
	$output_txt .= "\\newcommand{\\InTexAllDir}{\\basedir/".Common::GetExpandedTemplateWithLang("InTexAllDir", $lang)."}\n";
    $output_txt .= "\\newcommand{\\InStyAllDir}{\\basedir/".Common::GetExpandedTemplateWithLang("InStyAllDir", $lang)."}\n";
	
	$output_txt .= "\\newcommand{\\InCountryDir}{\\basedir/".Common::GetExpandedTemplateWithLang("InCountryDir", $lang)."}\n";
	$output_txt .= "\\newcommand{\\InInstConfigDir}{\\basedir/".Common::GetExpandedTemplateWithLang("InInstitutionConfigDir", $lang)."}\n";
	
	$output_txt .= "\\newcommand{\\InCountryTexDir}{\\basedir/".Common::GetExpandedTemplateWithLang("InCountryTexDir", $lang)."}\n";
	$output_txt .= "\\newcommand{\\InProgramTexDir}{\\basedir/".Common::GetExpandedTemplateWithLang("InProgramTexDir", $lang)."}\n";

	# Here SPC is the same path?
	# Util::print_message( Common::GetTemplateForAnotherInstitution("InProgramTexDir", "Peru", "SPC", "CS", "", "", "") ); exit;
	$output_txt .= "\\newcommand{\\InSPCTexDir}{\\basedir/".Common::GetTemplateForAnotherInstitution("InProgramTexDir", "Peru", "SPC", "CS", "", "", "")."}\n";
 	$output_txt .= "\\newcommand{\\InProgramDir}{\\basedir/".Common::GetExpandedTemplateWithLang("InProgramDir", $lang)."}\n";
	$output_txt .= "\\newcommand{\\InLogosDir}{\\basedir/".Common::GetExpandedTemplateWithLang("InLogosDir", $lang)."}\n";

	$output_txt .= "\\newcommand{\\OutputTexDir}{\\basedir/".Common::GetExpandedTemplateWithLang("OutputTexDir", $lang)."}\n";
	$output_txt .= "\\newcommand{\\OutputCompetencesDir}{\\basedir/".Common::GetExpandedTemplateWithLang("OutputCompetencesDir", $lang)."}\n";
	
 	$output_txt .= "\\newcommand{\\OutputFigsDir}{\\basedir/".Common::GetExpandedTemplateWithLang("OutputFigsDir", $lang)."}\n";
 	$output_txt .= "\\newcommand{\\InSyllabiBaseDir}{\\basedir/".Common::GetExpandedTemplateWithLang("InSyllabiContainerDir", $lang)."}\n";
 	$output_txt .= "\\newcommand{\\OutputPrereqDir}{\\basedir/".Common::GetExpandedTemplateWithLang("OutputPrereqDir", $lang)."}\n";
 	$output_txt .= "\n";

	$output_txt .= "\\newcommand{\\TeamTitle}{$Common::config{dictionary}{TeamTitle}}\n";
	$output_txt .= "\\newcommand{\\FinalReport}{$Common::config{dictionary}{FinalReport}}\n";
	$output_txt .= "\\newcommand{\\LastModification}{$Common::config{dictionary}{LastModification}}\n";
	$output_txt .= "\\newcommand{\\BibliographySection}{$Common::config{dictionary}{BibliographySection}}\n";

	$output_txt .= "\\newcommand{\\PeopleDir}{\\basedir/$Common::config{InPeopleDir}}\n";
	$output_txt .= "\\newcommand{\\Semester}{$Common::config{Semester}}\n";

	$output_txt .= "\n";
	foreach my $lang (@{$Common::config{SyllabusLangsList}})
	{
		$output_txt .= "\\newcommand{\\Language$lang"."Prefix}{$Common::config{dictionaries}{$lang}{lang_prefix}}\n";
	}

	Util::write_file($current_inst_file, $output_txt);
	my $output_current_institution = Common::GetExpandedTemplateWithLang("OutDir", $lang)."/tex/current-institution.tex";

	Util::print_message("Creating: $output_current_institution ...");
	Util::write_file($output_current_institution, $output_txt);
	Util::print_message("generate_institution ok");
}

# ok
sub update_acronyms($)
{
	my ($lang) = (@_);
	Util::precondition("read_institutions_list");
	my $txt = "";
	my $out_txt = "";
	foreach my $country (sort keys %Common::Common::inst_list)
	{
		foreach my $institution (sort keys %{$Common::Common::inst_list{$country}})
		{
			#system("mv institutions-info/institutions-$institution.tex institutions-info/info-$institution.tex");
			my $out_txt_name = Common::GetInstitutionInfo();
			if(-e $out_txt_name)
			{
				Util::print_message("Reading: $out_txt_name ...");
				$out_txt = Util::read_file($out_txt_name);
				if($out_txt =~ m/\\newcommand\{\\University\}\{(.*?)\}/)
				{
					my $univ = $1;
					$univ =~ s/\\xspace//g;
					$txt .= "\\acro{$institution}{$univ}\n";
				}
			}
		}
	}
	#print "$basetex/$area-acronyms.tex\n";
	my $acronym_base = Common::GetExpandedTemplateWithLang("in-acronyms-base-file", $lang);
	if( not -e $acronym_base )
	{	Util::print_message("$Util::icons{X} I did not find file: $acronym_base");
		exit;
	}
	Util::print_message("$Util::icons{ok} reading $acronym_base ...");
	$out_txt 	 = Util::read_file($acronym_base);

	if($out_txt =~ m/%--LIST-OF-INSTITUTIONS--/)
	{
		my $pretxt = "\n%Text generated by gen-scripts.pl ... DO NOT TOUCH !!!\n";
		my $postxt = "%End of text generated\n";
		$out_txt =~ s/%--LIST-OF-INSTITUTIONS--/$pretxt$txt$postxt/g;
	}

	my $out_acronym_file = Common::GetTemplate("out-acronym-file");
	Util::write_file($out_acronym_file, $out_txt);
	Util::print_message("update_acronyms ($out_acronym_file) OK!");
}

sub gen_batch_files()
{
	my $file = "";
	my ($input, $output) = ("", "");
	my $lang = Common::GetTemplate("language_without_accents");
	foreach my $file ("compile1institucion", "gen-html-1institution")
	{
	    system("rm $file*");
	    $input     = Common::GetTemplate("in-$file-base-file");
	    $output    = Common::GetTemplate("out-$file-file");
	    Common::gen_batch($input, $output, $lang);
	    Util::print_message("$Util::icons{link} Creating shorcut: ln -s $output");
	    system("cp $output .");
	}
	foreach my $file ("gen-eps-files" , "gen-graph", "gen-book", 
					  "CompileTexFile", "compile-simple-latex", 
					  "gen-poster"    , "gen-poster-fast")
	{
		system("rm $file*");
		$input     = Common::GetTemplate("in-$file-base-file");
	    $output    = Common::GetTemplate("out-$file-file");
	    system("rm $output");
		Common::gen_batch($input, $output, $lang);
		system("cp $output .");
	}
	my $command = "cp ". Common::GetTemplate("preamble0-file")." ". Common::GetTemplate("OutputTexDir");
	Util::print_message($command);
	system($command);
}

sub main()
{
    Common::set_preconfiguration_avoiding_courses();
	Common::setup();
	
	my $lang = Common::GetTemplate("language_without_accents");
	gen_batch_files();
	gen_compileall_script();
	generate_institution($lang);
	update_acronyms($lang);
	Common::shutdown();
	Util::print_message("End gen-scripts ...\n");
}

main();
