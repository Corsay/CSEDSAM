#!/usr/bin/perl
use 5.010;
use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

plan tests => 39;

use EncDecRYPT;
use TablesPRNG;

# Подготовка тестовых словарей, начиная с даты 10-01-2018 10:10:10 (2 неделя), на час
my $startParams = { seconds => 10, minut => 10, hour => 10, day => 10, month => 1, year => 2018, WeekNum => 2, };
my $endParams = { seconds => 10, minut => 8, hour => 11, day => 10, month => 1, year => 2018, };
=head2
	Первый словарь ключей (не полностью реализованно):
		ключ - конкатенация (с разделением через '-') номера недели, часов и минут (пример: 1-10-06)
		значение - ссылка на хеш, содержащий:
			* номер недели	- weekNum	- значение (1 - 52);
			* часы		- hour	- значение (0 - 23);
			* минуты	- minut	- значение (0 - 59);
			* ключа		- key	- значение (короткая гамма - т.е. если длины не хватает, то вызывать продолжение генерации с ГПСЧ);
			* вектор состояния - StateVect - ссылка на массив (вектор состояний для догенерации ключевой полседовательности).
=cut
# генерируем короткий первый словарь
my $dictOne = ShortTableGenerator( $startParams, $endParams );
my $keyParamsOne = { seconds => 10, minut => 10, hour => 10, day => 10, month => 1, year => 2018, WeekNum => 2, concat => "2-10-10" };
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
# генерируем короткий второй словарь
my $dictTwo = LongTableGenerator( $startParams, $endParams );
my $keyParamsTwo = { seconds => 10, minut => 10, hour => 10, day => 10, month => 1, year => 2018, WeekNum => 2, concat => "1-10-10-10" };
my $sym1 = chr(49);	# 1 - корректный дополняющий символ
my $sym2 = "55";	# некорекктный дополняющий символ (заменяется на символ по-умолчанию)


=head
	Функция тестирования
	Входные параметры:
		1 - сообщение;
		2 - ссылка на словарь (таблицу);
		3 - ссылка на ключейвые параметры;
		4 - префикс к записываемой в тест информации;
		5 - оператор сравнения (< == > undef)
		6 - длина ключа для сравнения (если указан оператор сравнения)
	Выходные параметры:
		Отсутствуют
=cut
sub EncDecLongTests {
	my ($msg, $dict, $keyParams, $prefix, $comprOper, $comprKeyLen) = @_;
	my ($dictCopy, $msgMas, $xoredMSG, $dblXoredMSG);

	# получаем шифрограмму
	while (my ($k, $v) = each %{$dict}) { $dictCopy->{ $k } = { %$v }; }
	$msgMas = EncDecLong($msg, $dictCopy, $keyParams);
	$xoredMSG = '';	$xoredMSG .= $_->{msg} foreach ( @{ $msgMas } );
	# получаем исходное сообщение
	while (my ($k, $v) = each %{$dict}) { $dictCopy->{ $k } = { %$v }; }
	$msgMas = EncDecLong($xoredMSG, $dictCopy, $keyParams);
	$dblXoredMSG = '';	$dblXoredMSG .= $_->{msg} foreach ( @{ $msgMas } );

	# сравним ожидания по длине cообщения и длине ключа
	if (defined $comprOper) {
		my ($comprMSG, $comprXoredMSG);
		if ($comprOper eq '<') {
			$comprMSG = (length($msg) < $comprKeyLen);
			$comprXoredMSG = (length($xoredMSG) < $comprKeyLen);
		} elsif ($comprOper eq '==') {
			$comprMSG = (length($msg) == $comprKeyLen);
			$comprXoredMSG = (length($xoredMSG) == $comprKeyLen);
		} else {
			$comprMSG = (length($msg) > $comprKeyLen);
			$comprXoredMSG = (length($xoredMSG) > $comprKeyLen);
		}
		ok($comprMSG, 'Keylen ' . $comprKeyLen . ': Len message ' . $comprOper . ' len key');
		ok($comprXoredMSG, 'Keylen ' . $comprKeyLen . ': Len xored message ' . $comprOper . ' len key');
	}
	# сравним исходную строку с шифрованной
	isnt($msg, $xoredMSG, $prefix . ': xored message != msg');
	is($msg, $dblXoredMSG, $prefix . ': double xored msg == msg');
}


##### Тестирование наложения ГАММЫ на сообщение, с учетом особенностей
=head2
	1. Длина сообщения меньше длины ключа
		1.1. Таблица первого типа, короткий ключ - 32 символа - длина результата короче 32 символов
		1.2. Таблица первого типа, догенерированный до максимума короткий ключ - 256 символов - длина результата короче 256 символов
		1.3. Таблица второго типа, длинный ключ - 128 символов - длина результата короче 128 символов
	2. Длина сообщения равна длине ключа
		2.1. Таблица первого типа, короткий ключ - 32 символа - длина результата 32 символов
		2.2. Таблица первого типа, догенерированный до максимума короткий ключ - 256 символов - длина результата 256 символов
		2.3. Таблица второго типа, длинный ключ - 128 символов - длина результата 128 символов
	3. Длина сообщения больше длины ключа, и при этом последний элемент короче ключа
		3.1. Таблица первого типа, короткий ключ - 32 символа - длина результата = ( (количества элементов массива - 1) * 256 + число меньшее 32)
		3.2. Таблица первого типа, догенерированный до максимума короткий ключ - 256 символов - длина результата = ( (кол. элем. мас. - 1) * 256 + число меньшее 256 и >= 32)
		3.3. Таблица второго типа, длинный ключ - 128 символов - длина результата = ( (кол. элем. мас. - 1) * 128 + число меньшее 128)
	4. Повторное использование ключа - результат возвращаемый функцией шифрования - undef
=cut
my ( $msgMas, $msgMasTwo, $msg, $xoredMSG, $dblXoredMSG, $xoredMSGTwo, $dblXoredMSGTwo, $dictOneCopy, $dictTwoCopy );
##### 1 - Длина сообщения меньше длины ключа
note("\n" . 'Len MSG < len KEY');
note('');
### 1.1. Таблица первого типа, короткий ключ - 32 символа - длина результата короче 32 символов
$msg = "My mom is the best in the city!";	# 31
EncDecLongTests( $msg, $dictOne, $keyParamsOne, 'Len message < len short key', '<', $TablesPRNG::SHORT_KEY_LEN );
### 1.2. Таблица первого типа, догенерированный до максимума короткий ключ - 256 символов - длина результата короче 256 символов
$msg = " She is the owner of a black belt for some martial arts." .
	" For she, every day is a day for something new, it can be a new technique, or maybe a new dish on our family table." .
	" There was not a day that we did not like her new dish, the black belt does wonders.";	# 255
EncDecLongTests( $msg, $dictOne, $keyParamsOne, 'Len message < len max key', '<', $TablesPRNG::MAX_KEY_LEN );
### 1.3. Таблица второго типа, длинный ключ - 128 символов - длина результата короче 128 символов
$msg = "But if without jokes, in the case of cooking, her freshly prepared new dishes are terrific!" .
	" And what's all I wanted to tell you"; # 127
EncDecLongTests( $msg, $dictTwo, $keyParamsTwo, 'Len message < len long key', '<', $TablesPRNG::LONG_KEY_LEN );


##### 2. Длина сообщения равна длине ключа
note("\n" . 'Len MSG == len KEY');
note('');
### 2.1. Таблица первого типа, короткий ключ - 32 символа - длина результата 32 символов
$msg = "My mom is the best in this city!"; # 32
EncDecLongTests( $msg, $dictOne, $keyParamsOne, 'Len message == len short key', '==', $TablesPRNG::SHORT_KEY_LEN );
### 2.2. Таблица первого типа, догенерированный до максимума короткий ключ - 256 символов - длина результата 256 символов
$msg = " She is the owner of a black belt for some martial arts." .
	" For she, every day is a day for something new, it can be a new technique, or maybe a new dish on our family table." .
	" There was not a day that we did not like her new dish, the black belt does wonders. ";	# 256
EncDecLongTests( $msg, $dictOne, $keyParamsOne, 'Len message == len max key', '==', $TablesPRNG::MAX_KEY_LEN );
### 2.3. Таблица второго типа, длинный ключ - 128 символов - длина результата 128 символов
$msg = "But if without jokes, in the case of cooking, her freshly prepared new dishes are terrific!" .
	" And what's all I wanted to tell you."; # 128
EncDecLongTests( $msg, $dictTwo, $keyParamsTwo, 'Len message == len long key', '==', $TablesPRNG::LONG_KEY_LEN );


##### 3. Длина сообщения больше длины ключа, и при этом последний элемент короче ключа
note("\n" . 'Len MSG > len KEY. Len last part of MSG < len key');
note('');
### 3.1. Таблица первого типа, короткий ключ - 32 символа - длина результата = ( (количества элементов массива - 1) * 256 + число меньшее 32)
$msg = "My mom is the best in the city!" .
	" She is the owner of a black belt for some martial arts." .
	" For she, every day is a day for something new, it can be a new technique, or maybe a new dish on our family table." .
	" There was not a day that we did not like her new dish, the black belt does wonders."; # 286 (256 + 30)
EncDecLongTests( $msg, $dictOne, $keyParamsOne, 'Len last part of msg < len key', '>', $TablesPRNG::SHORT_KEY_LEN );
### 3.2. Таблица первого типа, догенерированный до максимума короткий ключ - 256 символов - длина результата = ( (кол. элем. мас. - 1) * 256 + число меньшее 256 и >= 32)
$msg = "My mom is the best in the city!" .
	" She is the owner of a black belt for some martial arts." .
	" For she, every day is a day for something new, it can be a new technique, or maybe a new dish on our family table." .
	" There was not a day that we did not like her new dish, the black belt does wonders." .
	" But if without jokes, in the case of cooking, her freshly prepared new dishes are terrific!" .
	" And what's all I wanted to tell you."; # 415 (256 + 159)
EncDecLongTests( $msg, $dictOne, $keyParamsOne, 'Len last part of msg < len key', '>', $TablesPRNG::MAX_KEY_LEN );
### 3.3. Таблица второго типа, длинный ключ - 128 символов - длина результата = ( (кол. элем. мас. - 1) * 128 + число меньшее 128)
$msg = " But if without jokes, in the case of cooking, her freshly prepared new dishes are terrific!" .
	" And what's all I wanted to tell you."; # 129 (128 + 1)
EncDecLongTests( $msg, $dictTwo, $keyParamsTwo, 'Len last part of msg < len key', '>', $TablesPRNG::LONG_KEY_LEN );


##### 4. Повторное использование ключа - результат возвращаемый функцией шифрования - undef
isnt(EncDecLong($msg, $dictOne, $keyParamsOne, $sym2, 0), undef, 'Try to use key first time - with no clear key option - not undef returned.');
isnt(EncDecLong($msg, $dictOne, $keyParamsOne, $sym2, 1), undef, 'Try to use key second time - with clear key option - not undef returned.');
is(EncDecLong($msg, $dictOne, $keyParamsOne, $sym2), undef, 'Try to use key third time - undef returned.');
