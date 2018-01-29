#!/usr/bin/perl
use 5.010;
use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

plan tests => 1;

use MailClientRYPT;

# Тестирование почтового клиента
ok(1, "test1");
#ToDo tests

MailClient(@ARGV);
