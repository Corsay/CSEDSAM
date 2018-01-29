package MailClientRYPT 1.00;

use 5.010;
use strict;
use warnings;

use Mail::IMAPClient;

use DDP;

use utf8;
binmode(STDOUT,':utf8');
use Encode::IMAPUTF7;

=head1 NAME

    MailClientRYPT - Client for sending and receiving mail with encryption!

=head1 VERSION

    Version 1.00

=head1 SYNOPSIS

    ToDo info about what module does

=head1 EXPORT

    ToDo info about export functions

=head1 SUBROUTINES/METHODS
=cut


# цвета для полей:
my $colorDefault = "\x1b[0m";
my $colorQuestions = "\x1b[0m";
my $colorAnswerLine = "\x1b[0m";
my $colorMenuNumber = "\x1b[32m";
my $colorMenuString = "\x1b[0m";
my $colorMenuSpecString = "\x1b[0m";
my $colorMenuExitString = "\x1b[0m";
my $colorInfoString = "\x1b[32m";
my $colorInfoErrorString = "\x1b[1;31m";

=head1 MailClient
	Функция, в которой осуществляется:
		1 - подключение к почтовому серверу
		2 - после удачного подключения выводится список доступных папок
		3 - при выборе папке выводится список доступных сообщений
		4 - при выборе сообщения выводится его содержимое
=cut
sub MailClient {
	my $server = shift;
	my $user = shift;
	my $password = shift;

	# устанавливаем соединение с почтовым сервером
	my $imap = Mail::IMAPClient->new(
		Server   => $server,
		User     => $user,
		Password => $password,
		Ssl      => 1,
		Uid      => 1,
	) or die $colorInfoErrorString . "Can't connect to your mail server." . $colorDefault . "\n";

	# получаем с сервера список папок
	my $folders = $imap->folders
		or die $colorInfoErrorString . "Folders list Error: " . $imap->LastError . $colorDefault . "\n";

	my ($folderNum, $curFolder, $i, @msgs);
	while (1)
	{
		# запрашиваем у пользователя номер папки для просмотра писем
		$i = 0;
		say $colorQuestions . '-----------------------------------------------------' . $colorDefault;
		say $colorQuestions . 'Введите номер соответствующий нужной папке сообщений:' . $colorDefault;
		say $colorQuestions . '-----------------------------------------------------' . $colorDefault;
		for (@$folders) {
			say $colorMenuNumber . $i++ . $colorMenuString . " -> " . Encode::decode("IMAP-UTF-7", $_) . $colorDefault;
		}
		say $colorMenuNumber . $i++ . $colorMenuSpecString . " -> перейти к отправке сообщений." . $colorDefault;
		say $colorMenuNumber . $i . $colorMenuExitString . " -> разлогиниться и выйти из почтового клиента." . $colorDefault;
		print $colorAnswerLine . "Выбранная папка - " . $colorDefault;
		$folderNum = <STDIN>;
		chomp($folderNum);

		# Прокерка валидности номера папки (только число от 0 до $#{$folders} + 2)
		if ($folderNum - 2 > $#{$folders} or $folderNum !~ /^\d+$/) {
			system('clear');
			print $colorInfoErrorString . "Введен некорректный номер папки '$folderNum'\n" . $colorDefault;
			next;
		}
		# Перейти к отправке сообщений
		if ($folderNum - 1 == $#{$folders}) {
			system('clear');
			# ToDo вызов функции отправки сообщений
			next;
		}
		# Выход
		if ($folderNum - 2 == $#{$folders}) {
			system('clear');
			last;
		}

		# выбираем папку как текущую
		$imap->select( @{ $folders }[$folderNum] );
		$curFolder = Encode::decode("IMAP-UTF-7", @{ $folders }[$folderNum]);
		# получаем список сообщений из данной папки
		@msgs = $imap->messages or do {
			# или возвращаемся к выбору папки если в выбранной нет ни одного письма
			system('clear');
			print $colorInfoErrorString . "Нет сообщений в папке '$curFolder'\n" . $colorDefault;
			next;
		};
		system('clear');
		# Забираем информацию о сообщениях из текущей папки
		# FLAGS \seen - Просмотрено
		# INTERNALDATE - дата и время отправки по GMT
		# Нужно достать From: Subject: Date: и INTERNALDATE
		my $hashref = $imap->fetch_hash( qw/INTERNALDATE RFC822.HEADER/ );	# FLAGS ENVELOPE BODYSTRUCTURE RFC822.SIZE RFC822.TEXT
		my %msgInfoHash = ();
		for my $k (keys %$hashref) {
			$msgInfoHash{ $k }{ INTERNALDATE } = $hashref->{ $k }{ INTERNALDATE };
			my @list = $hashref->{ $k }{ 'RFC822.HEADER' } =~ /(?:From:|Subject:|Date:)\s(.+)/g;
			chop($_) foreach (@list);
			$msgInfoHash{ $k }{ From1 } = $list[0];
			$msgInfoHash{ $k }{ From2 } = $list[1];
			$msgInfoHash{ $k }{ Subject } = $list[2];
			$msgInfoHash{ $k }{ SenderLocalDate } = $list[3];
			# информационная строка:
			$msgInfoHash{ $k }{ ShortInfoString } = "$list[1] ($list[2]) ($list[3])";
			$msgInfoHash{ $k }{ InfoString } = "От: $list[0] ($list[1])\nЗаголовок: $list[2]\nВремя отправления: $list[3]\nВнутреннее время: " . $msgInfoHash{ $k }{ INTERNALDATE };
		}

		my ($msgid, $string);
		while (1)
		{
			say $colorInfoString . '_____________________________________________________' . $colorDefault;
			say $colorInfoString . "Текущая папка: $curFolder" . $colorDefault;
			# запрашиваем у пользователя номер желаемого к прочтению сообщения
		    say $colorQuestions . '-----------------------------------------------------' . $colorDefault;
			say $colorQuestions . 'Введите номер соответствующий сообщению для прочтения' . $colorDefault;
			say $colorQuestions . '-----------------------------------------------------' . $colorDefault;
			for (@msgs) {
				say $colorMenuNumber . "$_" . $colorMenuString . " -> " . $msgInfoHash{ $_ }{ ShortInfoString } . $colorDefault;
			}
			say $colorMenuNumber . "0" . $colorMenuExitString . " -> вернуться к выбору папки." . $colorDefault;
			print $colorAnswerLine . "Выбранное сообщение - " . $colorDefault;
			$msgid = <STDIN>;
			chomp($msgid);

			# Возврат
			if ($msgid == 0) {
				system('clear');
				last;
			}
			# получаем сообщение
			$string = $imap->body_string($msgid) or do {
				# или выводим сообщения с запрошенным номером нет
				system('clear');
				print $colorInfoErrorString . "Нет сообщения с таким номером($msgid) в папке '$curFolder'\n" . $colorDefault;
				next;
			};

			system('clear');
			say $colorInfoString . '_____________________________________________________'. $colorDefault;
			say $colorInfoString . "Информация о сообщении:\nНомер: $msgid\n" . $msgInfoHash{ $msgid }{ InfoString } . $colorDefault;

			# обрабатываем сообщение
			$string =~ s/(<div>)([^<]*)(<\/div>)/$2\n/g;
			chop($string);
			# заменим спецсимволы на символы
			$string =~ s/(&lt;)/</g;
			$string =~ s/(&gt;)/>/g;
			$string =~ s/(&amp;)/&/g;
			# кодируем в utf8
			$string = Encode::decode("utf8", $string);
			# выводим сообщение
			say '-----------------------------------------------------';
			say '------------------- Mail contain: -------------------';
			say '-----------------------------------------------------';
			print $string;
			say '-----------------------------------------------------';
			say '------------------- Mail end line -------------------';
			say '-----------------------------------------------------';

			# ожидание ввода:
			say '';
			say $colorInfoString . "Нажмите Enter чтобы вернуться к выбору другого сообщения." . $colorDefault;
			$string = <STDIN>;
			system('clear');
			next;
		}
	}

	# выходим из почты
	$imap->logout or die $colorInfoErrorString . "Logout error: " . $imap->LastError . $colorDefault . "\n";
	return;
}

=head2 SendMail
	Функция реализующая отправку сообщений
	Входные параметры:
		1 - авторизованный экземпляр класса IMAP::MailClient.
=cut
sub SendMail {
	my $imap = shift;

	my ($to, $subject, $body);

	return;
}


=head1 Import\Unimport
=cut
my @ImportedByDefault = qw/MailClient/;
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

