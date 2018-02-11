#!/usr/bin/env perl

use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use utf8;
use MailClientRYPT;

my ($login, $password);
# Если переданы аргументы забираем их как логин и пароль
if (@ARGV) {
	$login = $ARGV[0];
	$password = $ARGV[1];
}
else { # не передано аргументов запрашиваем логин и пароль
	print "\nДля подключения к почтовому серверу введите логин и пароль:\n";
	print "Логин - ";
	$login = <STDIN>;
	chomp($login);
	print "Пароль - ";
	$password = <STDIN>;
	chomp($password);
}

# передаем полученные данные
MailClient($login, $password);
