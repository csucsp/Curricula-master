#!/usr/bin/perl -w
use strict;
use scripts::Lib::Common;

my $text = Util::read_file("../Curricula.in/lang/Espanol/cycle/2017-I/Syllabi/GeneralEducation/GH2009.tex");

$text =~ s/\\course\{GH2009. Perú ¿país industrial\?\}/\\section\{Yes!\}/g;

# if($text =~ m/\\course\{(.*?)\}\{(.*?)\}\{(.*?)\}/g)
# {
#     my ($course_name, $course_type, $codcour) = ($1, $2, $3);
# #     ($course_name, $course_type, $codcour)    = (Common::replace_special_chars($course_name), Common::replace_special_chars($course_type), Common::replace_special_chars($codcour));
#     my $syllabus_head  = "\n\\section{$course_name ($course_type)}\\label{sec:$codcour}\n";
# 
#     $text =~ s/\\course\{$course_name\}\{$course_type\}\{$codcour\}/$syllabus_head/g;
#     print ".";
# }

Util::write_file("temp/output.tex", $text);
1;