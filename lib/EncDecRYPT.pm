package EncDecRYPT 1.00;

use 5.010;
use strict;
use warnings;

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
	return undef unless ($msg || $key || length($msg) == length($key));
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
		3 - параметры для выбора ключа (гаммы), ими являются - номер недели(в году), текущее время(часы и минуты).
		4 - символ дополнения (по-умолчанию $defMsgExpander)
	Выходные параметры:
		1 - массив, каждый элемент которого, является кортежем состоящим из:
			* части сообщения с наложением ключа (гаммы);
			* конкатенация для однозначного нахождения нужного ключа (гаммы) в справочнике.
	Дополнение:
		Считается что каждый символ сообщения и ключа является 8-битным.
		Если длина части сообщения меньше длины ключа (гаммы), сообщение дополняется незначащими символами для удовлетворения условию равенства длин сообщения и ключа (гаммы).
	Структура справочника ключей (гамм) - два варианта хеша:
		Первый:
			ключ - конкатенация (с разделением через '-') номера недели, часов и минут (пример: 1-10-06)
			значение - ссылка на хеш, содержащий:
				* номер недели	- weekNum	- значение (1 - 52);
				* часы			- hour		- значение (0 - 23);
				* минуты		- minut		- значение (0 - 59);
				* ключа			- key		- значение (короткая гамма - т.е. если длины не хватает, то вызывать продолжение генерации с ГПСЧ).
			по ключу "ГПСЧ" - ссылка на функцию ГПСЧ, для догенерации ключевой информации
		Второй:
			ключ - конкатенация (с разделением через '-') месяца, дня, часов и минут (пример: 12-31-23-59)
			значение - ссылка на хеш, содержащий:
				* месяц		- month	- значение (1 - 12);
				* день		- day	- значение (в рамках конкретного месяца)
				* часы		- hour	- значение (0 - 23);
				* минуты	- minut	- значение (0 - 59);
				* ключ		- key	- значение (полностью сформированная гамма, т.е. если длины не хватает, то выбрать следущий интервал и соответствующий ключ).
	Структура параметров выбора ключа соответствует структуре соответствующего справочника(с точностью до именования ключей + concat (конкатенация));
=cut
my $defMsgExpander = chr(22);	# SYN - chr(22) - 16h
sub EncDecLong {
	my $msg = shift;
	my $keyDict = shift;
	my $keyParams = shift;
	my $msgExpander = shift;
	$msgExpander = $defMsgExpander until ($msgExpander || length($msgExpander) > 1);

	# ToDo Проверить параметры

	# 1. Выбрать ключ (запомнить ключ и его длину).
	my $key = $keyDict->{ $keyParams->{concat} }{ key };

	# ToDo если справочник первого типа (с короткими ключами), то заморочиться с их генерацией (и тут)
	# ToDo Проверить что ключ обнаружен
	my $keyLen = length($key);

	# 2. Если длина сообщения больше длины ключа, то разбить его на части.
	# 3. Поместить сообщение(части сообщения) в массив.
	my @msgMas = grep {$_ ne ""} split /(.{$keyLen})/, $msg;

	# 4. Если последний элемент помещенный в массив (сообщение или его часть) имеет длину меньше длины ключа, то дополнить сообщение до длины ключа (заранее оговоренными символами).
	if (length($#msgMas) < $keyLen) { $msgMas[$#msgMas] .= $msgExpander x ($keyLen - length($#msgMas)); }

	# 5. Выбрать из таблицы соответствующее количеству частей сообщения количество ключей, начиная с ключа выбранного в пункте 1.
	my @keyMas = ($key);

	# 6. Произвести шифрование элементов из массива частей сообщения на массиве ключей
	for my $i (0..$#msgMas) {
		$msgMas[$i] = EncDec($msgMas[$i], $keyMas[$i]);
	}

	# 7. Сформировать список сообщений для возврата

	return;
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

