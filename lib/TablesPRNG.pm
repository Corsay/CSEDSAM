package TablesPRNG 1.00;

use 5.010;
use strict;
use warnings;

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
				* ключа		- key	- значение (короткая гамма - т.е. если длины не хватает, то вызывать продолжение генерации с ГПСЧ).
		Второй (LongTableGenerator):
			ключ - конкатенация (с разделением через '-') месяца, дня, часов и минут (пример: 12-31-23-59)
			значение - ссылка на хеш, содержащий:
				* месяц		- month	- значение (1 - 12);
				* день		- day	- значение (в рамках конкретного месяца)
				* часы		- hour	- значение (0 - 23);
				* минуты	- minut	- значение (0 - 59);
				* ключ		- key	- значение (полностью сформированная гамма, т.е. если длины не хватает, то выбрать следущий интервал и соответствующий ключ).
=cut


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

}

=head2 LongTableGenerator
	Функция, которая осуществляет генерацию таблицы второго типа (месяца, дня, часов и минут) (длинные ключи)
	Входные параметры:
		1 - начало периода;
		2 - конец периода.
	Выходные параметры:
		1 - ссылка на хеш содержащий сгенерированную таблицу.
=cut
sub LongTableGenerator {

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
		хеш со временем для текущего ключа
	Выходные параметры:
		хеш с модифицированным временем для следующего ключа
	Замечание:
		$keyParams->{concat} после данной функции не валиден.
=cut
my $defTimePartExpander = 120;	# время в unix_time
sub TimePartAdd {
	my $keyParams = shift;
	# получаем unix_timestamp
	my $unix_timestamp = timegm($keyParams->{seconds}, $keyParams->{minut}, $keyParams->{hour}, $keyParams->{day}, $keyParams->{month} - 1, $keyParams->{year});
	$unix_timestamp += $defTimePartExpander;	# модифицируем
	# формируем новые временные параметры
	my @time = gmtime($unix_timestamp);
	$keyParams->{seconds} = $time[0];
	$keyParams->{minut} = $time[1];
	$keyParams->{hour} = $time[2];
	$keyParams->{day} = $time[3];
	$keyParams->{month} = $time[4] + 1;
	$keyParams->{year} = $time[5] + 1900;
	$keyParams->{WeekNum} = int($time[7] / 7) + 1;
	return $keyParams;
}

=head1 Import\Unimport
=cut
my @ImportedByDefault = qw/TimePartAdd ShortTableGenerator LongTableGenerator SaveTableToFile LoadTableFromFile/;
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

