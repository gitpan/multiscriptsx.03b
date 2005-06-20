#!/usr/bin/perl
#####################################################
#
# Sophisticated Executor - Multiscript/Polyscript
#
# This program executes multiscript files 
# in different languages.
#
# Multiscript files contain a scripts separated by tag
#
# This allows multiple scripts to reside in a 
# single file in different versions and languages.
# The individual scripts can be called by language
# or by name as command arguments.
#
# This project is mirrored on sourceforge at
# http://sourceforge.net/projects/sexx/ 
#
# Author Nathan Ross
#
# Copyright 2005 Nathan Ross
# Licensed under the GPL and Artistic Licence
#####################################################

use Getopt::Long;
use IO::Handle;
use IO::File;
use Fcntl;

my $VERSION = ".03";
my $numargs = $#ARGV + 1;
my $appname = $0;

if ($numargs == 0) {
   print "$appname -f [FILENAME] -options ... \n";
   exit(0);
}

my $filename, $help, $getversion;
my @list, @lang, @program;
my $opt_version, $opt_random, $opt_perl, $opt_ruby, $opt_python, $opt_shell;
GetOptions("file|f=s"  => \$filename, 
           "help|h"    => \$help, 
           "random|r"  => \$opt_random, 
           "version|v" => \$getversion, 
	   "pv=s"      => \$opt_version, 
           "perl"      => \$opt_perl, 
           "python"    => \$opt_python, 
           "ruby"      => \$opt_ruby, 
           "shell"     => \$opt_shell, 
           "list=s"    => \@list,
           "lang=s"    => \@lang,
           "prog=s"    => \@program); 

   if ((!$filename) && (!$help) && (!$getversion) && ($#list < 0) &&
       ($#lang < 0) && ($#program < 0)) {
        print "$appname -f [FILENAME] -options ... \n";
        usage();
        exit(0);
        }

   if ($filename) {
       parse_multiscriptfile($filename);
   }
   if ($help) {
       print "$appname [FILENAME]\n";
       usage();
   }
   if ($getversion) {
       print "$appname Version $VERSION\n";
   }
   # argument list 
   if ($#list >= 0) {
       foreach my $item (@list) {
       print "argument list item is $item\n";
       }
   }
   # language list
   if ($#lang >= 0) {
      print "languages ", $#lang + 1, "\n"; 
      foreach my $itemb (@lang) {
      print "language list is $itemb\n";
      }
   }
   # program name list
   if ($#program >= 0) {
      print "Program arguments ", $#program + 1, "\n";
      foreach my $itemc (@program) {
      print "program name is $itemc\n";
      }
   }

sub parse_multiscriptfile() {
my $filename = $_[0];
my $line;
my $i = 0;
my $tmpfilename;          # the tmp filename
my $random;               # temp file random variable name
my $outputflag = 3;
my $key;
my $lang;                 # the script language version
my $program_args;         # the script command line args if defined

open (CODEFILE, $filename) or die "Can't open $filename";
    $tmpfilename = ".tmp.$filename.$$";
    if ($opt_random) {
        srand(time());
        $random = rand();
        $tmpfilename .= $random;
    }
    # print "Creating a new script temp file $tmpfilename\n";
    print "Creating a new script temp file $tmpfilename\n";
    umask 077;
    open (TMPFILE, ">$tmpfilename") or die $!;

    while ($line = <CODEFILE>) {
       # print $line;
       if ($line =~ /^<code>\n/)  {
       # print "Found Code tag\n";
       $outputflag = 0;
       $line = "";
       $lang = "perl";
       }
       elsif ($line =~ /^<code l=["](\S+)["]>/) {
       # this option has not been added
          $lang = $1;
          # print "lang = $lang";
          $outputflag = 0;
          $line = ""
       }
       elsif ($line =~ /^<code l=["](\S+)["] args=["]([\s\S]+)["]>/) {
          $lang = $1;
          $program_args = $2;
          $outputflag = 0;
          $line = "";
       }
   elsif ($line =~ /^<codeversion ver=["]([\s\d\S.]+)["] lang=["]([\S]+)["]>/)    {
              if ($opt_version) {
                  if ($opt_version eq $1) {
                      # print "version $1\n";
                      $line = "";
                      $lang = $2;
                      $outputflag = 0;  
                  }
              } 
       }
       elsif ($line =~ /^(<code ruby>\n)/) {
              if ($opt_ruby) {
                 print "ruby";
                 $outputflag = 0;
                 $line = "";
                 $lang = "ruby"; 
              }
       }
       elsif ($line =~ /(^<\/code ruby>\n)/) {
              if ($opt_ruby) {
                 $outputflag = 2;
                 system("$lang $tmpfilename > out");
                 seek(TMPFILE, 0, 0);
                 truncate(TMPFILE, 0);
              }
       }
       elsif ($line =~ /(^<code python>\n)/) {
               if ($opt_python) {
                  # print "found the start python tag\n";
                  $outputflag = 0;
                  $lang = "python";
                  $line = "";
               } 
       }
       elsif ($line =~ /(^<\/code python>\n)/) {
             $outputflag = 2;
             # print "found the end python code tag $outputflag\n";
             system("$lang $tmpfilename");
             seek(TMPFILE, 0, 0);
             truncate(TMPFILE, 0);
       }
       elsif ($line =~ /(^<\/code>\n)/) {
             $outputflag = 2;
             # print "found the end code tag $outputflag\n";
             if ($program_args) {
                system("$lang $tmpfilename $program_args");
             }
             else
             {
                system("$lang $tmpfilename");
             }
             $program_args = "";
             seek(TMPFILE, 0, 0);
             truncate(TMPFILE, 0);
       }
       else
       {
           # print "line $line $outputflag\n";
           if ($outputflag == 0) {
              print TMPFILE $line;
           }
       }
       $i++;
      }
# print "running the script\n";
# system("perl $tmpfilename");
close(CODEFILE);
close(TMPFILE);
unlink($tmpfilename);
}

sub usage() {
    print "  Mulitscript Executor \n";
    print "  This program will execute a multiscript file \n";
    print "  A multiscript file contains multiple script files ";
    print "dillineated by tags. \n\n";
    print "  Program Arguments: \n";
    print "  -file    -f     filename\n";
    print "  -help    -h     help\n";
    print "  -version -v     program version\n";
    print "  -random  -r     randomize temp filename\n";
    print "  -pv             run script version\n";
    print "  -python         run python\n";
    print "  -perl           run perl\n";
    print "  -ruby           run ruby\n";
    print "  -shell          run shell\n";
    print "  -prog           program name list to execute \n";
    print "  -list           program argument list to execute \n";
    print "  -lang           script language list to execute\n";
}

# POD
=head1 NAME
sx.pl
=head1 DESCRIPTION
- a Perl script that allows for multi script programming. The program will allow Perl, Python, Ruby or Shell or any other language to coexist in the same script. The scripts can be given version attributes and are dillineated by tags.  This program will run a multiscript program according to command options. 
=head1 README
The project page is mirrored on sourceforge.net at http://sourceforge.net/projects/sexx.
=pod SCRIPT CATEGORIES
CPAN
CPAN/Language
Educational:ComputerScience
=cut
