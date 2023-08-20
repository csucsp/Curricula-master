package Util;
use strict;
use Carp::Assert;
use Text::Balanced qw<extract_bracketed>;
use Array::Utils qw(:all);
use File::Spec;

# https://unicode-table.com/en/sets/check/
our %icons;
$icons{ok}   = "\x{1F44D}";		# 👍
$icons{X}    = "\x{274C}";		# ❌
$icons{link} = "\x{1F517}";		# 🔗
$icons{star} = "\x{1F31F}";		# 🌟
$icons{check}= "\x{2705}";		# ✅
$icons{books}= "\x{1F4DA}";     # 📚
$icons{bulb} = "\x{1F4A1}";		# 💡
$icons{clock}= "\x{23F0}";		# ⏰
$icons{plus} = "\x{2795}";		# ➕
$icons{eye} = "\x{1F441}";		# 👁


our %control	= ();
# ok
sub precondition($)
{
	my ($key) = (@_);
	if(not defined($control{$key}))
	{
		Util::print_color("precondition $key is not fulfilled ...")
	}
	assert(defined($control{$key}));
	assert($control{$key} == 1);
}

# ok
sub check_point($)
{
	my ($key) = (@_);
	$control{$key} = 1;
}

# ok
sub uncheck_point($)
{
	my ($key) = (@_);
	$control{$key} = 0;
}

sub is_checked_point($)
{
	my ($key) = (@_);
	if(defined($control{$key}) and $control{$key} == 1)
	{    return 1;          }
	return 0;
}

sub intersection($$)
{
	my ($list1, $list2) = (@_);
	$list1 =~ s/ //g;	$list2 =~ s/ //g;
	my @a1 = sort { lc($a) cmp lc($b) } split(",", $list1);
	my @a2 = sort { lc($a) cmp lc($b) } split(",", $list2);
	my @isect = sort { lc($a) cmp lc($b) } intersect(@a1, @a2);
	return join(",", @isect);
}

# ok
sub print_message($)
{
	my ($msg) = (@_);
	print "$msg\n";
}

# ok
sub print_error($)
{
	my ($msg) = (@_);
	print_soft_error("** ERROR ** :$msg\n");
	assert(0);
	exit;
}

# https://pypi.python.org/pypi/colorama
sub print_soft_error($)
{
	my ($msg) = (@_);
	print "\x1b[41m$msg\x1b[0m\n";
}

# https://pypi.python.org/pypi/colorama
sub print_warning($)
{
	my ($msg) = (@_);
	print "\x1b[44m\x1b[30m ** WARNING ** : $msg\x1b[0m\n";
}

# https://pypi.python.org/pypi/colorama
sub print_success($)
{
	my ($msg) = (@_);
	print "\x1b[44m $msg\x1b[0m\n";
}

sub color($$$)
{
	my ($pre, $msg, $post) = (@_);
	return "$pre$msg$post";
}

sub yellow($)
{	my ($msg) = (@_);
	return color("\x1b[43m\x1b[30m", $msg, "\x1b[0m");
}

sub red($)
{	my ($msg) = (@_);
	return color("\x1b[41m", $msg, "\x1b[0m");
}

sub blue($)
{	my ($msg) = (@_);
	return color("\x1b[44m", $msg, "\x1b[0m");
}

sub green($)
{	my ($msg) = (@_);
	return color("\x1b[42m\x1b[30m", $msg, "\x1b[0m");
}

# ok # https://pypi.python.org/pypi/colorama
sub print_color($)
{
	my ($msg) = (@_);
	print yellow($msg)."\n";
}

#  ok
sub halt($)
{
	my ($msg) = (@_);
	print_error($msg);
	assert(0);
	exit;
}

sub get_ang_base($)
{
	my ($nareas) = (@_);
	return (2*3.14159)/$nareas;
}

sub rotate($$$)
{
	my ($x, $y, $ang)  = (@_);
	my ($xp,$yp) = ($x*cos($ang)-$y*sin($ang), $x*sin($ang)+$y*cos($ang));
	return ($xp,$yp);
}

sub round($)
{
	my ($f) = (@_);
	my $txt = "$f";
	if( $txt =~ m/(.*?\...)/)
 	{	return $1;	}
 	return $f;
}

sub calc_percent($$)
{
	my ($part, $total) = (@_);
	my $percent = 100 * $part/$total;
	if($percent =~ m/(.*\..).*/)
	{	$percent  = $1;
	}
	return $percent;
}

sub highlight($$$)
{	
	my ($str, $substr, $function) = (@_);
	my $newstr = $function->($substr);
	$str =~ s/$substr/$newstr/g;
	return $str;
}

sub highlight_filename($)
{
	my ($fullname) = (@_);
	if( $fullname =~ m/.*\/(.*)\s*/g )
	{
		my $OnlyFile = $1;
		return highlight($fullname, $OnlyFile, \&Util::yellow);
	}
	return $fullname;
}

sub highlight_FilenameAndLang($$)
{
	my ($fullname, $lang) = (@_);
	$fullname = highlight_filename($fullname);
	$fullname = highlight($fullname, "$lang", \&Util::yellow);
	return $fullname;
}

sub HighlightFilenameLangRelativePath($$$)
{
	my ($fullname, $relative_path, $lang) = (@_);
	$fullname = highlight_filename($fullname);
	$fullname = highlight($fullname, "$lang", \&Util::yellow); 
	$fullname = highlight($fullname, "$relative_path", \&Util::green); 
	return $fullname;
}

our $flag = 0;
# ok
sub read_file($)
{
	my ($filename) = (@_);
	if( -r "$filename")
	{
		open(IN, "<$filename");
		my @lines = <IN>;
		close(IN);
		return join("", @lines);
	}
	Util::print_error("read_file: something wrong with this file:".Util::red($filename).". It does not open");
}

sub GetPathAndFile($)
{
	my ($fullname) = (@_);
	my ($volume, $path, $file) = File::Spec->splitpath( $fullname );
	return ($path, $file);
}

sub trim_comments($)
{
	my ($txt) = (@_);
	my @lines = split("\n", $txt);
	my $cline = 0;
	foreach (@lines)
	{
		$lines[$cline] =~ s/^%.*$//g;
		pos($lines[$cline])   =  0;
		while( $lines[$cline] =~ m/(.)%(.*)/g )
		{
			my $matchpos = $-[0];
			my ($char, $comment) = ($1, $2);
			if( not $char eq "\\" )
			{
				$lines[$cline] =~ s/$char%$comment/$char/g;
			}
			#Util::print_message("Entró ! ($matchpos)$cline:$char%$comment");
			pos($lines[$cline]) = $matchpos + 1;
			#exit;
		}
		$cline++;
	}
	return join("\n", @lines);
}
# ok

sub write_file($$)
{
	my ($filename, $txt) = (@_);
	open(OUT, ">$filename") or die Util::halt("write_file: $filename does not open");
	print OUT $txt;
	close(IN);
	system("chmod 755 $filename");
	#system("chgrp curricula $filename");
}

my @list_of_files_to_gen_fig;
sub write_file_to_gen_fig($$)
{
    # First: write this file
	my ($fullname, $txt) = (@_);
	
	$fullname =~ m/(.*)\/(.*)\.tex/;
	my ($dir, $filename) = ($1, $2);

	my $highlighted_text = Util::highlight($fullname, $filename, \&Util::yellow);
	print_message("$Util::icons{ok} Writing file: $highlighted_text OK!");
	write_file($fullname, $txt);

	# Second: generate the main to gen the fig
	my $main_txt = $Common::config{main_to_gen_fig};
	$main_txt =~ s/<OUTPUT_FILE>/$filename/g;
	$main_txt =~ s/<ENCODING>/$Common::config{tex_encoding}/g;
	$main_txt =~ s/<LANG_FOR_LATEX>/$Common::config{LANG_FOR_LATEX}/g;

	my $main_file 			= "$filename-main";
	my $main_file_fullname 	= "$dir/$main_file.tex";
	$highlighted_text = Util::highlight($main_file_fullname, $main_file, \&Util::yellow);
	print_message("$Util::icons{ok} Writing file: $highlighted_text OK!");
	write_file("$dir/$filename-main.tex", $main_txt);
	
    # Third: register this main to compile later
	push(@list_of_files_to_gen_fig, $filename);
}

sub generate_batch_to_gen_figs($)
{
	my ($output_file) = (@_);
    #print_message("generate_batch_to_gen_figs($output_file)");
	my $output_txt  = "";
	foreach my $fig_file (@list_of_files_to_gen_fig)
	{
                $output_txt .= "latex main-to-gen-fig-$fig_file\n";
                #$output_txt .= "dvips -Ppdf -Pcmz -o $fig_file.ps main-to-gen-fig-$fig_file\n";
                $output_txt .= "dvips -o $fig_file.ps main-to-gen-fig-$fig_file\n";
                $output_txt .= "ps2eps -f $fig_file.ps\n";
                $output_txt .= "mv $fig_file.eps ../fig/.\n";
                $output_txt .= "\n";
	}
    write_file($output_file, $output_txt);
    system("chmod 774 $output_file");
    print_message("generate_batch_to_gen_figs($output_file) OK!");
}

my ($start_time, $end_time) = ("", "");
sub begin_time()
{	$start_time	= time();	}

sub end_time()
{	$end_time	= time();	}

sub print_time_elapsed()
{
	Util::end_time();
	my $time_elapsed 	= $end_time - $start_time;
	Util::print_message("Time elapsed: $time_elapsed seconds ...");
}

sub stop($)
{
	my ($msg) = (@_);
	Util::print_message("Stopping!\n".Util::yellow($msg)."\n");
	exit;
}

use JSON::XS;
my $json = JSON::XS->new->utf8->pretty(1);
   $json->canonical(1);
my $no_timestamp = "-";
sub get_timestamp($)
{
	my ($file) = (@_);
	if( -e $file )
	{	return localtime((stat($file))[9]);	
		#return localtime(ctime(stat($file)->mtime));	
	}
	return $no_timestamp;
}


sub update_timestamp_for_dependency($$)
{
	my ($target_file, $source_file) = (@_);
	# First add %{$config{dependencies}{map}} = {$source_file1, $source_file2, $source_file3};
	$Common::config{dependencies}{map}{$target_file}{$source_file}  = get_timestamp($source_file); # invalid now
	# Third  update the timestamp for that source_file
}
sub update_source_target_dependency($$)
{
	my ($source_file, $target_file) = (@_);
	# First add %{$config{dependencies}{map}} = {$source_file1, $source_file2, $source_file3};
	$Common::config{dependencies}{map}{$target_file}{$source_file}  = get_timestamp($source_file);
}

my $verbose = 0;
# TODO: @deprecated
sub has_changed($$)
{
	my ($file, $timestamp)  = (@_);
	if( not -e $file ) # It does not exist
	{	if( $verbose == 1 ) {	Util::print_message("\t$Util::icons{X} ".Util::red("H1.")." ".Util::highlight_filename($file)." ".Util::red("does not exist (or has changed)"));		}
		return 1;
	}
	if( not defined($Common::config{dependencies}{map}{$file}) )
	{	if( $verbose == 1 ) {	Util::print_message("\t$Util::icons{X} ".Util::red("H2.")." ".Util::highlight_filename($file)." ".Util::red("ts NOT modified !"));		}
		return 1;
	}
	my $file_ts = get_timestamp($file);
	if( $timestamp eq $file_ts )
	{	if( $verbose == 1 ) {	Util::print_message("\t$Util::icons{ok} ".Util::red("H3.")." ".Util::highlight_filename($file)." ".Util::red("was NOT modified !"));		}
		return 0;
	} # Both have the same timestamp
	if( $verbose == 1 )     {	Util::print_message("\t$Util::icons{X} ".Util::red("H4.")." ".Util::highlight_filename($file)." ".Util::red("has been modified !"));	}
	return 1;
}

#my $regenerate = 1;
sub must_be_regenerated($)
{
	my ($target_file)  = (@_);
	if( $verbose == 1 ) {	Util::print_message("Checking ".Util::highlight_filename($target_file)." ...");		}
	if( not -e $target_file )
	{	if( $verbose == 1 ) {	Util::print_message("$Util::icons{X} ".Util::blue("1. $target_file has changed"));		}
		return 1;
	}
	if( not defined($Common::config{dependencies}{map}{$target_file}) )
	{	if( $verbose == 1 ) {	Util::print_message("$Util::icons{X} ".Util::blue("2. No map for $target_file"));		}
		return 1;	
	}
	if( $verbose == 1 ) 
	{	my $ndependencies 		= keys %{$Common::config{dependencies}{map}{$target_file}};
		if( $ndependencies > 0 )
		{	Util::print_message("$Util::icons{eye} $target_file");	 }
	}
	foreach my $source_file ( keys %{$Common::config{dependencies}{map}{$target_file}} )
	{	
		my $timestamp_saved = $Common::config{dependencies}{map}{$target_file}{$source_file};
		my $timestamp_indisk= get_timestamp($source_file);
		my $check = "$Util::icons{ok}";
		if( not $timestamp_indisk eq $timestamp_saved )
		{	$check = "$Util::icons{X}";	}
		if( $verbose == 1 ) 
		{	Util::print_message(Util::blue("\t3 json=$timestamp_saved, disk=$timestamp_indisk $check ($source_file)"));
		}
		if( not $timestamp_indisk eq $timestamp_saved )
		{	#Util::print_message("$check $target_file\n\t".Util::red("$target_file")." ".Util::red("changed")." json=".Util::red($timestamp_saved).", disk=".Util::red("$timestamp_indisk"));
			return 1;	
		}
	}
	if( $verbose == 1 ) {	Util::print_message("$Util::icons{ok} ".Util::blue("5. $target_file all the dependencioes are ok"));		}
	return 0;
}

sub read_timestamps()
{	my $json_file = Common::GetTemplate("in-json-file");
	Util::print_message("$Util::icons{ok} Reading timestamps: ".highlight_filename($json_file));	
	my $json_tex  	= "";
	if( -e $json_file )
	{	$json_tex	= read_file($json_file);
		%{$Common::config{dependencies}} = eval { %{ decode_json($json_tex) };	}	
	}
}

sub store_timestamps()
{	
	my $json_file = Common::GetTemplate("in-json-file");
	my $output    = eval { $json->encode(\%{$Common::config{dependencies}}); 	};
	my $highlighted_text = Util::highlight_filename($json_file);
	#Util::print_message("$Util::icons{ok} Storing $highlighted_text");
	write_file($json_file, $output);
}

1;
