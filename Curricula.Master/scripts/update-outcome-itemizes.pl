#!/usr/bin/perl -w
use Lib::Common;
use strict;

if( defined($ENV{'CurriculaParam'}))	{ $Common::command = $ENV{'CurriculaParam'};	}
if(defined($ARGV[0])) { $Common::command = shift or Util::halt("There is no command to process (i.e. COUNTRY-AREA-INST)");	}

sub replace_outcomes($)
{
	my ($lang) = (@_);
	my $file = Common::GetExpandedTemplateWithLang("in-all-outcomes-by-course-poster", $lang);
	my $all_outcomes_txt = Util::read_file($file);
	while( $all_outcomes_txt =~ m/\\ref\{out:Outcome(.*?)\}/g )
	{
	      my $outcome = $1;
	      if( defined($Common::config{outcomes_map}{$outcome}) )
	      {		$all_outcomes_txt =~ s/\\ref\{out:Outcome$outcome\}/ $Common::config{outcomes_map}{$outcome}/g;	}
	      else
	      {		Util::print_message("Outcome config{outcomes_map}{$outcome} not defined ... did you compile the curricula.tex???? ");	}
	}
	Util::write_file($file, $all_outcomes_txt);
	Util::print_message("replace_outcomes() OK!");
}

sub main()
{
	Common::set_preconfiguration_avoiding_courses();
 	Common::set_initial_configuration($Common::command);
	my $lang = $Common::config{language_without_accents};
    Common::read_pagerefs();
 	replace_outcomes($lang);
}

main();
