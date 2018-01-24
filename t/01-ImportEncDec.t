#!/usr/bin/perl
use 5.010;
use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

plan tests => 7;

use EncDecRYPT;

# Тестирование наложения ключа(ГАММЫ)
my $msg = "11";	# 00110001 00110001
my $key = "22";	# 00110010 00110010
my $waited_msg_xor = pack("B*", '0000001100000011');

#say 'message = ', $msg,	' bytemsg = ', unpack "B*", $msg;
#say '    key = ', $key,	' bytekey = ', unpack "B*", $key;
#say ' waited = ', $waited_msg_xor,	' bytewaited = ', unpack "B*", $waited_msg_xor;

my $msg_xor = EncDecRYPT::EncDec($msg, $key);
is($msg_xor, $waited_msg_xor, "Encrypt message");
$msg_xor = EncDecRYPT::EncDec($msg_xor, $key);
is($msg_xor, $msg, "Decrypt message");

# проверка undef
is(EncDec(undef, $key), undef, "EncDec undef msg");
is(EncDec($msg, undef), undef, "EncDec undef key");
is(EncDec(undef, undef), undef, "EncDec undef all");

# Тестирование импорта
no EncDecRYPT;
use EncDecRYPT qw/EncDec/;

$msg_xor = EncDec($msg, $key);
is($msg_xor, $waited_msg_xor, "Encrypt message imported EncDec");
$msg_xor = EncDec($msg_xor, $key);
is($msg_xor, $msg, "Decrypt message imported EncDec");
