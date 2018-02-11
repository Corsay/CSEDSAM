package TablesPRNG 1.00;

use 5.010;
use strict;
use warnings;

use Math::Random::MT::Auto;

use JSON::XS;
use Time::Local;

=head1 NAME

    TablesPRNG - Tables generation module which uses PRNG (PseudoRandom Number Generator).

=head1 VERSION

    Version 1.00

=head1 SYNOPSIS

    ToDo info about what module does

=head1 EXPORT

    ToDo info about export functions

=head1 SUBROUTINES/METHODS
=cut


=head2
	Модуль содержит:
		* Функции генерации таблиц
		* Функции сохранения таблиц в файл
		* Функцию загрузки таблицы (из файла) в переменную и возврат ссылки на неё

	Структура справочника ключей (гамм) - два варианта хеша:
		Первый (не полностью реализованно) (ShortTableGenerator):
			ключ - конкатенация (с разделением через '-') номера недели, часов и минут (пример: 1-10-06)
			значение - ссылка на хеш, содержащий:
				* номер недели	- weekNum	- значение (1 - 52);
				* часы		- hour	- значение (0 - 23);
				* минуты	- minut	- значение (0 - 59);
				* ключа		- key	- значение (короткая гамма - т.е. если длины не хватает, то вызывать продолжение генерации с ГПСЧ);
				* вектор состояния - StateVect - ссылка на массив (вектор состояний для догенерации ключевой полседовательности).
		Второй (LongTableGenerator):
			ключ - конкатенация (с разделением через '-') месяца, дня, часов и минут (пример: 12-31-23-59)
			значение - ссылка на хеш, содержащий:
				* месяц		- month	- значение (1 - 12);
				* день		- day	- значение (в рамках конкретного месяца)
				* часы		- hour	- значение (0 - 23);
				* минуты	- minut	- значение (0 - 59);
				* ключ		- key	- значение (полностью сформированная гамма, т.е. если длины не хватает, то выбрать следущий интервал и соответствующий ключ).
=cut


# Используемые переменные
our $SHORT_KEY_LEN = 32; # длина короткого ключа в байтах (2^5).
our $LONG_KEY_LEN = 128; # длина длинного ключа в байтах (2^7).
our $MAX_KEY_LEN = 256; # максимальная длина ключа в байтах (для догенерации) (2^8).
my $KEY_COLLISION_REPEAT = 3; # максимальное количество повторов перегенерации ключа


=head1 Generate Tables
=head2 ShortTableGenerator
	Функция, которая осуществляет генерацию таблицы первого типа (номера недели, часов и минут) (короткие ключи)
	Входные параметры:
		1 - начало периода;
		2 - конец периода.
	Выходные параметры:
		1 - ссылка на хеш содержащий сгенерированную таблицу.
=cut
sub ShortTableGenerator {
	my $startParams = shift;
	my $endParams = shift;
	return TableGenerator(
		$startParams,
		$endParams,
		1,
		$SHORT_KEY_LEN,
		518400,	# при коллизии добавить 6 дней (до начала следующей недели)
		[ qw /WeekNum hour minut/ ],
		[ qw /WeekNum hour minut key day stateVect/ ]
	);
}

=head2 LongTableGenerator
	Функция, которая осуществляет генерацию таблицы первого типа (месяца, дня, часов и минут) (длинные ключи)
	Входные параметры:
		1 - начало периода;
		2 - конец периода.
	Выходные параметры:
		1 - ссылка на хеш содержащий сгенерированную таблицу.
=cut
sub LongTableGenerator {
	my $startParams = shift;
	my $endParams = shift;
	return TableGenerator(
		$startParams,
		$endParams,
		0,
		$LONG_KEY_LEN,
		undef,	# при коллизии добавить значение по умолчанию
		[ qw /month day hour minut/ ],
		[ qw /month day hour minut key/ ]
	);
}

=head2 TableGenerator
	Функция, которая осуществляет генерацию таблицы выбранного типа
	Входные параметры:
		1 - начало периода (ссылка на хеш - секунды, минуты, часы; день, месяц, год, номер недели) (копируется);
		2 - конец периода (ссылка на хеш);
		3 - тип таблицы для генерации; (0 - длинные ключи, 1 - короткие ключи)
		4 - число секунд в unix_time, которое прибавлять в случае коллизии (при добавлении в хеш, когда там уже существует ключ с подобной конкатенацией параметров)
		5 - ссылка на массив параметров для конкатенации; (в порядке следования нужном в конкатенации)
		6 - ссылка на массив параметров для итогового хеша.
	Выходные параметры:
		1 - ссылка на хеш содержащий сгенерированную таблицу.
=cut
sub TableGenerator {
	my $startParams = shift;
	my $endParams = shift;
	my $tableType = shift;
	my $keyLen = shift;
	my $TimePartExpander = shift;
	my $concatFields = shift;
	my $hashFields = shift;
	my %hashTable = ();	# результирующая таблица
	my %hashKeys = ();	# хеш ключей: ключ => 1
	$startParams = { %$startParams };	# копируем исходные параметры (гарантия целостности исходных данных) (далее работаем с копией)

	# ToDo проверить наличие параметров

	my $prng = Math::Random::MT::Auto->new();	# ГПСЧ

	# получаем для них unix_time
	$startParams->{ unix_timestamp } = timegm($startParams->{seconds}, $startParams->{minut}, $startParams->{hour}, $startParams->{day}, $startParams->{month} - 1, $startParams->{year});
	$endParams->{ unix_timestamp } = timegm($endParams->{seconds}, $endParams->{minut}, $endParams->{hour}, $endParams->{day}, $endParams->{month} - 1, $endParams->{year});

	while ($startParams->{ unix_timestamp } <= $endParams->{ unix_timestamp }) {
		# формируем нужный формат конкатенации
		$startParams->{concat} = '';
		$startParams->{concat} .= $startParams->{ $_ } . "-" foreach @{ $concatFields };
		chop( $startParams->{concat} );

		# При коротом типе добавляем в список элементов stateVect
		if ($tableType == 1) {
			my @stateVect = $prng->get_state();	# вектор состояния
			$startParams->{ stateVect } = \@stateVect;
		}

		# генерация ключа
		my $key = GenerateKey( \%hashKeys, $keyLen, $prng);
		die "Long Key Table Generation: too many collisions.\n" unless defined $key;
		$startParams->{ key } = $key;

		# если ключ уже существует
		if ( exists $hashTable{ $startParams->{concat} } ) {
			# то для таблицы первого типа прибавляем $TimePartExpander (или можно при необходимости применить методы обхода коллизий)
			$startParams = TimePartAdd( $startParams, $TimePartExpander );	# $startParams->{concat} после данной функции не валиден.
			next;
		}
		else {
			# Добавляем запись о нужных параметрах в хеш
			$hashTable{ $startParams->{concat} } { $_ } = $startParams->{ $_ } foreach @{ $hashFields };
		}

		# Делаем приращение к начальному параметру времени
		$startParams = TimePartAdd( $startParams );	# $startParams->{concat} после данной функции не валиден.
	}

	# возвращаем полученный хеш
	return \%hashTable;
}

=head2 GenerateKey
	Функция, которая генерирует ключ нужной длины (в байтах)
	Входные параметры:
		1 - ссылка на хеш ключей; (для исключения дублирования)
		2 - Ожидаемая длина ключа;
		3 - ГПСЧ; (экземпляр класса) (опционально) (чтобы не инициализировать его постоянно при частом вызове функции генерации ключа)
		4 - Параметры генерации ключа. (ссылка на вектор состояний) (опционально)
	Выходные параметры:
		1 - сгенерированный ключ
=cut
sub GenerateKey {
	my $hashKeys = shift;
	my $keyLen = shift;
	my $prng = shift;
	my $stateVect = shift;

	# ToDo проверка корректности параметров

	# если не указан ГПСЧ, то инициализировать его тут
	$prng = Math::Random::MT::Auto->new() unless defined $prng;
	# если указан вектор состояния, то использовать его при генерации
	$prng->set_state($stateVect) if defined $stateVect;

	# цикл генерации ключа
	my $key = '';
	my $key_iter_num = 0;
	while ($key_iter_num < $KEY_COLLISION_REPEAT) {
		# формируем ключ заданной длины
		$key = "$prng";
		while (length($key) < $keyLen) {
			$key .= "$prng";
		}
		# обрезаем до нужной длины
		$key = substr($key, 0, $keyLen) if (length($key) > $keyLen);

		# проверяем что такого ключа еще не было, добавляем его в хеш ключей и выходим из цикла
		# если был, увеличиваем и повторяем операцию KEY_COLLISION_REPEAT раз
		if ( exists $hashKeys->{ $key } ) {
			$key_iter_num++;
		}
		else {
			$hashKeys->{ $key } = 1;
			last;
		}
	}
	# проверяем что ключ сгенерировался
	return undef if ($key_iter_num >= $KEY_COLLISION_REPEAT);

	# возвращаем полученный ключ
	return $key;
}


=head1 Save/Load Tables
=head2 SaveTableToFile
	Функция, которая осуществляет выгрузку таблицы в файл (выгрузка осуществляется в формате JSON)
	Входные параметры:
		1 - ссылка на хеш содержащий сгенерированную таблицу;
		2 - название файла для сохранения таблицы.
	Выходные параметры:
		Отстутствуют
	Дополнение:
		При ошибке выбрасывает die.
=cut
sub SaveTableToFile {
	my $hash = shift;
	my $filename = shift;

	# Если файл существует и нет права на запись в него, то ошибка - записи в выбранный файл
	die "Error then write in file '$filename': File exists, but (-w) permission denied\n" if (-e $filename and !-w $filename);

	# 1. Открываем указанный файл на запись
	my $fh;
	open ($fh, '>', $filename) or die "Error then open/create file '$filename': $!\n";
	# 2. Переводим таблицу в JSON
	my $json = JSON::XS::encode_json($hash);
	# 3. Сохраняем полученный JSON в файл
	print {$fh} $json;
	# Закрываем файл
	close $fh;
	return;
}

=head2 LoadTableFromFile
	Функция, которая осуществляет загрузку таблицы из файла (загружает JSON содержащийся в выбранном файле)
	Входные параметры:\
		1 - название файла для загрузки таблицы.
	Выходные параметры:
		1 - ссылка на хеш содержащий загруженную таблицу.
	Дополнение:
		При ошибке выбрасывает die.
=cut
sub LoadTableFromFile {
	my $filename = shift;

	# Если файл существует и нет права на чтение из него, то ошибка - чтения из выбранного файла
	die "Error then read from file '$filename': File exists, but (-r) permission denied\n" if (-e $filename and !-r $filename);

	# 1. Открываем указанный файл на чтение
	my $fh;
	open ($fh, '<', $filename) or die "Error then open file '$filename': $!\n";
	# 2. Загружаем JSON из файла
	my $json = <$fh>;
	# 3. Переводим таблицу из JSON
	my $hash = JSON::XS::decode_json($json);
	# Закрываем файл
	close $fh;
	return $hash;
}


=head1 Time
=head2 TimePartAdd
	Функция прибавляющая $defTimePartExpander (прирост времени) к временному интервалу.
	Входные параметры:
		1 - хеш со временем для текущего ключа;
		2 - время которое добавлять вместо стандартного (в unix_time).
	Выходные параметры:
		1 - хеш с модифицированным временем для следующего ключа
	Замечание:
		$keyParams->{concat} после данной функции не валиден.
=cut
my $defTimePartExpander = 120;	# время в unix_time
sub TimePartAdd {
	my $keyParams = shift;
	my $TimePartExpander = shift;
	$TimePartExpander = $defTimePartExpander unless defined $TimePartExpander;
	$keyParams = { %$keyParams }; # копируем keyParams
	# получаем unix_timestamp
	my $unix_timestamp = timegm($keyParams->{seconds}, $keyParams->{minut}, $keyParams->{hour}, $keyParams->{day}, $keyParams->{month} - 1, $keyParams->{year});
	$unix_timestamp += $TimePartExpander;	# модифицируем
	# формируем новые временные параметры
	$keyParams = TimeHashFromUnixTime($unix_timestamp, $keyParams);
	return $keyParams;
}

=head2 TimeHashFromUnixTime
	Функция записывающая время согласно переданому unix_timestamp в хеш
	Входные параметры:
		1 - unix_timestamp;
		2 - хеш для добавления результата.
	Выходные параметры:
		1 - хеш с временем согласно введенному unix_timestamp
	Формат выходного хеша:
		seconds => секунд
		minut   => минута
		hour    => час
		day     => день меясца
		month   => номер месяца (1..12)
		year    => год
		wday    => номер дня недели (0 - воскресение .. 6 - суббота)
		WeekNum => номер недели
		unix_timestamp => время в формате unix_time
=cut
sub TimeHashFromUnixTime {
	my $unix_timestamp = shift;
	my $keyParams = shift;
	my @time = gmtime($unix_timestamp);
	$keyParams->{seconds} = $time[0];
	$keyParams->{minut} = $time[1];
	$keyParams->{hour} = $time[2];
	$keyParams->{day} = $time[3];
	$keyParams->{month} = $time[4] + 1;
	$keyParams->{year} = $time[5] + 1900;
	$keyParams->{wday} = $time[6];	# день недели (0 - воскресение .. 6 - суббота)
	$keyParams->{WeekNum} = int($time[7] / 7) + 1;
	$keyParams->{unix_timestamp} = $unix_timestamp;
	return $keyParams;
}


=head1 Import\Unimport
=cut
my @ImportedByDefault = qw/ShortTableGenerator LongTableGenerator GenerateKey SaveTableToFile LoadTableFromFile TimePartAdd TimeHashFromUnixTime/;
sub def_import {
	my $pkg = shift;
	{
		no strict 'refs';
		*{"${pkg}::$_"} = \&{$_} foreach @ImportedByDefault;
	}
}
sub def_unimport {
	my $pkg = shift;
	{
		no strict 'refs';
		delete ${"${pkg}::"}{$_} foreach @ImportedByDefault;
	}
}
sub import {
	my $self = shift;
	my $pkg = caller;

	def_import($pkg);	# то что import по умолчанию

	foreach my $func (@_) {
		no strict 'refs';
		*{"${pkg}::$func"} = \&{$func};
	}
}
sub unimport {
	my $self = shift;
	my $pkg = caller;

	def_unimport($pkg);	# то что unimport по умолчанию

	{
		no strict 'refs';
		delete ${"${pkg}::"}{$_} foreach @_;
	}
}


=head1 LICENSE AND COPYRIGHT

Copyright 2018 Dmitriy Tcibisov.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1;

