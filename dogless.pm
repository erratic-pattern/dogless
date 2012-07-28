#!/usr/bin/perl
package Dogless;
use strict;
use warnings; no warnings 'uninitialized';
use v5.10;
use Getopt::Long;

sub help {
<<__HELP__
Usage: $0 [options] [files]

Interprets dogless programs passed as command line arguments, or from stdin if no files are specified.

Options:

  -d --debug        Enters debug mode, the source code is 
                    printed for each transformation.
  -h --help         This help text

  -i --interval     specifies a decimal interval in seconds to
                    wait between commands
__HELP__
}

#command line options
my ($help, $debug_mode, $interval);

my $any_command;
$any_command = qr/(?:<|>)(??{$any_command})|\$..|\\?.|$/s;

sub run_cmd {
    my ($_, $pre, $post, $s) = @_;
    my ($x, $y, $c);
    if(($c) = /^<(.*)$/p) {
        $pre =~ /\||$/p;
        $pre = run_cmd($c, ${^PREMATCH}, ${^POSTMATCH}, ${^MATCH});
        return "$pre$s$post";
    }
    elsif (($c) = /^>(.*)$/p) {
        $post =~ /\||$/p;
        $post = run_cmd($c, ${^PREMATCH}, ${^POSTMATCH}, ${^MATCH});
        return "$pre$s$post";
    }
    elsif(($x, $y) = /^\$(.)(.)$/s) {
        $_ = "$pre$s$post";
        s/\Q$x\E/$y/;
        return $_;
    }
    elsif (/^"$/) {
        $post =~ /^[^"]*("|$)/p;
        return "$pre$s${^POSTMATCH}";
    }
    elsif (/^\?$/) {
        return reverse "$pre$s$post";
    }
    elsif (/^\^$/) {
        return "$post$s$pre";
    }
    elsif (/^~$/) {
        return "$pre$s$post$pre$s~$post";
    }
    elsif (/^!$/) {
        return '';
    }
    elsif (/^\|$/) {
        return "$pre$s$post";
    }
    elsif (($c) = /^\\?(.)$/sp){
        return "$pre$c$s$post";
    }
    else {
        return "$pre$post";
    }
}

sub interpret {
    my ($_) = @_;
    while (/\|($any_command)/p) {
        say if $debug_mode;
        sleep $interval if defined $interval;
        $_ = run_cmd($1, ${^PREMATCH}, ${^POSTMATCH}, '|');
    }
    return $_;
}


unless (caller) {
    GetOptions ("help|h" => \$help,
                "debug|d" => \$debug_mode,
                "interval|i=f" => \$interval,
               ) or die "Invalid options.";
    say help() and exit if $help;
    print interpret (join '', <>);
}
