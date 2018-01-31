#!/usr/bin/perl
use 5.006;
use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

plan tests => 3;

BEGIN {
    use_ok( 'TablesPRNG' ) || print "Bail out!\n";
    use_ok( 'EncDecRYPT' ) || print "Bail out!\n";
    use_ok( 'MailClientRYPT' ) || print "Bail out!\n";
}

note( "Testing TablesPRNG $TablesPRNG::VERSION, Perl $], $^X" );
note( "Testing EncDecRYPT $EncDecRYPT::VERSION, Perl $], $^X" );
note( "Testing MailClientRYPT $MailClientRYPT::VERSION, Perl $], $^X" );
