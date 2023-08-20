#!/usr/bin/perl -w

use strict;
use Carp::Assert;
use Data::Dumper;
use Lib::Common;
use Lib::GenSyllabi;
use Lib::GeneralInfo;

# ./scripts/create-program.pl Peru     Engineering Espanol IAG USIL Plan2022 2022-I -source=Arequipa-Area-ABC -reuse=Yes
# ./scripts/create-program.pl Peru Computing Espanol CS UCSP Plan2018 2020-I -source=Peru-CS-SPC -reuse=Yes
# ./scripts/create-program.pl Colombia Computing Espanol IS UNAL Plan2021 2023-I -source=Colombia-CS-UNAL -reuse=Yes
my $DefaultSource = "Peru-CS-UCSP";
my $example = 
 "./scripts/create-program.sh Arequipa Disc Espanol Area ABC Plan2021 2022-I -source=Peru-CS-SPC";

my @desired_params = ("country", "discipline", "language", "area", "institution", "plan", "cycle");
my %params;

my %base    = ("country"     => "Peru"     , 
               "discipline"  => "Computing",
               "language"    => "Espanol"  ,
               "area"        => "CS"       , 
               "institution" => "UCSP"      , # SPC
               "plan"        => "Plan2018" ,  # "Plan2021"
               "cycle"       => "2020-I");
my %flags   = ("yes"    => 1, "no"      => 0);

my ($IfDoesntExistDoNothing, $IfDoesntExistCreateIt, $DoesntChangeName) = 
    (1,                      2,                      4);

sub process_params()
{
    my $size = scalar @desired_params;
    #print $size;
    my $i = 0;
    for(; $i < $size; $i++)
    {   if(defined($ARGV[$i])) 
        { $params{$desired_params[$i]} = $ARGV[$i];     }
        else
        {   Util::halt("There is no $desired_params[$i] to process\n(i.e. $example)");
        }
    }
    $Common::command = $DefaultSource;
    $params{"update_template"} = 0;
    $size = scalar @ARGV;

    for(; $i < $size; $i++)
    {   if( $ARGV[$i] =~ m/-(.*)=(.*)/g )
        {   my ($key, $value) = ($1, $2);
            if( $key eq "source" )
            {   $Common::command = $value;  }
            elsif( $key eq "reuse" )  # Reuse, update_template?
            {   $value  = lc $value;
                if( defined($flags{$value}) )
                {   $params{"update_template"} = $flags{$value}; }
                else
                {   Util::print_message("Parameter -reuse=$value not recognized !");  }
            }
        }
    }

    if( $params{cycle} =~ m/(.*)-(.*)/g )
    {   $params{CurriculaVersion} = $1;
        # <CURRICULA_VERSION>/$config{CurriculaVersion}
    }
    else
    {   Util::print_message("Something is wrong ! I couldn't detect CurriculaVersion");    }
}

sub preprocess_file($)
{
    my ($txt) = (@_);
    $txt =~ s/\\newcommand\{\\country\}\{(.*)\\xspace\}/\\newcommand{\\country}{$params{country}\\xspace}/g;
    if( $txt =~ m/\\newcommand\{\\PlanConfig\}\{(.*)\}/g )
    {   my $ConfigFile = Common::replace_special_chars($1);
        $txt =~ s/$ConfigFile/$params{plan}-Sem$params{cycle}.config/g;
    }
    $txt =~ s/<CYCLE>/$params{cycle}/g;
    return $txt;
}

sub create_new_program($)
{
    #print Dumper(\%base);
    #print Dumper(\%params);
    #exit;
    my ($lang) = (@_);
	my @files = (	["InCountryTexDir",                  "Main.tex"                     ],
					["InInstitutionDisciplineConfigDir", "Main.tex"                     ],
					["InProgramDir",                     "Main.tex"                     ],
					["InProgramDir",	                 "program-info.tex"             ],
					["InProgramDir",	                 "team.tex"                     ],
					["InProgramDir",	                 "ack.tex"                      ],
                    ["InProgramDir",	                 "<PLAN>-Sem<CYCLE>.config.tex" ],
                    ["InInstitutionConfigDir",           "syllabus-template.tex"        ],
                    ["InCycleDir",                       "faculty.txt"                  ],
                    ["in-distribution-dir",              "Specific-Evaluation.tex",         $IfDoesntExistCreateIt],
                    ["in-distribution-dir",              "distribution.txt",                $IfDoesntExistCreateIt],
                    ["InAreaConfigDir",                  "All.config"                   ],    
                    ["InAreaConfigDir",                  "Area.config"                  ],
                    ["InInstitutionConfigDir",           "<INST>.config"                ],
                    ["InInstitutionConfigDir",           "<INST>.tex"                   ],
                    ["InTexDir",                         "outcomes-macros.tex"          ],
                    ["InTexDir",                         "other-packages.tex"           ],
                    ["InTexDir",                         "abstract.tex"                 ], 
                    ["InDisciplineConfigDir",            "<DISCIPLINE>.config"          ],
                    ["InCountryDir",                     "country.config"               ],
                    ["InDisciplineTexDir",               "<DISCIPLINE>-acronyms.tex"    ],
                    ["InGeneralAreaDir",                 "<AREA><CURRICULA_VERSION>-dependencies.tex", $DoesntChangeName],
                    ["InTexDir",                         "chap-introduction.tex"],

            # 'description-foreach-prefix.tex' 'copyright.tex'       
				);
	# print Dumper(\@files);
	foreach my $file_info (@files)
	{
		my ($SourceKey, $BaseFile) = @{$file_info};
        my ($WhatToDo) = ($IfDoesntExistDoNothing);
        my $nParam = @{$file_info};
        if( $nParam > 2 )
        {   $WhatToDo = @$file_info[2];  }

        my $SourceFile = Common::ExpandTags($BaseFile, $lang);
        my $TargetFile = $SourceFile;
        if( not $WhatToDo & $DoesntChangeName )
        {   $TargetFile = Common::ExpandTags2($BaseFile, $params{country}, $params{institution}, 
                                            $params{area}, $params{cycle}, 
                                            $params{CurriculaVersion}, $params{language});
        }

		my $SourcePath = Common::GetExpandedTemplateWithLang($SourceKey, $lang); 
		my $TargetPath = Common::GetTemplateForAnotherInstitution($SourceKey, 
                                    $params{country}, $params{institution}, 
                                    $params{area}, $params{cycle}, 
                                    $params{CurriculaVersion}, $params{language});
        # Util::print_message(sprintf("%-30s => SourceFile=%-20s, TargetFile=%-20s", $BaseFile, $SourceFile, $TargetFile));
        # Util::print_message(Util::blue("SourcePath=$SourcePath")."\n".Util::blue("TargetPath=$TargetPath"));
        if( $SourcePath eq $TargetPath )
        {   Util::print_message("  ".Util::green("Both paths are the same !")."   ($SourcePath)");
        }
        if( not -d $TargetPath )
        {   Util::print_message(Util::green("+Creating directory:")."\n   ".Util::green("$TargetPath")); 
            system("mkdir -p $TargetPath");
        }
        if( -e "$SourcePath/$SourceFile" )
        {   
            my $highlighted_text = Util::highlight_filename("$TargetPath/$TargetFile");
            if( -e "$TargetPath/$TargetFile" )
            {   Util::print_message("   $highlighted_text already exists ! ");
            }
            else   
            {   Util::print_message("$Util::icons{ok} ".Util::blue("cp")." $SourcePath/$SourceFile ".Util::blue("=>")." $TargetPath/$TargetFile");
                system(             "cp $SourcePath/$SourceFile $TargetPath/$TargetFile");   
            }
            # Process $TargetPath/$TargetFile
            if( $params{"update_template"} == 1 ) # Reusing templates
            {
                my $newfile_content = Util::read_file("$TargetPath/$TargetFile");
                $newfile_content = preprocess_file($newfile_content);
                Util::write_file("$TargetPath/$TargetFile", $newfile_content);
            }
        }  
        else # Source does not exist
        {
            if( $WhatToDo & $IfDoesntExistCreateIt )
            {   Util::write_file("$TargetPath/$TargetFile", "\n"); 
                Util::print_message(Util::green("+Creating empty file")." $TargetPath/".Util::green("$TargetFile"));     
            }
            else
            {   Util::print_message(Util::red("* Error in source")." ... File $SourcePath/".Util::green("$SourceFile")." ".Util::red("NO existe !"));
            }
        }                        
	}
}

sub print_next_steps()
{
    Util::print_message("./scripts/gen-scripts.pl $params{country}-$params{area}-$params{institution}");
    
}

sub main()
{
    process_params();
    Util::begin_time();
    Common::set_preconfiguration_avoiding_courses();
	Common::setup();
    my $lang = $Common::config{language_without_accents};

    create_new_program($lang);

    print_next_steps();
    Common::print_closing_message();
    # Util::print_message("End !");
}
main();