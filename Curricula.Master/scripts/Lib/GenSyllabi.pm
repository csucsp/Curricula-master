package GenSyllabi;
use warnings;
use Data::Dumper;
use Carp::Assert;
use Scalar::Util qw(blessed dualvar isdual readonly refaddr reftype
                        tainted weaken isweak isvstring looks_like_number
                        set_prototype);
                        # and other useful utils appearing below
use Switch;
use Lib::Common;
use strict;
my $competence_singular 	= "competence";
my $outcome_singular    	= "outcome";
my $specificoutcome_singular= "specificoutcome";
my $competences 			= $competence_singular."s";
my $outcomes    			= $outcome_singular."s";
my $specificoutcomes		= $specificoutcome_singular."s";

my @versioned_environments = ($outcomes, $specificoutcomes, $competences);
my %prefix_environments    = ($outcomes         => $outcome_singular, 
						      $specificoutcomes => $specificoutcome_singular, 
						      $competences      => $competence_singular);

sub get_environment($$$)
{
	my ($codcour, $txt, $env) = (@_);
	if($txt =~ m/\\begin\{$env\}\s*\n((?:.|\n)*)\\end\{$env\}/g)
	{	return $1;	}
# 	Util::print_warning("$codcour does not have $env");
	return "";
}

sub filter_list_of_competences($$$)
{
	my ($codcour, $lang, $unit_list_of_competences) = (@_);
	$unit_list_of_competences =~ s/ //g;

	my $version = $Common::config{OutcomesVersion};
	my $env = $outcomes;
	# Util::print_color("env=$env");
	# $Common::course_info{$codcour}{$lang}{$env}{$version}{$key} = $value;
	# print "Common::course_info{$codcour}{$lang}{$env}}=$Common::course_info{$codcour}{$lang}{$env}\n";
	# print Dumper(\%{$Common::course_info{$codcour}{$lang}{$env}});
	my $course_competences = join(",", @{$Common::course_info{$codcour}{$lang}{$env}{$version}{keys}});
	# print "Course: $codcour contains: $course_competences\n";
	# print "Competences to filter: $unit_list_of_competences\n";
	my $output_val = Util::intersection($course_competences, $unit_list_of_competences);
	return $output_val;
}

sub process_syllabus_units($$$$)
{
	my ($codcour, $lang, $syllabus_in, $unit_struct)	= (@_);
	my ($unit_count, $total_hours) 			= (0, 0);
	my %accu_hours     				= ();

	Util::precondition("parse_environments_in_header($codcour)");

	# \begin{unit}{\AL}{}   {Guttag13,Thompson11,Zelle10}{2}{C1,C5}
	$unit_count       = 0;
	foreach my $line (split("\n", $syllabus_in))
	{
		if($line =~ m/\\begin\{unit\}(.*)(\r|\n)*$/ )
		{
			my $params = $1;
			$unit_count++;
			if($params =~ m/\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}/ )
			{
				#Util::print_color("codcour=$codcour, $line good line !");
			}
			elsif($params =~ m/\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}/ )
			{
				my ($p1, $p2, $p3, $p4) 	= ($1, $2, $3, $4);
				my ($pm1, $pm2, $pm3, $pm4) = (Common::replace_special_chars($p1), Common::replace_special_chars($p2), Common::replace_special_chars($p3), Common::replace_special_chars($p4));
				print("codcour=$codcour\n\\begin\{unit\}$params wrong number of parameters?"),
				$syllabus_in =~ s/\\begin\{unit\}\{$pm1\}\{$pm2\}\{$pm3\}\{$pm4\}/\\begin\{unit\}\{$p1\}\{\}\{$p2\}\{$p3\}\{$p4\}/g;
				Util::print_message("Changed to: \\begin\{unit\}\{$p1\}".Util::green("\{\}")."\{$p2\}\{$p3\}\{$p4\}");
			}
			else
			{
				Util::print_error("codcour=$codcour, did you invented a new format for units? ($line)");
			}
			if($line =~ m/\\begin\{unit\}\{.*?\}\{.*?\}\{.*?\}\{(.*?)\}\{.*?\}\s*((?:.|\n)*?)\\end\{unit\}/)
			{
				$unit_count++;
				my $nhours 	= $1;
				$total_hours   += $nhours;
				if( not looks_like_number($nhours) )
				{	Util::print_warning("Codcour=$codcour, Unit $unit_count, number of hours is wrong ($nhours)");		}
				$accu_hours{$unit_count}  = $total_hours;
			}
		}
	}

	my $all_units_txt     = "";
	my $unit_captions = "";
	$unit_count       = 0;

	my $sep = "";
	while($syllabus_in =~ m/\\begin\{unit\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\s*((?:.|\n)*?)\\end\{unit\}/g)
	{
		$unit_count++;
		$Common::course_info{$codcour}{n_units}++;
		my ($unit_caption, $alternative_caption, $unit_bibitems, $unit_hours, $list_of_competences, $unit_body) = ($1, $2, $3, $4, $5, $6);
		$list_of_competences = filter_list_of_competences($codcour, $lang, $list_of_competences);
		$list_of_competences =~ s/ //g;
		$unit_bibitems =~ s/ //g;

		push(@{$Common::course_info{$codcour}{units}{unit_caption}}, $unit_caption);
		push(@{$Common::course_info{$codcour}{units}{alternative_caption}}, $alternative_caption);
		push(@{$Common::course_info{$codcour}{units}{bib_items}}   , $unit_bibitems);
		push(@{$Common::course_info{$codcour}{units}{hours}}       , $unit_hours);
		push(@{$Common::course_info{$codcour}{units}{list_of_competences}} , $list_of_competences);
		$Common::course_info{$codcour}{allbibitems} .= "$sep$unit_bibitems";

		$unit_captions   .= "\\item $unit_caption\n";
		my %map = ();
		$map{UNIT_TITLE}  	= $unit_caption;
		$map{UNIT_BIBITEMS}	= $unit_bibitems;

		$map{LEVEL_OF_COMPETENCE}	= $list_of_competences;
		if($unit_caption =~ m/^\\(.*)/)
		{
			$unit_caption = $1;
			#Util::print_message("TODO Course: $codcour: \\$unit_caption found ...");
			#print Dumper (\%$Common::config{topics_priority}); exit;

			#if( not defined($Common::config{topics_priority}{$unit_caption}) )
			#{	Util::print_color("process_syllabus_units: course: $codcour ignoring unit \\$unit_caption for map_hours_unit_by_course ...");	}
			#else
			#{
				if(not defined($Common::map_hours_unit_by_course{$lang}{$unit_caption}{$codcour}))
				{	$Common::map_hours_unit_by_course{$lang}{$unit_caption}{$codcour} = 0;		}
				$Common::map_hours_unit_by_course{$lang}{$unit_caption}{$codcour} += $unit_hours;
			#}

			if(not defined($Common::acc_hours_by_course{$lang}{$codcour}))
			{	$Common::acc_hours_by_course{$lang}{$codcour}  = 0;						}
			$Common::acc_hours_by_course{$lang}{$codcour} += $unit_hours;

			if(not defined($Common::acc_hours_by_course{$lang}{$unit_caption}))
			{	$Common::acc_hours_by_unit{$lang}{$unit_caption}  = 0;						}
			$Common::acc_hours_by_unit{$lang}{$unit_caption} += $unit_hours;

# 			if( $unit_caption eq "DSSetsRelationsandFunctions" )
# 			{	print Dumper (\%Common::map_hours_unit_by_course{$lang}{$unit_caption}); 		}
		}
		$sep = ",";
		my ($topics, $unitgoals) = ("", "");
		if($unit_body =~ m/(\\begin\{topics\}\s*((?:.|\n)*?)\\end\{topics\})/g)
		{	$topics = $1; }
		elsif($unit_body =~ m/(\\.*?AllTopics)/g)
		{	$topics = $1; }

		if($unit_body =~ m/(\\begin\{learningoutcomes\}\s*(?:.|\n)*?\\end\{learningoutcomes\})/g)
		{	$unitgoals = $1; }
		elsif($unit_body =~ m/(\\.*?AllObjectives)/g)
		{	$unitgoals = $1; }
		push(@{$Common::course_info{$codcour}{units}{topics}},   $topics);
		push(@{$Common::course_info{$codcour}{units}{unitgoals}}, $unitgoals);

		my $thisunit            = $unit_struct;
		$map{HOURS}		= "$unit_hours";
		$map{FULL_HOURS}	= "$unit_hours $Common::config{dictionary}{hours}";
		$map{UNIT_GOAL}		= $unitgoals;
		$map{UNIT_CONTENT}	= $topics;
		$map{PERCENTAGE} 	= 0;
		$map{PERCENTAGE} 	= int(100*$accu_hours{$unit_count}/$total_hours+0.5) if($total_hours  > 0 );

		$sep = "";
		my $bib_citations = "";
		foreach my $bibitem (split(",", $unit_bibitems))
		{	$bib_citations .= "$sep\\cite{$bibitem}";	$sep = ", ";		}
		$map{CITATIONS} = $bib_citations;
		$thisunit = Common::replace_tags_from_hash($thisunit, "--", "--", %map);
		$all_units_txt .= $thisunit;
	}
	Util::check_point("process_syllabus_units($codcour)");
	return ($all_units_txt, $unit_captions, $syllabus_in );
}

my %macro_for_env = ($outcomes           => "ShowOutcome", 
					$competences         => "ShowCompetence",
					$specificoutcomes	 => "ShowSpecificOutcome",
					);

sub parse_environments_in_header($$$$)
{
	my ($codcour, $lang, $syllabus_in, $fullname)   = (@_);
	my $version = $Common::config{OutcomesVersion};
	printf("$Util::icons{ok} parse_environments_in_header");
	foreach my $env (@versioned_environments)
	{	
		$Common::course_info{$codcour}{$lang}{$env}{$version}{keys} 	= [];
		$Common::course_info{$codcour}{$lang}{$env}{$version}{txt} 		= $1;
		$Common::course_info{$codcour}{$lang}{$env}{$version}{count} 	= 0;
		$Common::course_info{$codcour}{$lang}{$env}{$version}{itemized}	= "";
		if( $syllabus_in =~ m/\\begin\{$env\}\{$version\}\s*\n((?:.|\n)*?)\\end\{$env\}/g)
		{
			#Util::print_message("\\begin{$env}{$version} detected !");
			$Common::course_info{$codcour}{$lang}{$env}{$version}{txt} = $1;
			foreach my $one_line ( split("\n", $Common::course_info{$codcour}{$lang}{$env}{$version}{txt}) )
			{
				my ($key, $tail)     = ("", "");
				my $reg_exp =  "\\\\".$macro_for_env{$env}."(.*)";
				if( $one_line =~ m/$reg_exp/g )
				{
					($tail) = ($1);
					my @params = $tail =~ m/\{(.*?)\}/g;
					switch($env)
					{	my $prefix = $prefix_environments{$env};
						case [$outcomes, $competences] 
						{ 	#print $env;
							my ($key, $value) = ($params[0], $params[1]);
							# \item \ShowOutcome{a}{2}
							# \item \ShowCompetence{C1}{a}
							$Common::course_info{$codcour}{$lang}{$env}{$version}{$key} = $value;
							push(@{$Common::course_info{$codcour}{$lang}{$env}{$version}{keys}}, $key);
							$Common::config{course_by_outcome}{$params[0]}{$codcour} = "";
							if( not defined($Common::config{macros}{outcomes}{$lang}{"$prefix$key"}) )
							{	
								#Util::print_message("Common::config{macros}{outcomes}{$lang}{$prefix$key}=".$Common::config{macros}{outcomes}{$lang}{"$prefix$key"});
								#print Dumper(\%{$Common::config{macros}{outcomes}{$lang}});
								push(@{$Common::error{outcomes_and_competencies}{$lang}{$env}{$key}}, $codcour);		

							}
						}	#\% ($codcour, $semester, $lang)
						case [$specificoutcomes]
						{	# Save the specific outcome
							my $key = "$params[0]$params[1]";
							$Common::course_info{$codcour}{$lang}{$env}{$version}{$key} = $params[2];
							push(@{$Common::course_info{$codcour}{$lang}{$env}{$version}{keys}}, $key);

							# \item \ShowSpecificOutcome{a}{3}{}
							$Common::course_info{$codcour}{$lang}{outcomes}{$version}{specificoutcomes}{$key} = $params[2];
							$Common::config{course_by_specificoutcome}{$params[0]}{$params[1]}{$codcour} = "";
							if( not defined($Common::config{macros}{outcomes}{$lang}{"$prefix$key"}) )
							{	
								#my @keys = sort {$a cmp $b} keys %{$Common::config{macros}{outcomes}{$lang}};
								#print Dumper(\@keys);
								#Util::print_message("Common::config{macros}{outcomes}{$lang}{$prefix$key}=".$Common::config{macros}{outcomes}{$lang}{"$prefix$key"});
								#exit;
								#print Dumper(\%{$Common::config{macros}{outcomes}{$lang}});
								push(@{$Common::error{outcomes_and_competencies}{$lang}{$env}{$key}}, $codcour);		
							}
						}
					}
					
					$Common::course_info{$codcour}{$lang}{$env}{$version}{itemized}  	.= "\\item \\".$macro_for_env{$env};
					foreach my $param (@params)
					{	$Common::course_info{$codcour}{$lang}{$env}{$version}{itemized} .= "{$param}";		}
					$Common::course_info{$codcour}{$lang}{$env}{$version}{itemized}		.= "\n";
					$Common::course_info{$codcour}{$lang}{$env}{$version}{count}++;
					my $prefix	        = "";
					if(defined($Common::config{$env."_map"}) and defined($Common::config{$env."_map"}{$key}) ) # outcome: a), b), c) ... Competence
					{	$prefix = $Common::config{$env."_map"}{$key};	}
					if( $env eq "outcomes")
					{	$Common::config{course_by_outcome}{$key}{$codcour} = "";	}
				}
			}
		}
		else
		{
			$Common::error{courses}{$codcour}{lang}{$lang}{file}     = $fullname;
			$Common::error{courses}{$codcour}{lang}{$lang}{missing} .= "$env"."{$version}, ";
		}
	}
	Util::check_point("parse_environments_in_header($codcour)");
}

sub get_professors_info($$)
{
	my ($codcour, $lang) 	= (@_);
	my %map 		= ("PROFESSOR_NAMES" => "", "PROFESSOR_SHORT_CVS" => "", 
					   "PROFESSOR_JUST_GRADE_AND_FULLNAME" => "", "PROFESSOR_ERROR" => "");
	my $sep    		= "";
	if(defined($Common::config{distribution}{$codcour}))
	{
		my $first = 1;
		#print Dumper(\%Common::professor_role_order); exit;
		foreach my $role  ( sort {$Common::professor_role_order{$a} <=> $Common::professor_role_order{$b}}
							keys %Common::professor_role_order)
		{
			#print Dumper(\%{$Common::config{distribution}{$codcour}{$role}});
			my $count 				= 0;
			my $PROFESSOR_SHORT_CVS = "";
			foreach my $email (sort {$Common::config{faculty}{$b}{fields}{degreelevel} <=> $Common::config{faculty}{$a}{fields}{degreelevel} ||
									 $Common::config{faculty}{$a}{fields}{dedication}  cmp $Common::config{faculty}{$b}{fields}{dedication} ||
									 $Common::config{faculty}{$a}{fields}{name}        cmp $Common::config{faculty}{$b}{fields}{name}}
								keys %{$Common::config{distribution}{$codcour}{$role}}
							  )
			{
					if( $Common::config{faculty}{$email}{fields}{degreelevel} >= $Common::config{degrees}{MasterPT} )
					{
						my $coordinator = "";
						#if( $role eq "C" )
						#{	$coordinator = "~(\\textbf{$Common::config{dictionaries}{$lang}{Coordinator}})";	$first = 0;		}
						$map{PROFESSOR_NAMES} 	.= "$Common::config{faculty}{$email}{fields}{name} ";
						$PROFESSOR_SHORT_CVS	.= "\\item $Common::config{faculty}{$email}{fields}{name} \$<\$$email\$>\$ $coordinator\n";
						$PROFESSOR_SHORT_CVS 	.= "\\vspace{-0.2cm}\n";
						$PROFESSOR_SHORT_CVS 	.= "\\begin{itemize}[noitemsep]\n";
						$PROFESSOR_SHORT_CVS 	.= "$Common::config{faculty}{$email}{fields}{shortcv}{$lang}";
						$PROFESSOR_SHORT_CVS 	.= "\\end{itemize}\n\n";
						$count++;
						#$map{PROFESSOR_JUST_GRADE_AND_FULLNAME} .= "$sep$Common::config{faculty}{$email}{fields}{title} $Common::config{faculty}{$email}{fields}{name}";
					}
					$sep = ", ";
			}
			if( $count > 0 )
			{	$map{PROFESSOR_SHORT_CVS} .= "\\noindent \\textbf{$Common::config{dictionaries}{$lang}{professor_role_label}{$role}}\n";
				$map{PROFESSOR_SHORT_CVS} .= "\\begin{itemize}[noitemsep]\n";
				$map{PROFESSOR_SHORT_CVS} .= $PROFESSOR_SHORT_CVS;
				$map{PROFESSOR_SHORT_CVS} .= "\\end{itemize}\n";
				#print Dumper (\%{$Common::config{dictionaries}{$lang}{professor_role_label}});
				#exit;
			}
		}
		#exit; #role
	}
	else
	{
 		$map{PROFESSOR_ERROR} = Util::red("There is no professor assigned to $codcour (".Common::format_semester_label_in_plain_text($Common::course_info{$codcour}{semester}, $lang).")");
	}
	return ($map{PROFESSOR_NAMES}, $map{PROFESSOR_SHORT_CVS}, $map{PROFESSOR_ERROR});
}

sub get_prerrequisites_info($$)
{
	my ($codcour, $lang) = (@_);
	my %map 		= ();
	if($Common::course_info{$codcour}{n_prereq} == 0)
	{	$map{PREREQUISITES_JUST_CODES}	= $Common::config{dictionaries}{$lang}{None};
        $map{PREREQUISITES}             = $Common::config{dictionaries}{$lang}{None};
	}
	else
	{
        $map{PREREQUISITES_JUST_CODES}	= $Common::course_info{$codcour}{prerequisites_just_codes};
        my $output = "";
        if( scalar(@{$Common::course_info{$codcour}{$lang}{code_name_and_sem_prerequisites}}) == 1 )
        {   $output = $Common::course_info{$codcour}{$lang}{code_name_and_sem_prerequisites}[0];    }
        else
        {   foreach my $txt ( @{$Common::course_info{$codcour}{$lang}{code_name_and_sem_prerequisites}} )
            {   $output .= "\t\t \\item $txt\n";        }
            $output = "\\begin{itemize}\n$output\\end{itemize}";
        }
        $map{PREREQUISITES} 			= $output;
	}
	return ($map{PREREQUISITES_JUST_CODES}, $map{PREREQUISITES});
}

sub get_formatted_skills($$$$$)
{
	my ($codcour, $env, $version, $lang, $fullname) = (@_);
	my %map = ("FULL_SPECIFIC" => "", "SPECIFIC_ITEMS" => "");
	my $EnvforOutcomes = $Common::config{EnvforOutcomes};
	$map{FULL_SPECIFIC}	= "";
	if($Common::course_info{$codcour}{$lang}{$env}{$version}{count} == 0)
	{	#Util::print_warning("Course $codcour ... no {$env}{$version} detected ... assuming an empty one!"); 
		$Common::course_info{$codcour}{$lang}{$env}{$version}{itemized} = "\\item \\colorbox{red}{No$env}\n";
	}
	#Util::print_message("Common::course_info{$codcour}{$lang}{$env}{$version}{count}=$Common::course_info{$codcour}{$lang}{$env}{$version}{count}"); 
	if( defined($Common::course_info{$codcour}{$lang}{$env}{$version}) )
	{	$map{FULL_SPECIFIC}	= "\\begin{$EnvforOutcomes}\n$Common::course_info{$codcour}{$lang}{$env}{$version}{itemized}\\end{$EnvforOutcomes}";	}
	else{	Util::print_warning("There is no $env ($version) defined for $codcour ($fullname)"); 	
	}
	$map{SPECIFIC_ITEMS}	= $Common::course_info{$codcour}{$lang}{$env}{$version}{itemized};
	return ($map{FULL_SPECIFIC}, $map{SPECIFIC_ITEMS});
}

sub init_course_units_vars($)
{
	my ($codcour) = (@_);
	$Common::course_info{$codcour}{allbibitems}         = "";
	$Common::course_info{$codcour}{n_units}				= 0;
	$Common::course_info{$codcour}{units}{unit_caption}	= [];
	$Common::course_info{$codcour}{units}{bib_items}	= [];
	$Common::course_info{$codcour}{units}{hours}		= [];
	$Common::course_info{$codcour}{units}{bloom_level}	= [];
	$Common::course_info{$codcour}{units}{topics}    	= [];
	$Common::course_info{$codcour}{units}{unitgoals}	= [];
	$Common::course_info{$codcour}{units}{list_of_competences} = [];
}

sub get_filtered_common_file($$)
{
	my ($codcour, $CommonTexFile) = (@_);
	my $CommonTxt = Util::read_file($CommonTexFile);
	my $output_txt = "";

	my $version = $Common::config{OutcomesVersion};
	foreach my $env (@versioned_environments)
	{
		if( $CommonTxt =~ m/\\begin\{$env\}\{$version\}\s*\n((?:.|\n)*?)\\end\{$env\}/g)
		{	$output_txt .= 	"\\begin\{$env\}\{$version\}\n$1\\end\{$env\}\n";	}
		else
		{	$Common::error{courses}{$codcour}{competencies}{$env} = "I did not find: ".Util::red("\\begin\{$env\}\{$version\}...\\end\{$env\}")." see file: $CommonTexFile"; 
			#Util::print_warning("Course $codcour ... no {specificoutcomes}{$version} detected ... assuming an empty one!");
		}
	}
	# print Dumper(\%{$Common::error{courses}{$codcour}{competencies}});
	# Util::print_message("get_filtered_common_file($codcour):\n$output_txt");
	return $output_txt;
}

my $read_syllabus_info_last_sem_processed = 0;
# ok
sub read_syllabus_info($$$$)
{
	my ($codcour, $semester, $lang, $show_messages)   = (@_);
	my $course_name 	= $Common::course_info{$codcour}{$lang}{course_name};
	#Util::print_message("read_syllabus_info($codcour. $course_name ($semester$Common::config{dictionary}{ordinal_postfix}{$semester}), $lang)\n");
	my $fullname 	  	= Common::get_input_syllabus_full_path($codcour, $semester, $lang);
	if( not $semester == $read_syllabus_info_last_sem_processed )
	{
		my $semester_label = Common::format_semester_label_in_plain_text($semester, $lang);
		Util::print_message(Util::yellow("$semester_label") );
		$read_syllabus_info_last_sem_processed = $semester;
	}
	if( not -e $fullname )
	{	Common::TryToCreateSyllabus($codcour, $semester, $lang);
		$fullname 		= Common::get_input_syllabus_full_path($codcour, $semester, $lang);
		$show_messages  = 1;
	}
	assert( -e $fullname );
	$Common::course_info{$codcour}{$lang}{file_fullpath} = $fullname;
	my $CommonTexFile = Common::GetCommonFileFullPath($codcour, $lang);
	if( not -e $CommonTexFile )
	{	# Create the common file
		Common::create_empty_common_file($codcour, $lang);
	}
	my $relative_path 	= $Common::course_info{$codcour}{relative_path};
	my $highlighted_text = Util::HighlightFilenameLangRelativePath($fullname, "$relative_path", "$lang");
	printf("$Util::icons{ok} read_syllabus_info: Reading %-120s", $highlighted_text );
	#print $formatted_str;	
	#Util::print_message("read_syllabus_info: Reading $fullname ...");
	my $syllabus_in	= Util::read_file($fullname);
	if( $show_messages == 1)
	{	#Util::print_color("Size (A) of $fullname is: ". length($syllabus_in)." bytes");	
	}
	
	init_course_units_vars($codcour);
	my $version = $Common::config{OutcomesVersion};
	if( -e $CommonTexFile )
	{	if( $show_messages )
		{	my  $highlighted_text = Util::HighlightFilenameLangRelativePath($CommonTexFile, $relative_path, "Common");
			print("$Util::icons{ok} $highlighted_text ...\n");
		}
		my $CommonTxt = get_filtered_common_file($codcour, $CommonTexFile);
		#                                   --COMMON-CONTENT--
		$syllabus_in  =~ s/\\end\{goals\}\s*(?:.|\n)*?\\begin\{unit\}/\\end\{goals\}\n\n$CommonTxt\n\\begin\{unit\}/g;
	}
	my %map = ();
	$map{INPUT_TEX_FILE_NAME}  = $fullname;
	$map{INPUT_COMMON_TEX_FILE_NAME} = $CommonTexFile;

	$syllabus_in = Common::replace_accents($syllabus_in);
	while($syllabus_in =~ m/\n\n\n/)
	{	$syllabus_in =~ s/\n\n\n/\n\n/g;	}

	$Common::course_info{$codcour}{unitcount}	= 0;
	my $syllabus_template = $Common::config{syllabus_template};
	foreach my $env ("justification", "goals")
	{	$Common::course_info{$codcour}{$lang}{$env}{txt} 	= get_environment($codcour, $syllabus_in, $env);
	}
	my $CommonFileContent = Util::read_file($CommonTexFile);
	parse_environments_in_header($codcour, $lang, $CommonFileContent, $CommonTexFile);
	printf("\n");
	my $unit_struct = "";
	if($syllabus_template =~ m/--BEGINUNIT--\s*\n((?:.|\n)*)--ENDUNIT--/)
	{	$unit_struct = $1;	}

	#if( $show_messages == 1)
	#{	Util::print_color("Size (B) of syllabus_in is: ". length($syllabus_in)." bytes"); }
	my $syllabus_adjusted = "";
	($map{UNITS_SYLLABUS}, $map{SHORT_DESCRIPTION}, $syllabus_adjusted) = process_syllabus_units($codcour, $lang, $syllabus_in, $unit_struct);

	if( not $syllabus_adjusted eq $syllabus_in )
	{
		system("cp $fullname $fullname.bak");
		$syllabus_in = $syllabus_adjusted;
		Util::print_color("Syllabus adjusted (new units format)... see old file at: $fullname.bak");
		Util::write_file($fullname, $syllabus_in);
	}
	else
	{	#Util::write_file($fullname, $syllabus_in);		
	}
	#if( $show_messages == 1)
	#{	Util::print_color("Size (C) of syllabus_in is: ". length($syllabus_in)." bytes");	exit;	}
	$map{COURSE_CODE} 		= $codcour;
	$map{COURSE_NAME} 		= Common::prepare_text_for_latex($course_name);
	$map{COURSE_TYPE}		= $Common::config{dictionaries}{$lang}{$Common::course_info{$codcour}{course_type}};
	$map{LEARNING_MODALITY}	= $Common::config{dictionaries}{$lang}{LearningModalityList}{$Common::course_info{$codcour}{LearningModality}};

	$semester 			= $Common::course_info{$codcour}{semester};
	$map{SEMESTER}    	= $semester;
	$map{SEMESTER}     .= "\$^{$Common::config{dictionary}{ordinal_postfix}{$semester}}\$ ";
	$map{SEMESTER}     .= "$Common::config{dictionary}{Semester}.";
	$map{CREDITS}		= $Common::course_info{$codcour}{cr};
	$map{JUSTIFICATION}	= $Common::course_info{$codcour}{$lang}{justification}{txt};

	$map{FULL_GOALS}	= "\\begin{itemize}\n$Common::course_info{$codcour}{$lang}{goals}{txt}\n\\end{itemize}";
	$map{GOALS_ITEMS}	= $Common::course_info{$codcour}{$lang}{goals}{txt};

	($map{FULL_OUTCOMES},          $map{OUTCOMES_ITEMS}) 		  = get_formatted_skills($codcour, "outcomes", $version, $lang, $CommonTexFile);
	($map{FULL_SPECIFIC_OUTCOMES}, $map{SPECIFIC_OUTCOMES_ITEMS}) = get_formatted_skills($codcour, "specificoutcomes", $version, $lang, $CommonTexFile);
	($map{FULL_COMPETENCES},       $map{COMPETENCES_ITEMS})		  = get_formatted_skills($codcour, "competences", $version, $lang, $CommonTexFile);
	
	$map{EVALUATION} 	= $Common::config{general_evaluation};
	#Util::print_message("map{EVALUATION} =\n$map{EVALUATION}");
	if( defined($Common::course_info{$codcour}{$lang}{specific_evaluation}) )
	{	$map{EVALUATION} = $Common::course_info{$codcour}{$lang}{specific_evaluation};	}

	($map{PROFESSOR_NAMES}, $map{PROFESSOR_SHORT_CVS}, $map{PROFESSOR_ERROR}) = get_professors_info($codcour, $lang);
	$Common::course_info{$codcour}{docentes_names}  	= $map{PROFESSOR_NAMES};
	$Common::course_info{$codcour}{docentes_titles}  	= $map{PROFESSOR_TITLES};
	$Common::course_info{$codcour}{docentes_shortcv} 	= $map{PROFESSOR_SHORT_CVS};

	my $horastxt 		 = "";
	$horastxt 			.= "$Common::course_info{$codcour}{th} HT; " if($Common::course_info{$codcour}{th} > 0);
	$horastxt 			.= "$Common::course_info{$codcour}{ph} HP; " if($Common::course_info{$codcour}{ph} > 0);
	$horastxt 			.= "$Common::course_info{$codcour}{lh} HL; " if($Common::course_info{$codcour}{lh} > 0);
	$map{HOURS}			 = $horastxt;
	($map{THEORY_HOURS}, $map{PRACTICE_HOURS}, $map{LAB_HOURS}, $map{AUTONOMOUS_HOURS})	= ("-", "-", "-", "-");

	if($Common::course_info{$codcour}{th} > 0)
	{   $map{THEORY_HOURS} = "$Common::course_info{$codcour}{th} (<<Weekly>>)";	}

	if($Common::course_info{$codcour}{ph} > 0)
	{   $map{PRACTICE_HOURS} = "$Common::course_info{$codcour}{ph} (<<Weekly>>)";	}

	if($Common::course_info{$codcour}{lh} > 0)
	{   $map{LAB_HOURS} = "$Common::course_info{$codcour}{lh} (<<Weekly>>)";	}

	if($Common::course_info{$codcour}{ti} > 0)
	{	$map{AUTONOMOUS_HOURS} = "$Common::course_info{$codcour}{ti} (<<hours>>)";	}

	($map{PREREQUISITES_JUST_CODES}, $map{PREREQUISITES}) = get_prerrequisites_info($codcour, $lang);
	
	$map{LIST_OF_TOPICS} = $map{SHORT_DESCRIPTION};
	$map{SHORT_DESCRIPTION} = "\\begin{inparaenum}\n$map{SHORT_DESCRIPTION}\\end{inparaenum}";

	my ($bibfile_in, $bibfile_out) = ("", "");
	if($syllabus_in =~ m/\\bibfile\{(.*?)\}/g)
	{	$bibfile_in = $1;	$bibfile_in     =~ s/ //g;	}
	else
	{	Util::print_color("ABC\n$syllabus_in");
		Util::print_color("XYZ\n$syllabus_adjusted");
		Util::print_message(Util::yellow("$codcour")." does not contain \\bibfile{$codcour}. See:".
							Util::yellow("$map{INPUT_TEX_FILE_NAME}"));
	}
	$map{BIBSTYLE}	= $Common::config{bibstyle};
	$Common::course_info{$codcour}{short_bibfiles} = "";
	if( $bibfile_in =~ m/.*\/(.*)/)
	{	$bibfile_out 	= $1;
		$Common::course_info{$codcour}{short_bibfiles} = $1;
	}
	$map{IN_BIBFILE} 	= $bibfile_in;
	$map{BIBFILE} 		= $bibfile_out.".bib";
	$Common::course_info{$codcour}{bibfiles} = $bibfile_in;

	foreach (keys %{$Common::course_info{$codcour}{extra_tags}})
	{	$map{$_} =  $Common::course_info{$codcour}{extra_tags}{$_};		}
	if( $show_messages == 1)
	{	#Util::print_color("Check point B"); #assert(0); exit;	
	}
	return %map;
}

sub genenerate_syllabus_output_tex_file($$$$$%) # Bookmark
{
	my ($codcour, $file_template, $units_field, $output_file, $lang, %map)   = (@_);
	$file_template =~ s/--BEGINUNIT--\s*\n((?:.|\n)*)--ENDUNIT--/$map{$units_field}/g;
	$file_template =~ s/\\newcommand\{\\INST\}\{\}/\\newcommand\{\\INST\}\{$Common::config{institution}\}/g;
	$file_template =~ s/\\newcommand\{\\AREA\}\{\}/\\newcommand\{\\AREA\}\{$Common::config{area}\}/g;
	if($file_template =~ m/--OUTCOMES-FOR-OTHERS--/g)
	{
		my $nkeys = keys %{$Common::course_info{$codcour}{extra_tags}};
		if($nkeys > 0 )
		{	Util::print_message("\t$output_file extra tags detected ok!");
			#print Dumper (\%{$Common::course_info{$codcour}{extra_tags}});	
			$file_template =~ s/<<Competences>>/<<CompetencesForCS>>/g;
			my $extra_txt = "\\item \\textbf{<<CompetencesForEngineering>>} \n";
			#Util::print_message("OutcomesForOtherContent$lang=".$Common::course_info{$codcour}{extra_tags}{"OutcomesForOtherContent$lang"});
			my $EnvforOutcomes = $Common::config{EnvforOutcomes};
			$extra_txt .= "\\begin{$EnvforOutcomes}\n$Common::course_info{$codcour}{$lang}{extra_tags}{OutcomesForOtherContent}\\end{$EnvforOutcomes}\n";
			$file_template =~ s/--OUTCOMES-FOR-OTHERS--/$extra_txt/g;
			#$extra_txt .= 
			#exit;
		}
		else{	$file_template =~ s/--OUTCOMES-FOR-OTHERS--//g;}
	}
	$file_template = Common::ExpandTags($file_template, $lang);
	for(my $i = 0 ; $i < 2; $i++ )
	{
	    $file_template = Common::replace_tags_from_hash($file_template, "--", "--", %map);
	    $file_template = Common::translate($file_template, $lang);
	}
	my $InTexDir = Common::GetExpandedTemplateWithLang("InTexDir", $lang);
	#Util::print_message("InTexDir=$InTexDir"); exit;
	# TODO Pending er
	$file_template =~ s/<IN_TEX_DIR>/$InTexDir/g;
	my $InStyDir = Common::GetExpandedTemplateWithLang("InStyDir", $lang);
	$file_template =~ s/<IN_STY_DIR>/$InStyDir/g;

	#file_template =~ s/--.*?--//g;
	if(-e $output_file)
    {	system("rm $output_file");	}
	Util::write_file($output_file, $file_template);
	#Util::print_message("Generating $output_file ok!");	exit;
	#Util::print_message("genenerate_syllabus_output_tex_file: ".Util::green($codcour)."\n\n");
}

sub read_sumilla_template()
{
	return;
	my $syllabus_file = Common::GetTemplate("in-syllabus-template-by-program-file");
	$Common::config{sumilla_template} = "";
	if(-e $syllabus_file)
	{	Util::print_message("Reading ... \"$syllabus_file\"");
	    $Common::config{sumilla_template} = Util::read_file($syllabus_file);
	}
	else
	{	Util::print_warning("It seems that you forgot the syllabus program template file ... \"$syllabus_file\"");}

	$syllabus_file = Common::GetTemplate("in-syllabus-template-by-program-by-cycle-file");
	if(-e $syllabus_file)
	{	Util::print_message("Reading ... \"$syllabus_file\"");
		$Common::config{sumilla_template} = Util::read_file($syllabus_file);
	}
	else
	{	Util::print_warning("It seems that you forgot the syllabus program template for this cycle ... \"$syllabus_file\"");}

	if($Common::config{sumilla_template} eq "")
	{		Util::print_error("It seems that you forgot the template sumilla file ... \"$syllabus_file\"");   }
}

sub read_syllabus_template($)
{
	my ($lang) = (@_);
	$Common::config{syllabus_template} = "";
	my $syllabus_file = "";
	my @syllabi_to_search = ("in-syllabus-template-by-institution-file",
							 "in-syllabus-template-by-program-file",
							 "in-syllabus-template-by-program-by-cycle-file",
							);
	my @explaining_text = ("for this institution", "for this program", "for this program in this cycle");
	my @searching_paths = ();
	my $count = 0;
	foreach my $file (@syllabi_to_search)
	{
		$syllabus_file = Common::GetExpandedTemplateWithLang($file, $lang);
		if(-e $syllabus_file)
		{	Util::print_message(Util::yellow("#$count: I found syllabus-template at:")." \"$syllabus_file\"");
			$Common::config{syllabus_template} 		= Util::read_file($syllabus_file);
			$Common::config{syllabus_template_file} = $syllabus_file;
		}
		else
		{	Util::print_message("#$count: It seems that you forgot the syllabus template file ".Util::yellow($explaining_text[$count]).": ($syllabus_file)");
			push(@searching_paths, $syllabus_file);
		}
		$count++;
	}
	if($Common::config{syllabus_template} eq "")
	{		Util::print_message(Util::red("#4 It seems that you forgot the template for syllabus file ... \"$syllabus_file\""));   
			Util::print_message("I was looking at:");
			for(my $i = 0 ; $i < $count ; $i++)
			{	Util::print_message("$syllabi_to_search[$i] -> $searching_paths[$i] ...");
			}
			exit;
	}
	if( $Common::config{syllabus_template} =~ m/\\begin\{evaluation\}\s*\n((?:.|\n)*?)\n\\end\{evaluation\}/g )
	{
		$Common::config{general_evaluation} = $1;
		$Common::config{syllabus_template}  =~ s/\\begin\{evaluation\}\s*\n(?:.|\n)*?\n\\end\{evaluation\}/--EVALUATION--/;
		Util::print_message("File General Evaluation detected ok!");
	}
	else
	{
	    Util::print_error("It seems you did not write General Evaluation Criteria on your Syllabus template (See file: $syllabus_file) ...");
	}
}

sub read_all_syllabi_fields()
{
	Util::precondition("parse_courses");
	my $lang = $Common::config{language_without_accents};
	Util::print_message("\n".Util::yellow("read_all_syllabi_fields-"));
	my $count_courses 	= 0;
	for(my $semester = $Common::config{SemMin}; $semester <= $Common::config{SemMax}; $semester++)
	{
		foreach my $codcour (@{$Common::courses_by_semester{$semester}})
		{
			my $codcour_label = Common::unmask_codcour($codcour);
			foreach my $lang (@{$Common::config{SyllabusLangsList}})
			{
				my %map 			  = read_syllabus_info($codcour, $semester, $lang, 0);
				$map{AREA}			  = $Common::config{area};
				%{$Common::course_info{$codcour}{$lang}{map}} = %map;
				#Util::print_message("Common::course_info{$codcour}{$lang}{map}");
				#print Dumper(\%map); 		exit;
			}
		}
	}
	#Util::print_message("");
	Util::check_point("read_all_syllabi_fields");
}

sub read_information_for_all_syllabi()
{
	my $lang = $Common::config{language_without_accents};
	Common::read_faculty();
	Common::read_distribution();
	#Common::regenerate_distribution();
	Common::sort_faculty_list();
	Common::read_aditional_info_for_silabos(); # Days, time for each class, etc.

	# It generates all the sillabi
	read_sumilla_template();   					# 1st Read template for sumilla
	read_syllabus_template($lang);  			# 2nd Read the syllabus template
	Common::read_specific_evaluacion_info();	# 3rd Read specific evaluation if exist !
	read_all_syllabi_fields();
}

sub generate_information_for_all_syllabi()
{
	my $lang = $Common::config{language_without_accents};
	generate_tex_syllabi_files();
	generate_syllabi_include();					# File to include all the syllabus
	generate_course_general_info($lang); 		# 4th Generate files containing Prerequisites, etc
	generate_dot_maps_for_all_courses($lang);   # 5th Generate dot files
	
 	#gen_batch_to_compile_syllabi($lang);
	Util::print_message(Util::yellow("Book of syllabi ..."));
	foreach my $lang (@{$Common::config{SyllabusLangsList}})
	{
	    gen_book("Syllabi", "../syllabi/", "", $lang);
	    if( $Common::config{flags}{DeliveryControl} && $Common::config{flags}{DeliveryControl} == 1 )
	    {	gen_book("Syllabi", "../pdf/", "-delivery-control", $lang);
	    }
	}
}
# ok, Here we generate syllabi, prerequisitite files
sub process_syllabi()
{
	read_information_for_all_syllabi();
	generate_information_for_all_syllabi();
	Util::check_point("process_syllabi");
}

sub generate_tex_syllabi_files(){
	Util::precondition("parse_courses");
	my $lang = $Common::config{language_without_accents};
	# Generate all the syllabi
	
	Util::print_message("\n".Util::yellow("generate_tex_syllabi_files"));
	my $count_courses 	= 0;
	my $OutputTexDir = Common::GetTemplate("OutputTexDir");
	for(my $semester = $Common::config{SemMin}; $semester <= $Common::config{SemMax}; $semester++){
		my $semester_label = Common::format_semester_label_in_plain_text($semester, $lang);
		Util::print_message(Util::yellow("$semester_label"));
		foreach my $codcour (@{$Common::courses_by_semester{$semester}}){
			my $codcour_label = Common::unmask_codcour($codcour);
			foreach my $lang (@{$Common::config{SyllabusLangsList}}){
				#Util::print_message("");
				my $codcour_file_name 	= "$codcour_label-$Common::config{dictionaries}{$lang}{lang_prefix}";
				my $output_file 	  	= "$OutputTexDir/$codcour_file_name.tex";
				my $must_be_regenerated = Util::must_be_regenerated($output_file);
				if( $must_be_regenerated )
				{	printf("%16s", Util::blue("Creating $codcour"));	
				}
				my $highlighted_text  = Util::highlight_filename($output_file);
				my %map				  = %{$Common::course_info{$codcour}{$lang}{map}};
				if( $must_be_regenerated ){
					Util::print_message("\t$Util::icons{check} $highlighted_text ...".$map{PROFESSOR_ERROR});
					genenerate_syllabus_output_tex_file($codcour_label, $Common::config{syllabus_template}, "UNITS_SYLLABUS", $output_file, $lang, %map);
					# Copy bib files
					my $syllabus_bib_file 	  			= Common::GetExpandedTemplateWithLang("InSyllabiContainerDir", $lang)."/$map{IN_BIBFILE}.bib";
					my $relative_path 				= $Common::course_info{$codcour}{relative_path};
					my $syllabus_bib_highlighted 	= Util::HighlightFilenameLangRelativePath($syllabus_bib_file, "$relative_path", "$lang");
					Util::print_message("\t$Util::icons{check} cp $syllabus_bib_highlighted $OutputTexDir/$map{IN_BIBFILE}.bib");
					system("cp $syllabus_bib_file $OutputTexDir");
					
					# Updating dependencies
					Util::update_timestamp_for_dependency( $output_file, $Common::config{syllabus_template_file});
					Util::update_timestamp_for_dependency( $output_file, $map{"INPUT_TEX_FILE_NAME"});
					Util::update_timestamp_for_dependency( $output_file, $map{"INPUT_COMMON_TEX_FILE_NAME"});
					Util::update_timestamp_for_dependency( $output_file, $syllabus_bib_file);
					Util::store_timestamps();
				}
				else
				{	Util::print_message("$Util::icons{clock} ".Util::green("Reusing")." $highlighted_text !");
				}
				#exit;
			}
		}
	}
	#system("chgrp curricula $OutputTexDir/*");
	my $firstpage_file = Common::GetTemplate("in-syllabus-first-page-file");
	my $command = "cp $firstpage_file $OutputTexDir/.";
	Util::print_message($command);
	system($command);
	Util::print_message("generate_tex_syllabi_files ok !");
	Util::check_point("generate_tex_syllabi_files");
}

sub get_hidden_chapter_info($$)
{
	my ($semester, $lang) = (@_);
	my $output_tex .= "\% $semester$Common::config{dictionaries}{$lang}{ordinal_postfix}{$semester} $Common::config{dictionaries}{$lang}{Semester}\n";
	$output_tex .= "\\addtocounter{chapter}{1}\n";
	$output_tex .= "\\addcontentsline{toc}{chapter}{$Common::config{dictionaries}{$lang}{semester_ordinal}{$semester} $Common::config{dictionaries}{$lang}{Semester}}\n";
	$output_tex .= "\\setcounter{section}{0}\n";
	return $output_tex;
}

sub generate_fancy_header_file($)
{
	my ($lang) = (@_);
	my $lang_prefix = $Common::config{dictionaries}{$lang}{lang_prefix};
	my $in_fancy_hdr_file = Common::GetExpandedTemplateWithLang("in-config-hdr-foot-sty-file", $lang);
	my $fancy_hdr_content = Util::read_file($in_fancy_hdr_file);
	$fancy_hdr_content =~ s/<SchoolFullName>/\\SchoolFullName$lang_prefix/g;
	$fancy_hdr_content =~ s/<<Curricula>>/$Common::config{dictionaries}{$lang}{Curricula}/g;
	
	my $out_fancy_hdr_file = Common::GetExpandedTemplateWithLang("out-config-hdr-foot-sty-file", $lang);
	my $highlighted_text = Util::highlight($out_fancy_hdr_file, 
										Common::GetExpandedTemplateWithLang("out-config-hdr-foot-sty-only-file", $lang),
										\&Util::yellow);
	$out_fancy_hdr_file =~ s/<LANG>/$Common::config{dictionaries}{$lang}{lang_prefix}/g;
	Util::print_message("$Util::icons{ok} $highlighted_text ...");
	Util::write_file($out_fancy_hdr_file, $fancy_hdr_content);
}

sub write_book_files($$$)
{
	my ($InBook, $lang, $output_tex) = (@_);
	my $InBookFile     = Common::GetTemplate("in-Book-of-$InBook-main-file");
	system("cp $InBookFile ".Common::GetTemplate("OutputTexDir"));

	my $InBookContent = Util::read_file($InBookFile);
	$InBookContent = Common::ExpandTags($InBookContent, $lang);

	my $OutBookFile = Common::GetTemplate("out-Book-of-$InBook-main-file");
	$OutBookFile = Common::ExpandTags($OutBookFile, $lang);

	my $highlighted_text = Util::highlight(	$OutBookFile, 
											Common::GetExpandedTemplateWithLang("out-Book-of-$InBook-only-file", $lang), 
											\&Util::yellow);
	Util::print_message("$Util::icons{ok} $highlighted_text ok! (write_book_files)");
	$InBookContent = Common::translate($InBookContent, $lang);
	Util::write_file($OutBookFile, $InBookContent);

	my $InBookFaceFile = Common::GetTemplate("in-Book-of-$InBook-face-file");
	$highlighted_text = Util::highlight($InBookFaceFile, "Book-Face.tex", \&Util::yellow);
	my $InBookFaceTxt = Util::read_file($InBookFaceFile);
	$InBookFaceTxt = Common::ExpandTags($InBookFaceTxt, $lang);
	if( system("cp $InBookFaceFile ".Common::GetTemplate("OutputTexDir")) >> 8 == 0 )
	{	Util::print_message("$Util::icons{books} $highlighted_text ".Util::blue("->")." ".Common::GetTemplate("OutputTexDir")." ... ok!");	}

	my $OutputIncludeListFile = Common::GetTemplate("out-$InBook-includelist-file");
	$OutputIncludeListFile = Common::ExpandTags($OutputIncludeListFile, $lang);

	$highlighted_text = Util::highlight($OutputIncludeListFile, 
										Common::GetExpandedTemplateWithLang("pdf-syllabi-includelist-only-file", $lang),
										\&Util::yellow);
	Util::print_message("$Util::icons{ok} $highlighted_text ok! (write_book_files)");
	Util::write_file($OutputIncludeListFile, $output_tex);
	generate_fancy_header_file($lang);
}

# ok
# GenSyllabi::gen_book("Syllabi", "syllabi/", "");
# GenSyllabi::gen_book("Syllabi", "../pdf/", "-delivery-control", $lang);
sub gen_book($$$$)
{
	my ($InBook, $prefix, $postfix, $lang) = (@_);
	Util::precondition("set_global_variables");

	my $output_tex = "% Generated by gen_book($InBook, $prefix, $postfix, $lang)\n";
	#$output_tex .="rm *.ps *.pdf *.log *.dvi *.aux *.bbl *.blg *.toc\n\n";
	my $count = 0;
	for(my $semester = $Common::config{SemMin}; $semester <= $Common::config{SemMax} ; $semester++)
	{
		$output_tex .= get_hidden_chapter_info($semester, $lang);
		foreach my $codcour (@{$Common::courses_by_semester{$semester}})
		{
		    my $codcour_label = Common::unmask_codcour($codcour);
		    #-$Common::config{dictionaries}{$lang}{lang_prefix}.tex";
			my $course_name  = Common::prepare_text_for_latex($Common::course_info{$codcour}{$lang}{course_name});
		    $output_tex 	.= "\\includepdf[pages=-,addtotoc={1,section,1,{$codcour. $course_name},$codcour-$Common::config{dictionaries}{$lang}{lang_prefix}}]";
		    $output_tex 	.= "{$prefix$codcour-$Common::config{dictionaries}{$lang}{lang_prefix}$postfix}\n";
		    $count++;
		}
		$output_tex .= "\n";
	}
	write_book_files("Syllabi", $lang, $output_tex);
# 	Util::print_message("gen_book ($count courses) in $OutputFile OK!");
}

sub gen_book_of_bibliography($)
{
      my ($lang) = (@_);
      Util::precondition("set_global_variables");
      my $count = 0;
      my $output_tex = "";

      for(my $semester = $Common::config{SemMin}; $semester <= $Common::config{SemMax} ; $semester++)
      {
	      $output_tex .= get_hidden_chapter_info($semester, $lang);
	      foreach my $codcour (@{$Common::courses_by_semester{$semester}})
	      {
		      # print "codcour=$codcour ...\n";
		      my $bibfiles = $Common::course_info{$codcour}{short_bibfiles};
		      #print "codcour = $codcour    ";
			  my $course_name = Common::prepare_text_for_latex($Common::course_info{$codcour}{$lang}{course_name});
		      my $sec_title = "$codcour. $course_name";
# 			$sec_title .= "($semester$Common::rom_postfix{$semester} sem)";
		      $output_tex .= "\\section{$sec_title}\\label{sec:$codcour}\n";
		      $output_tex .= "\\begin{btUnit}%\n";
		      $output_tex .= "\\nocite{$Common::course_info{$codcour}{allbibitems}}\n";
		      $output_tex .= "\\begin{btSect}[apalike]{$bibfiles}%\n";
		      $output_tex .= "\\btPrintCited\n";
		      $output_tex .= "\\end{btSect}%\n";
		      $output_tex .= "\\end{btUnit}%\n\n";
		      #$output_tex .= "$Common::course_info{$codcour}{justification}\n\n";
		      $count++;
	      }
	      $output_tex .= "\n";
      }
      write_book_files("Bibliography", $lang, $output_tex);
      Util::print_message("gen_book_of_bibliography ($count courses) OK!");
}

# ok
sub gen_book_of_descriptions($)
{
      my ($lang) = (@_);
      Util::precondition("set_global_variables");
      my $output_tex = "";
      my $count = 0;
      for(my $semester = $Common::config{SemMin}; $semester <= $Common::config{SemMax} ; $semester++)
      {
	      $output_tex .= get_hidden_chapter_info($semester, $lang);
	      foreach my $codcour (@{$Common::courses_by_semester{$semester}})
	      {
		      #Util::print_message("codcour = $codcour    ");
		      #my $codcour_label = Common::unmask_codcour($codcour);
		      my $sec_title = "$codcour. $Common::course_info{$codcour}{$lang}{course_name}";
  # 			$sec_title 	.= "($semester$Common::config{dictionary}{ordinal_postfix}{$semester} ";
  # 			$sec_title 	.= "$Common::config{dictionary}{Semester})";
		      $output_tex .= "\\section{$sec_title}\\label{sec:$codcour}\n";
		      $output_tex .= "$Common::course_info{$codcour}{$lang}{justification}{txt}\n\n";
		      $count++;
	      }
	      $output_tex .= "\n";
      }
      write_book_files("Descriptions", $lang, $output_tex);
      Util::print_message("gen_book_of_descriptions ($count courses) OK!");
}

sub generate_team_file($)
{	
	my ($lang) = (@_);
	my $TeamContentBase 	= Util::read_file(Common::GetTemplate("InProgramDir")."/team.tex");
	my $OutputTeamFileBase	= Common::GetTemplate("out-team-file");
	
	my $TeamContent = Common::translate($TeamContentBase, $lang);
	$TeamContent =~ s/<LANG>/$Common::config{dictionaries}{$lang}{lang_prefix}/g;
	my $OutputTeamFile = $OutputTeamFileBase;
	$OutputTeamFile =~ s/<LANG>/$Common::config{dictionaries}{$lang}{lang_prefix}/g;
	Util::print_message("Generating $OutputTeamFile ok ...");
	Util::write_file($OutputTeamFile, $TeamContent);
}

# # ok
# sub gen_list_of_units_by_course()
# {
# 	Util::precondition("set_global_variables");
# 	my $file_name = Common::GetTemplate("out-list-of-unit-by-course-file");
# 	my $output_tex = "";
# 	my $count = 0;
# 	for(my $semester = $Common::config{SemMin}; $semester <= $Common::config{SemMax} ; $semester++)
# 	{
# 		$output_tex .= get_hidden_chapter_info($semester);
# 		foreach my $codcour (@{$Common::courses_by_semester{$semester}})
# 		{
# 			#my $codcour_label 	= Common::unmask_codcour($codcour);
# 			my $i = 0;
# 			my $sec_title = "$codcour. $Common::course_info{$codcour}{$Common::config{language_without_accents}}{course_name}";
#  			#$sec_title 	.= "($semester$Common::config{dictionary}{ordinal_postfix}{$semester} ";
#  			#$sec_title 	.= "$Common::config{dictionary}{Semester})";
# 			$output_tex .= "\\section{$sec_title}\\label{sec:$codcour}\n";
# 			#for($i = 0 ; $i < $Common::course_info{$codcour}{outcomes}{count}; $i++)
# 			$output_tex .= "\\subsection{Resultados}\n";
# 			$output_tex .= "\\begin{itemize}\n";
# 			my $outcomes_txt = "";
# 			foreach my $outcome_key (@{$Common::course_info{$codcour}{outcomes}{$version}{array}}) # Sequential to list later
# 			{
# 				my $bloom 	= $Common::course_info{$codcour}{outcomes}{$version}{$outcome_key};
# 				$outcomes_txt  .= "\\item \\ref{out:Outcome$outcome_key}) \\Outcome$outcome_key"."Short [$bloom, ~~~~~]\n";
# 			}
# 			if( $Common::course_info{$codcour}{outcomes}{count} == 0 )
# 			{	$output_tex .= "\t\\item $Common::config{dictionary}{None}\n";	}
# 			$output_tex .= $outcomes_txt;
# 			$output_tex .= "\\end{itemize}\n\n";
#
# 			$output_tex .= "\\subsection{Unidades}\n";
# 			$output_tex .= "\\begin{itemize}\n";
# 			my $units_txt = "";
# 			for($i = 0 ; $i < $Common::course_info{$codcour}{n_units}; $i++)
# 			{
# 			      $units_txt .= "\t\\item $Common::course_info{$codcour}{units}{unit_caption}[$i], ";
# 			      $units_txt .= "$Common::course_info{$codcour}{units}{hours}[$i] $Common::config{dictionary}{hrs}, ";
# 			      $units_txt .= "[$Common::course_info{$codcour}{units}{bloom_level}[$i], ~~~~~]\n";
# 			}
# 			#if( $Common::course_info{$codcour}{n_units} == 0 )
# 			if( $i == 0 )
# 			{	$units_txt = "\t\\item $Common::config{dictionary}{None}\n";	}
# 			$output_tex .= $units_txt;
# 			$output_tex .= "\\end{itemize}\n\n";
# 			$count++;
# 		}
# 		$output_tex .= "\n";
# 	}
# 	Util::write_file($file_name, $output_tex);
# 	system("cp ".Common::GetTemplate("in-Book-of-units-by-course-main-file")." ".Common::GetTemplate("OutputTexDir"));
# 	system("cp ".Common::GetTemplate("in-Book-of-units-by-course-face-file")." ".Common::GetTemplate("OutputTexDir"));
# 	Util::print_message("gen_list_of_units_by_course $file_name ($count courses) OK!");
# }

sub generate_formatted_syllabus($$$$)
{
	my ($codcour, $source, $target, $lang) = (@_);
	my $active_version = $Common::config{OutcomesVersion};
	my $source_txt = Util::read_file($source);

	my $course_name = Common::prepare_text_for_latex($Common::course_info{$codcour}{$lang}{course_name});
	my $course_type = $Common::config{dictionary}{$Common::course_info{$codcour}{course_type}};
	my $header      = "\n\\course{$codcour. $course_name}{$course_type}{$codcour}\n";
	$header        .= "% Source file: $source\n";
	my $newhead 	= "\\begin{syllabus}\n$header\n\\begin{";
	$source_txt 	=~ s/\\begin\{syllabus\}\s*((?:.|\n)*?)\\begin\{/$newhead/g;

	foreach my $env (@versioned_environments)
	{
		my $syllabus_in_copy = $source_txt;
		while( $syllabus_in_copy =~ m/\\begin\{$env\}\{(.*?)\}\s*\n((?:.|\n)*?)\\end\{$env\}/g)
		{	my $version = $1;
			my $body = $2;
			if( $version eq $active_version ) # This is a necessary environment
			{	$syllabus_in_copy =~ s/\\begin\{$env\}\{$version\}\s*\n((?:.|\n)*?)\\end\{$env\}/\\begin\{$env\}\n$1\\end\{$env\}/g;	}
			else
			{	$syllabus_in_copy =~ s/\\begin\{$env\}\{$version\}\s*\n((?:.|\n)*?)\\end\{$env\}\s*\n//g;	}
		}
		$source_txt = $syllabus_in_copy;
	}
	while ($source_txt =~ m/\n\n\n/ )
	{		$source_txt =~ s/\n\n\n/\n\n/;		}
	my $highlighted_text = Util::highlight("$source -> $target", "$codcour", \&Util::yellow);
	Util::print_message("$Util::icons{ok} $highlighted_text (OK)");
	Util::write_file($target, $source_txt);
}

sub generate_syllabi_include()
{
	my $lang = $Common::config{language_without_accents};
	Util::print_message(Util::yellow("Generating Syllabi to include ..."));
	my $output_file = Common::GetTemplate("out-list-of-syllabi-include-file");
	my $output_tex  = "";

	$output_tex  .= "%This file is generated automatically ... do not touch !!! (GenSyllabi.pm: generate_syllabi_include()) \n";
	$output_tex  .= "\\newcounter{conti}\n";

	my $OutputTexDir = Common::GetTemplate("OutputTexDir");
	my $ncourses    = 0;
	my $newpage = "";
	for(my $semester = $Common::config{SemMin}; $semester <= $Common::config{SemMax} ; $semester++)
	{
		my $semester_label = Common::format_semester_label_in_plain_text($semester, $lang);
		Util::print_message(Util::yellow("$semester_label"));
		$output_tex .= "\n";
		$output_tex .= "\\addcontentsline{toc}{section}{$Common::config{dictionary}{semester_ordinal}{$semester} ";
		$output_tex .= "$Common::config{dictionary}{Semester}}\n";
		foreach my $codcour ( @{$Common::courses_by_semester{$semester}} )
		{
			#my $codcour_label = Common::unmask_codcour($codcour);
			my $lang 		= Common::GetTemplate("language_without_accents");
			my $lang_prefix	= $Common::config{dictionaries}{$lang}{lang_prefix};
			my $course_fullpath = Common::get_input_syllabus_full_path($codcour, $semester, $lang);
			if( not -e $course_fullpath ){	Util::print_message(Util::red("generate_syllabi_include Error:")." $course_fullpath ");	exit;	}

			generate_formatted_syllabus($codcour, $course_fullpath, "$OutputTexDir/$codcour-orig-$lang_prefix.tex", $lang);
			$course_fullpath =~ s/(.*)\.tex/$1/g;
			$output_tex .= "$newpage\\input{$OutputTexDir/$codcour-orig-$lang_prefix}";
			my $course_name = Common::prepare_text_for_latex($Common::course_info{$codcour}{$lang}{course_name});
			$output_tex .= "% $codcour $course_name\n";
			#if($codcour =~ m/CS2H/g)
			#	{	Util::print_message("GenSyllabi::read_syllabus_info $codcour ...");  exit; }

			$ncourses++;
			$newpage = "\\newpage";
		}
		$output_tex .= "\n";
	}
	Util::write_file($output_file, $output_tex);
	Util::print_message("generate_syllabi_include() OK!");
}

sub generate_course_general_info($)
{
    my ($lang) = (@_);
	my $OutputPrereqDir = Common::GetTemplate("OutputPrereqDir");
	my $OutputFigsDir   = Common::GetTemplate("OutputFigsDir");
	Util::print_message(Util::yellow("generate_course_general_info"));
	for(my $semester = $Common::config{SemMin}; $semester <= $Common::config{SemMax} ; $semester++)
	{
		foreach my $codcour (@{$Common::courses_by_semester{$semester}})
		{
			my $normal_header   = "\\begin{itemize}\n";
			$codcour = Common::unmask_codcour($codcour);
			# Semester: 5th Sem.
			$normal_header .= "\\item \\textbf{$Common::config{dictionary}{Semester}}: ";
			$normal_header .= "$semester\$^{$Common::config{dictionary}{ordinal_postfix}{$semester}}\$ ";
			$normal_header .= "$Common::config{dictionary}{Sem}. ";

			# Credits
			$normal_header .= "\\textbf{$Common::config{dictionary}{Credits}}: $Common::course_info{$codcour}{cr}\n";

			# Hours of this course
			$normal_header .= "\\item \\textbf{$Common::config{dictionary}{HoursOfThisCourse}}: ";
			if($Common::course_info{$codcour}{th} > 0)
			{	$normal_header .= "\\textbf{$Common::config{dictionary}{Theory}}: $Common::course_info{$codcour}{th} $Common::config{dictionary}{hours}; ";	}
			if($Common::course_info{$codcour}{ph} > 0)
			{	$normal_header .= "\\textbf{$Common::config{dictionary}{Practice}}: $Common::course_info{$codcour}{ph} $Common::config{dictionary}{hours}; ";	}
			if($Common::course_info{$codcour}{lh} > 0)
			{	$normal_header .= "\\textbf{$Common::config{dictionary}{Laboratory}}: $Common::course_info{$codcour}{lh} $Common::config{dictionary}{hours}; ";	}
			$normal_header .= "\n";

			my $syllabus_link = "";
			$syllabus_link .= "\t\\begin{htmlonly}\n";
			$syllabus_link .= "\t\\item \\textbf{$Common::config{dictionary}{Syllabus}}:\n";
			$syllabus_link .= "\t\t\\begin{rawhtml}";
			$syllabus_link .= Common::get_syllabi_language_links("\t\t", $codcour)."-";
			$syllabus_link .=  "\t\t\\end{rawhtml}\n";
			$syllabus_link .=  "\t\\end{htmlonly}\n";
			$normal_header .= $syllabus_link;

			my $prereq_txt = "\\item \\textbf{$Common::config{dictionary}{Prerequisites}}: ";
			if($Common::course_info{$codcour}{n_prereq} == 0)
			{	$prereq_txt .= "$Common::config{dictionary}{None}\n";	}
			else
			{
				$prereq_txt .= "\n\t\\begin{itemize}\n";
				foreach my $course (@{$Common::course_info{$codcour}{$lang}{full_prerequisites}})
				{
					$prereq_txt .= "\t\t\\item $course\n";
				}
				$prereq_txt .= "\t\\end{itemize}\n";
			}
			$normal_header .= $prereq_txt;
			$normal_header    .= "\\end{itemize}\n";

			my $output_file      = "$OutputPrereqDir/$codcour";
			Util::write_file("$output_file.tex", $normal_header);
# 			Util::print_message("$codcour, $output_file.tex ok!");

			my $output_tex  = "";
			$output_tex    .= "\\input{$output_file}\n\n";
			my $map_for_course = $Common::svg_in_html;

			#$map_for_course =~ s/<OutputFigsDir>/$OutputFigsDir/g;
			$map_for_course =~ s/<filename>/$codcour/g;
			#$map_for_course =~ s/<WIDHT>/70%/g;
			#$map_for_course =~ s/<HEIGHT>/70%/g;
			$output_tex    .= $map_for_course;
			#$output_tex    .= "\\begin{figure}\n";
			#$output_tex    .= "\\centering\n";
			#$output_tex    .= "\\includegraphics[scale=0.66]{\\OutputFigsDir/$codcour_label}\n";
			#$output_tex    .= "\\caption{Cursos relacionados con xyz \\htmlref{$codcour_label}{sec:$codcour_label}}\n";
			#$output_tex    .= "\\label{fig:prereq:$codcour_label}\n";
			#$output_tex    .= "\\end{figure}\n";

			Util::write_file("$output_file-html.tex", $output_tex);
			my $output_html_file = "$OutputPrereqDir/$codcour-html.tex";
			my $highlighted_text = Util::highlight($output_html_file, "$codcour-html", \&Util::yellow);
			Util::print_message("$Util::icons{ok} Creating $highlighted_text ok!");
		}
	 }
	 #Util::print_error("TODO: XYZ Aqui falta poner varios silabos en idiomas !");
}

sub get_course_dot_map($$$)
{
	my ($codcour, $lang, $course_tpl) = (@_);
	my $min_sem_to_show = $Common::course_info{$codcour}{semester};
	my $max_sem_to_show = $Common::course_info{$codcour}{semester};

	my %local_list_of_courses_by_semester = ();
	push(@{$local_list_of_courses_by_semester{$Common::course_info{$codcour}{semester}}}, $codcour);
	my $prev_courses_dot = "";
	# Map PREVIOUS courses
	foreach my $codprev (@{$Common::course_info{$codcour}{prerequisites_for_this_course}})
	{	
		if( defined($Common::course_info{$codprev}) )
		{	$prev_courses_dot .= Common::generate_course_info_in_dot_with_sem($codprev, $course_tpl, $lang)."\n";	}
		else # Something else ()
		{	$prev_courses_dot .= "\t\"$codprev\"->\"$codcour\";\n";
			next;
			# ! Falta conectar codprev->codcour	
		}
 		my ($output_txt, $regular_course) = Common::generate_connection_between_two_courses($codprev, $codcour, $lang);
		$prev_courses_dot .= $output_txt;
		if($regular_course == 1 )
		{	if(	$Common::course_info{$codprev}{semester} < $min_sem_to_show )
			{	$min_sem_to_show = $Common::course_info{$codprev}{semester} ;	}
			push(@{$local_list_of_courses_by_semester{$Common::course_info{$codprev}{semester}}}, $codprev);
		}
	}
	my $this_course_dot = $course_tpl;
	my %map = ("FONTCOLOR"	  => "black",
				"FILLCOLOR"	  => "yellow",
				"BORDERCOLOR" => "black");
	$this_course_dot = Common::replace_tags_from_hash($this_course_dot, "<", ">", %map);
	$this_course_dot = Common::generate_course_info_in_dot_with_sem($codcour, $this_course_dot, $lang)."\n";
	$this_course_dot =~ s/\s*URL="URL.*?",\s*/ /g;

	# Map courses AFTER this course
	my $post_courses_dot = "";
	foreach my $codpost (@{$Common::course_info{$codcour}{courses_after_this_course}})
	{
		$post_courses_dot .= Common::generate_course_info_in_dot_with_sem($codpost, $course_tpl, $lang)."\n";
		my ($output_txt, $regular_course) = Common::generate_connection_between_two_courses($codcour, $codpost, $lang);
		$post_courses_dot .= $output_txt;
		if($regular_course == 1 )
		{	if(	$Common::course_info{$codpost}{semester} > $max_sem_to_show )
			{	$max_sem_to_show = $Common::course_info{$codpost}{semester} ;	}
			push(@{$local_list_of_courses_by_semester{$Common::course_info{$codpost}{semester}}}, $codpost);
		}
	}
	my $sem_col 		= "";
	my $sem_definitions = "";
	my $same_rank 		= "";
	my $sep 			= "";
	for( my $sem_count = $min_sem_to_show; $sem_count <= $max_sem_to_show; $sem_count++)
	{
		my $sem_label = Common::format_semester_label_in_dot($sem_count, $lang);
		my $this_sem = "\t{ rank = same; $sem_label; ";
		foreach my $one_cour (@{$local_list_of_courses_by_semester{$sem_count}})
		{	$this_sem .= "\"".Common::unmask_codcour($one_cour)."\"; ";		}
		$same_rank .= "$this_sem }\n";
		$sem_col .= "$sep$sem_label";
# 				,fillcolor=black,style=filled,fontcolor=white
		$sem_definitions .= "\t$sem_label [shape=box];\n";
		$sep = "->";
	}
	my $output_tex  = "";
	$output_tex .= "digraph $codcour\n";
	$output_tex .= "{\n";
	$output_tex .= "\tbgcolor=white;\n";
	$output_tex .= "\tcompound=true;\n";
	$output_tex .= "\tcharset=\"UTF-8\"\n";
	$output_tex .= "\t$sem_col;\n";
	$output_tex .= "\n";
	$output_tex .= $sem_definitions;
	if(not $prev_courses_dot eq "")
	{	$output_tex .= "$prev_courses_dot\n";	}

	$output_tex .= "$this_course_dot\n";

	if(not $post_courses_dot eq "")
	{	$output_tex .= "$post_courses_dot\n";	}
	$output_tex .= "$same_rank\n";

	$output_tex .= "}\n";
	return $output_tex;
}

sub generate_course_dot_map($$$)
{
	my ($codcour, $lang, $course_tpl) = (@_);
	my $output_dot_tex  = get_course_dot_map($codcour, $lang, $course_tpl);
	my $output_dot_file = Common::GetTemplate("OutputDotDir")."/$codcour.dot";

	my $semester_label = Common::format_semester_label_in_plain_text($Common::course_info{$codcour}{semester}, $lang);
	my $highlighted_text = Util::highlight($output_dot_file, "$codcour", \&Util::yellow);
	Util::print_message("$Util::icons{ok} ($semester_label) $highlighted_text ok!  ..."); 
	Util::write_file($output_dot_file, $output_dot_tex);

	my $OutputFigsDir 	= Common::GetTemplate("OutputFigsDir");
	$Common::config{"dots_to_be_generated"}	.= "echo \"👍 Generating ".Util::highlight_filename("$OutputFigsDir/$codcour.svg")." ($semester_label)...\";\n";
	#$Common::config{"dots_to_be_generated"}	.= "dot -Tps  $output_dot_file -o $OutputFigsDir/$codcour.ps; \n";
	$Common::config{"dots_to_be_generated"}	.= "dot -Tsvg $output_dot_file -o $OutputFigsDir/$codcour.svg; \n\n";
}

sub generate_dot_maps_for_all_courses($)
{
    my ($lang) = (@_);
	Util::check_point("detect_critical_path");
	my $size = "big";
	my $template_file	= Common::read_dot_template($size, $lang);
	my $course_tpl 		= Util::read_file($template_file);
	Util::print_message(Util::yellow("generate_dot_maps_for_all_courses:"). "$template_file ... ");
	my $OutputDotDir  	= Common::GetTemplate("OutputDotDir");
	#my $OutputFigsDir 	= Common::GetTemplate("OutputFigsDir");
	
	for(my $semester = $Common::config{SemMin}; $semester <= $Common::config{SemMax} ; $semester++)
	{	$Common::config{"dots_to_be_generated"} .= "# Semester #$semester\n";
		foreach my $codcour (@{$Common::courses_by_semester{$semester}})
		{	generate_course_dot_map($codcour, $lang, $course_tpl);
		}
	 }
}

1;
