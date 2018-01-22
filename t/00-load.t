#!/usr/bin/perl
use 5.006;
use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

plan tests => 1;

BEGIN {
    use_ok( 'EncDecRYPT' ) || print "Bail out!\n";
}

diag( "Testing EncDecRYPT $EncDecRYPT::VERSION, Perl $], $^X" );
