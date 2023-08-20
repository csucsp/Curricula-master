#!/usr/bin/perl
use Lib::Util;
use Data::Dumper;

#use JSON::XS;
#my $json = JSON::XS->new->utf8->pretty(1);
my %student = (name => "Foo Bar",    email => "foo@bar.com",    gender => undef,
#    classes => ["Chemistry", "Math", "Litreture", ],
    address => { city => "Fooville",    planet => "Earth",    },
);

$student{date}{month}{subfield} = 25;
@{$student{date}{month}{array}} = [10,  {"abc" => 5}];

my %map = ("A" => "AKey", "B" => "BKey", "C" => "CKey");
print Dumper(\%student);
print "**********\n";
print Dumper(\%map);
print "**********\n";
%{$student{map}} = %map;
print Dumper(\%student);
print "**********\n";
my $date = \%{$student{date}};
$date->{day} = 27;
print Dumper(\%student);
#my $output = $json->encode(\%student);
#write_file("test2.txt", $output);

=begin comment
system("more test1.txt test2.txt > test3.txt");
if( Util::need_to_be_regenerated("test3.txt"))
{    print "Modified!\n";   }
else
{   print "Source is the same!\n";    }
=end comment
=cut

my $json_file = "json.txt";
# my json_file = Common::GetTemplate("in-json-file");

#Util::read_timestamps($json_file);
#print Dumper(\%{$Common::config{dependencies}});
#Util::update_source_target_dependency("test3.txt", "GeneralInfo.pm");
#Util::update_source_target_dependency("HotKey.pm", "GeneralInfo.pm");
#Util::update_source_target_dependency("GenSyllabi.pm", "GeneralInfo.pm");
#Util::update_source_target_dependency("test1.txt", "Common.pm");
#Util::update_source_target_dependency("test2.txt", "Common.pm");
#Util::update_source_target_dependency("HotKey.pm", "Common.pm");

#Util::update_source_target_dependency("test3.txt", "GeneralInfo.pm");
#Util::update_source_target_dependency("Common.pm", "GeneralInfo.pm");

#Util::store_timestamps($json_file);

my $a = 5, $b = 4, $c = 0;
if( not $a & $c )
{   print("True");  }
else
{   print("False");  }

