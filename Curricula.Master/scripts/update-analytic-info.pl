#!/usr/bin/perl -w
use strict;
use Lib::Common;

if( defined($ENV{'CurriculaParam'}))	{ $Common::command = $ENV{'CurriculaParam'};	}
if(defined($ARGV[0])) { $Common::command = shift or Util::halt("There is no command to process (i.e. COUNTRY-AREA-INST)");	}

my ($script, $script_re) = ("", "");

sub insert_analytic_script($)
{
        my ($file) = (@_);
        my $in = Util::read_file($file);
        if( $in =~ m/$script_re<\/BODY>/) # it already contains the script
        {       return 0;        } 
        else
        {       $in =~ s/<\/BODY>/$script<\/BODY>/g;    
                Util::write_file($file, $in);
                return 1;
        }
}

sub update_html_files()
{
        $script = Util::read_file(Common::GetTemplate("in-analytics.js-file"))."\n";
        $script_re = Common::replace_special_chars($script);
        my $dir = Common::GetTemplate("OutputHtmlDir");
        opendir DIR, $dir;
        my @filelist = readdir DIR;
        closedir DIR;
        my $count = 0;
        #insert_analytic_script("$dir/node2.html"); exit;
        Util::print_message("Updating files at: $dir");
        foreach my $htmlfile (sort {$a cmp $b} @filelist)
        {
              if($htmlfile =~ m/.*\.html/)
              {
                    printf("%-80s", "$dir/$htmlfile ...");
                    my $bool = insert_analytic_script("$dir/$htmlfile");
                    if( $bool == 1)     {  ++$count;    print "ok ...($count)! \n";   }
                    else                {               print "         Ignoring ...\n";                          }
                    #exit;
              }
        }
        Util::print_message("\nTotal $count files updated ...                                     ");
}

sub main()
{
        Util::begin_time();
        Common::set_preconfiguration_avoiding_courses();
        Common::set_initial_configuration($Common::command);
        update_html_files();
        Util::print_time_elapsed();
        Util::print_message("update-analytics-info finished ok ...");
}

main();

