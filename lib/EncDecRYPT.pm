package EncDecRYPT 1.00;

use 5.010;
use strict;
use warnings;

use TablesPRNG;

=head1 NAME

    EncDecRYPT - The great new Encryption and Decryption module!

=head1 VERSION

    Version 1.00

=head1 SYNOPSIS

    ToDo info about what module does

=head1 EXPORT

    ToDo info about export functions

=head1 SUBROUTINES/METHODS
=cut


=head1 Encryption_Decryption
=head2 EncDec
	Функция осуществляющяя наложение ГАММЫ на сообщение.
	Входные параметры:
		1 - сообщение;
		2 - ключ.
	Требование к входным параметрам:
		Сообщение и ключ должны быть одинаковой длины.
	Выходные параметры:
		1 - сообщение с наложением гаммы.
=cut
sub EncDec {
	my ($msg, $key) = @_;
	return undef if grep {not defined $_ } $msg, $key;
	return undef unless length($msg) == length($key);
	my $msg_xor = $msg ^ $key;	# побитовый XOR
	return $msg_xor;
}

=head2 EncDecLong
	Функция осуществляющяя наложение ГАММЫ на сообщение, с учетом особенностей:
		* при длине сообщения больше длины ключа (гаммы) - разделение сообщения на части и наложения на каждую часть сообщения своего ключа (гаммы);
		* при длине сообщения меньше длины ключа (гаммы) - дополнение сообщения до длины ключа (гаммы).
	Входные параметры:
		1 - сообщение;
		2 - ссылка на справочник ключей (гамм);
		3 - параметры для выбора ключа (гаммы), ими являются - датавремя(секунды, минуты, часы; день, месяц, год) и конкатенация(concat) параметров согласно используемому справочнику.
		4 - символ дополнения (по-умолчанию $defMsgExpander)
	Выходные параметры:
		1 - массив, каждый элемент которого, является хешом состоящим из:
			* сообщение - msg	- часть сообщения с наложением ключа (гаммы);
			* время	- time	- ссылка на хэш содержащий параметры выбора ключа (точное время для отправки сообщения).
	Дополнение:
		Считается что каждый символ сообщения и ключа является 8-битным.
		Если длина части сообщения меньше длины ключа (гаммы), сообщение дополняется незначащими символами для удовлетворения условию равенства длин сообщения и ключа (гаммы).
		Критической зоной (когда ключей меньше чем частей сообщений) в конце таблицы пренебрегаем в данной реализации.
	Структура справочника ключей (гамм) - два варианта хеша:
		Первый (не полностью реализованно):
			ключ - конкатенация (с разделением через '-') номера недели, часов и минут (пример: 1-10-06)
			значение - ссылка на хеш, содержащий:
				* номер недели	- weekNum	- значение (1 - 52);
				* часы		- hour	- значение (0 - 23);
				* минуты	- minut	- значение (0 - 59);
				* ключа		- key	- значение (короткая гамма - т.е. если длины не хватает, то вызывать продолжение генерации с ГПСЧ);
				* вектор состояния - StateVect - ссылка на массив (вектор состояний для догенерации ключевой полседовательности).
		Второй:
			ключ - конкатенация (с разделением через '-') месяца, дня, часов и минут (пример: 12-31-23-59)
			значение - ссылка на хеш, содержащий:
				* месяц		- month	- значение (1 - 12);
				* день		- day	- значение (в рамках конкретного месяца)
				* часы		- hour	- значение (0 - 23);
				* минуты	- minut	- значение (0 - 59);
				* ключ		- key	- значение (полностью сформированная гамма, т.е. если длины не хватает, то выбрать следущий интервал и соответствующий ключ).
=cut
=head2
	Считается:
		1. Что первый словарь(таблица) содержит короткие ключи и при нехватке длины ключа, он догенерируется до нужной длины, но не больше максимальной.
		2. Что второй словарь(таблица) содержит длинные ключи (которых должно хватить на полное шифрование сообщения)
		В обоих случаях считается, что если длины ключа не хватает, то нужно разбить сообщение на несколько.
	Последовательность действий:
		1.1. считать нужные параметры (сообщение, ссылку на словарь(таблицу ключей), временные параметры для выбора ключа)
		1.2. инициализировать массив для результата (массив хешей {msg => ..., time => ...})
		2. проверить параметры на валидность

		3.1. Получить первый ключ согласно временным параметрам
		3.2. Проверить что ключ был получен и он не является затертым, в случае если ключ затерт, завершить выполнение вернув undef
		4. Запомнить ожидаемую длину ключа (которая равна исходно длине взятого в пункте 3.1. ключа)
		5. Проверить, если ожидаемую длина ключа соответствует короткому ключу, то проверить на то что короткого ключа хватает для защифрования, иначе изменить ожидаемую длину на максимальную

		6. Разбить исходное сообщение на части соответствующие текущей ожидаемой длине ключа

		10.1. Дополнить последнюю часть сообщения до ожидаемой длины ключа (либо пункт 10.2) (дополнение проводится заранее оговоренными символами).

		7.1. Ввести массив для ключей, для хранения ключей для шифрования каждой части сообщения (сразу сохранив в нем первый полученный ключ)
		7.2. Ввести массив конкатенаций, для хранения конкатенаций для каждого взятого ключа,
		и дальнейшего использования для зачистки данных ключей в словаре(таблице) (сразу сохранив в нем первую конкатенацию)
		7.3. Сохранить в массив для результата временные параметры для первого ключа (для корректного определения в дальнейшем времени отправки сообщения)
		8. Получить ключ для каждой из частей сообщения:
		8.1. Прибавить определенной время к исходному (TimePartAdd)
		8.2. Согласно типу таблицы сформировать нужный формат конкатенации
		8.3.1. Получить ключ согласно сформированной конкатенации
		8.3.2. Проверить ключ на затертость (путем сравнения с последовательностью для затирания ключей), в случае если ключ затерт, завершить выполнение вернув undef
		8.3.3. Продолжить, сохранив полученный ключ в массив ключей
		8.3.4. Сохранить конкатенацию данного ключа в массив конкатенаций
		8.4. Сохранить в массив для результата временные параметры (для корректного определения в дальнейшем времени отправки сообщения)

		9. В случае несоответствия длины самого первого сообщения, длине первого ключа - догенерировать все ключи до ожидаемой длины (полученной после пунктов 4/5),
		для этого забрать вектор состояний(ГПСЧ) из таблицы, согласно конкатенации из массива конкатенаций (порядковые номера соответствуют номерам ключей)
		9.1. Проверить на необходимость догенерации последнего элемента ключа в массиве

		10.2 Обрезать последний ключ до длины последнего сообщения (либо пункт 10.1) (Предпочтительнее)

		11. Произвести шифрование элементов из массива частей сообщения на массиве ключей, результат поместить в массив для результата
		12. Зачистить ключи.
		13. Вернуть массив результата.
=cut
my $defClearingKey = '0' x $TablesPRNG::MAX_KEY_LEN;	# нулевая последовательность с длинной равной длине максимального ключа
my $defMsgExpander = chr(22);	# SYN - chr(22) - 16h
sub EncDecLong {
	# 1.1. считать нужные параметры (сообщение, ссылку на словарь(таблицу ключей), временные параметры для выбора ключа)
	my $msg = shift;
	my $keyDict = shift;
	my $keyParams = shift;
	return undef if grep {not defined $_ } $msg, $keyDict, $keyParams;
	$keyParams = { %$keyParams }; # копируем keyParams
	my $msgExpander = shift;
	$msgExpander = $defMsgExpander if (not defined $msgExpander or length($msgExpander) > 1);
	# 1.2. инициализировать массив для результата (массив хешей {msg => ..., time => ...})
	my @rezultMas = ();	# массив для результата
	# 2. проверить параметры на валидность
	# ToDo Проверить параметры

	# 3.1. Получить первый ключ согласно временным параметрам
	my $key = $keyDict->{ $keyParams->{concat} }{ key };
	# 3.2. Проверить что ключ был получен и он не является затертым, в случае если ключ затерт, завершить выполнение вернув undef
	return undef if ($key eq $defClearingKey);
	# 4. Запомнить ожидаемую длину ключа (которая равна исходно длине взятого в пункте 3.1. ключа)
	my $keyLen = length(unpack "B*", $key) / 8;	# length плохо работает с кодами от 00h до 20h
	# 5. Проверить, если ожидаемую длина ключа соответствует короткому ключу, то проверить на то что короткого ключа хватает для защифрования, иначе изменить ожидаемую длину на максимальную
	if ($keyLen == $TablesPRNG::SHORT_KEY_LEN) {
		# если длины ключа не достаточно, меняем длину ключа на максимальную
		if ($keyLen < length(unpack "B*", $msg) / 8) {
			$keyLen = $TablesPRNG::MAX_KEY_LEN;
		}
	}

	# 6. Разбить исходное сообщение на части соответствующие текущей ожидаемой длине ключа
	my @msg = split //, $msg;
	my @msgMas = ();
	for my $i (0..$#msg) {
		$msgMas[ int($i / $keyLen) ] .= $msg[$i];	# забираем в каждый элемент массива не более $keyLen символов
	}

	# 10.1. Дополнить последнюю часть сообщения до ожидаемой длины ключа (либо пункт 10.2) (дополнение проводится заранее оговоренными символами).
	#if (length(unpack "B*", $msgMas[$#msgMas]) / 8 < $keyLen) { $msgMas[$#msgMas] .= $msgExpander x ( ($keyLen - length(unpack "B*", $msgMas[$#msgMas]) / 8) ); }

	# 7.1. Ввести массив для ключей, для хранения ключей для шифрования каждой части сообщения (сразу сохранив в нем первый полученный ключ)
	my @keyMas = ($key);
	# 7.2. Ввести массив конкатенаций, для хранения конкатенаций для каждого взятого ключа,
	# и дальнейшего использования для зачистки данных ключей в словаре(таблице) (сразу сохранив в нем первую конкатенацию)
	my @concatMas = ( $keyParams->{concat} );
	# 7.3. Сохранить в массив для результата временные параметры для первого ключа (для корректного определения в дальнейшем времени отправки сообщения)
	$rezultMas[0]{time} = { %$keyParams };
	# 8. Получить ключ для каждой из частей сообщения:
	for my $i (1..$#msgMas) {
		# 8.1. Прибавить определенной время к исходному (TimePartAdd)
		$keyParams = TimePartAdd( $keyParams );	# $keyParams->{concat} после данной функции не валиден.
		# 8.2. Согласно типу таблицы сформировать нужный формат конкатенации
		if ( exists $keyDict->{ $keyParams->{concat} }{ WeekNum } ) {	# первый (конкатенация (с разделением через '-') номера недели, часов и минут (пример: 1-10-06))
			$keyParams->{concat} = $keyParams->{WeekNum} . "-" . $keyParams->{hour} . "-" . $keyParams->{minut};
		}
		else {	# второй (конкатенация (с разделением через '-') месяца, дня, часов и минут (пример: 12-31-23-59))
			$keyParams->{concat} = $keyParams->{month} . "-" . $keyParams->{day} . "-" . $keyParams->{hour} . "-" . $keyParams->{minut};
		}
		# 8.3.1. Получить ключ согласно сформированной конкатенации
		$key = $keyDict->{ $keyParams->{concat} }{ key };
		# 8.3.2. Проверить ключ на затертость (путем сравнения с последовательностью для затирания ключей), в случае если ключ затерт, завершить выполнение вернув undef
		return undef if ($key eq $defClearingKey);
		# 8.3.3. Продолжить, сохранив полученный ключ в массив ключей
		push @keyMas, $key;
		# 8.3.4. Сохранить конкатенацию данного ключа в массив конкатенаций
		push @concatMas, $keyParams->{concat};
		# 8.4. Сохранить в массив для результата временные параметры (для корректного определения в дальнейшем времени отправки сообщения)
		$rezultMas[$i]{time} = { %$keyParams };
	}

	# 9. В случае несоответствия длины самого первого сообщения, длине первого ключа - догенерировать все ключи до ожидаемой длины (полученной после пунктов 4/5),
	# для этого забрать вектор состояний(ГПСЧ) из таблицы, согласно конкатенации из массива конкатенаций (порядковые номера соответствуют номерам ключей)
	my $firstMSGLen = length(unpack "B*", $msgMas[0]) / 8;
	my $firstKEYLen = length(unpack "B*", $keyMas[0]) / 8;
	if ( $firstMSGLen > $firstKEYLen ) {
		for my $i (0..$#keyMas) {
			# ToDo дополнительно проверить на необходимость догенерации последнего элемента ключа в массиве
			my $stateVect = $keyDict->{ $concatMas[$i] }{ stateVect };
			$keyMas[$i] = GenerateKey( {}, $keyLen, undef, $stateVect);
		}
	}

	# 10.2. Обрезать последний ключ до длины последнего сообщения (либо пункт 10.1) (Предпочтительнее)
	my $lastMSGLen = length(unpack "B*", $msgMas[$#msgMas]) / 8;
	my $lastKEYLen = length(unpack "B*", $keyMas[$#keyMas]) / 8;
	if ($lastMSGLen < $lastKEYLen) { $keyMas[$#keyMas] = substr($keyMas[$#keyMas], 0, $lastMSGLen); }

	# 11. Произвести шифрование элементов из массива частей сообщения на массиве ключей, результат поместить в массив для результата
	for my $i (0..$#msgMas) {
		$rezultMas[$i]{msg} = EncDec($msgMas[$i], $keyMas[$i]);
	}

	# 12. Зачистить ключи.
	foreach (@concatMas) {
		$keyDict->{ $_ }{ key } = $defClearingKey;
	}

	# 13. Вернуть массив результата.
	return \@rezultMas;
}


=head1 Import\Unimport
=cut
my @ImportedByDefault = qw/EncDec EncDecLong/;
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

