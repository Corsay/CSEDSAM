#!/usr/bin/perl
use 5.010;
use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

plan tests => 11;

use EncDecRYPT;

# Подготовка тестовых словарей
=head2
	Первый словарь ключей (не полностью реализованно):
		ключ - конкатенация (с разделением через '-') номера недели, часов и минут (пример: 1-10-06)
		значение - ссылка на хеш, содержащий:
			* номер недели	- weekNum	- значение (1 - 52);
			* часы		- hour	- значение (0 - 23);
			* минуты	- minut	- значение (0 - 59);
			* ключа		- key	- значение (короткая гамма - т.е. если длины не хватает, то вызывать продолжение генерации с ГПСЧ).
		по ключу "ГПСЧ" - ссылка на функцию ГПСЧ, для догенерации ключевой информации
=cut
my $dictOne = {
	"2-10-10" => {
			WeekNum	=> 2,
			hour	=> 10,
			minut	=> 10,
			key	=> "123456",
		},
	"2-10-12" => {
			WeekNum	=> 2,
			hour	=> 10,
			minut	=> 12,
			key	=> "789012",
		},
	"2-10-14" => {
			WeekNum	=> 2,
			hour	=> 10,
			minut	=> 14,
			key	=> "345678",
		},
	"2-10-16" => {
			WeekNum	=> 2,
			hour	=> 10,
			minut	=> 16,
			key	=> "234567",
		},
};
my $keyParamsOne = {
	seconds	=> 10,
	minut	=> 10,
	hour	=> 10,
	day	=> 10,
	month	=> 1,
	year	=> 2018,
	WeekNum	=> 2,
	concat	=> "2-10-10"
};
=head2
	Второй словарь ключей:
		ключ - конкатенация (с разделением через '-') месяца, дня, часов и минут (пример: 12-31-23-59)
		значение - ссылка на хеш, содержащий:
			* месяц		- month	- значение (1 - 12);
			* день		- day	- значение (в рамках конкретного месяца)
			* часы		- hour	- значение (0 - 23);
			* минуты	- minut	- значение (0 - 59);
			* ключ		- key	- значение (полностью сформированная гамма, т.е. если длины не хватает, то выбрать следущий интервал и соответствующий ключ).
=cut
my $dictTwo = {
	"1-10-10-10" => {
			month	=> 1,
			day	=> 10,
			hour	=> 10,
			minut	=> 10,
			key	=> "123456",
		},
	"1-10-10-12" => {
			month	=> 1,
			day	=> 10,
			hour	=> 10,
			minut	=> 12,
			key	=> "789012",
		},
	"1-10-10-14" => {
			month	=> 1,
			day	=> 10,
			hour	=> 10,
			minut	=> 14,
			key	=> "345678",
		},
	"1-10-10-16" => {
			month	=> 1,
			day	=> 10,
			hour	=> 10,
			minut	=> 16,
			key	=> "234567",
		},
};
my $keyParamsTwo = {
	seconds	=> 10,
	minut	=> 10,
	hour	=> 10,
	day	=> 10,
	month	=> 1,
	year	=> 2018,
	WeekNum	=> 2,
	concat	=> "1-10-10-10"
};
my $sym1 = chr(49);	# 1 - корректный дополняющий символ
my $sym2 = "55";	# некорекктный дополняющий символ (заменяется на символ по-умолчанию)


##### Тестирование наложения ГАММЫ на сообщение, с учетом особенностей
my ( $msgMas, $msgMasTwo, $msg, $xoredMSG, $dblXoredMSG, $xoredMSGTwo, $dblXoredMSGTwo );
##### 1 - при длине сообщения больше длины ключа (гаммы)
$msg = "Mother wash a rama";
# получаем шифрограмму
$msgMas = EncDecLong($msg, $dictOne, $keyParamsOne, $sym2);
$xoredMSG = '';	$xoredMSG .= $_->{msg} foreach ( @{ $msgMas } );
# получаем исходное сообщение + добавленные в конце символы
$msgMas = EncDecLong($xoredMSG, $dictOne, $keyParamsOne, $sym2);
$dblXoredMSG = '';	$dblXoredMSG .= $_->{msg} foreach ( @{ $msgMas } );
# сравним исходную строку с шифрованными
isnt($msg, $xoredMSG, "Len message > len key, xored message != msg");
is($msg, $dblXoredMSG, "Len message > len key, double xored msg == msg");


##### 2 - при длине сообщения меньше длины ключа (гаммы)
$msg = "rama";
# получаем шифрограмму
$msgMas = EncDecLong($msg, $dictOne, $keyParamsOne, $sym1);
$xoredMSG = '';	$xoredMSG .= $_->{msg} foreach ( @{ $msgMas } );
# получаем исходное сообщение + добавленные в конце символы
$msgMas = EncDecLong($xoredMSG, $dictOne, $keyParamsOne);
$dblXoredMSG = '';	$dblXoredMSG .= $_->{msg} foreach ( @{ $msgMas } );
# сравним исходную строку с шифрованными
isnt($msg, substr($xoredMSG, 0, length($msg)), "Len message < len key, xored message != msg");
is($msg, substr($dblXoredMSG, 0, length($msg)), "Len message < len key, double xored msg == msg");


##### 3 - при длине сообщения больше длины ключа (гаммы), но при этом длина последней части сообщения меньше длины ключа (гаммы)
$msg = " Mother wash a rama!";
### Первый словарь
# получаем шифрограмму
$msgMas = EncDecLong($msg, $dictOne, $keyParamsOne);	# шифруем сообщение (разбивая на части если нужно)
$xoredMSG = '';	$xoredMSG .= $_->{msg} foreach ( @{ $msgMas } );	# собираем зашифрованный вариант в одно целое
# получаем исходное сообщение + добавленные в конце символы
$msgMas = EncDecLong($xoredMSG, $dictOne, $keyParamsOne);	# шифруем сообщение (разбивая на части если нужно)
$dblXoredMSG = '';	$dblXoredMSG .= $_->{msg} foreach ( @{ $msgMas } );	# собираем зашифрованный вариант в одно целое

### Второй словарь
# получаем шифрограмму
$msgMasTwo = EncDecLong($msg, $dictTwo, $keyParamsTwo);
$xoredMSGTwo = '';	$xoredMSGTwo .= $_->{msg} foreach ( @{ $msgMasTwo } );
# получаем исходное сообщение + добавленные в конце символы
$msgMasTwo = EncDecLong($xoredMSGTwo, $dictTwo, $keyParamsTwo);
$dblXoredMSGTwo = '';	$dblXoredMSGTwo .= $_->{msg} foreach ( @{ $msgMasTwo } );

#use DDP;
#p $msgMas;	p $msg;	p $xoredMSG;	p $dblXoredMSG;
#say substr($xoredMSG, 0, length($msg));
#say substr($dblXoredMSG, 0, length($msg));

# сравним исходную строку с substr(так как есть лишние добавочные символы) шифрованных
isnt($msg, substr($xoredMSG, 0, length($msg)), "Len part of msg < len key, dictOne, xored message != msg");
is($msg, substr($dblXoredMSG, 0, length($msg)), "Len part of msg < len key, dictOne, double xored msg == msg");
isnt($msg, substr($xoredMSGTwo, 0, length($msg)), "Len part of msg < len key, dictTwo, xored message != msg");
is($msg, substr($dblXoredMSGTwo, 0, length($msg)), "Len part of msg < len key, dictTwo, double xored msg == msg");
is($xoredMSG, $xoredMSGTwo, "Len part of msg < len key, xored message dict one == xored message dict two");


##### 4 - при длине сообщения равной длине ключа (гаммы)
$msg = "Mother";
# получаем шифрограмму
$msgMas = EncDecLong($msg, $dictOne, $keyParamsOne, $sym2);
$xoredMSG = '';	$xoredMSG .= $_->{msg} foreach ( @{ $msgMas } );
# получаем исходное сообщение + добавленные в конце символы
$msgMas = EncDecLong($xoredMSG, $dictOne, $keyParamsOne, $sym2);
$dblXoredMSG = '';	$dblXoredMSG .= $_->{msg} foreach ( @{ $msgMas } );
# сравним исходную строку с шифрованными
isnt($msg, $xoredMSG, "Len message = len key, xored message != msg");
is($msg, $dblXoredMSG, "Len message = len key, double xored msg == msg");
