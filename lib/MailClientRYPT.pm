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
	) or die "Can't connect to your mail server.\n";

	# получаем с сервера список папок
	my $folders = $imap->folders
		or die "Folders list Error: ", $imap->LastError, "\n";

	my ($folderNum, $curFolder, $i, @msgs);
	while (1)
	{
		# запрашиваем у пользователя номер папки для просмотра писем
		$i = 0;
		say '-----------------------------------------------------';
		say 'Введите номер соответствующий нужной папке сообщений:';
		say '-----------------------------------------------------';
		for (@$folders) {
			say $i++ . " -> " . Encode::decode("IMAP-UTF-7", $_);
		}
		say $i . " -> разлогиниться и выйти из почтового клиента.";
		print "Выбранная папка - ";
		$folderNum = <STDIN>;

		# Прокерка валидности номера папки (только число от 0 до $#{$folders} + 1)
		if ($folderNum - 1 > $#{$folders} or $folderNum !~ /^\d+$/) {
			system('clear');
			chomp($folderNum);
			print "Введен некорректный номер папки '$folderNum'\n";
			next;
		}
		# Выход
		if ($folderNum - 1 == $#{$folders}) {
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
			print "Нет сообщений в папке '$curFolder'\n";
			next;
		};
		# Забираем информацию о сообщениях из текущей папки
		# FLAGS \seen - Просмотрено
		#my $hashref = $imap->fetch_hash( qw/FLAGS INTERNALDATE RFC822.HEADER RFC822.SIZE/ );	# ENVELOPE BODYSTRUCTURE RFC822.TEXT
		#p $hashref;
		system('clear');

		my ($msgid, $string);
		while (1)
		{
			say '_____________________________________________________';
			say "Текущая папка: $curFolder";
			# запрашиваем у пользователя номер желаемого к прочтению сообщения
		    say '-----------------------------------------------------';
			say 'Введите номер соответствующий сообщению для прочтения:';
			say '-----------------------------------------------------';
			for (@msgs) {
				say $_;
			}
			say "0 -> вернуться к выбору папки.";
			print "Выбранное сообщение - ";
			$msgid = <STDIN>;

			# Возврат
			if ($msgid == 0) {
				system('clear');
				last;
			}
			# получаем сообщение
			$string = $imap->body_string($msgid) or do {
				# или выводим сообщения с запрошенным номером нет
				system('clear');
				chomp($msgid);
				print "Нет сообщения с таким номером($msgid) в папке '$curFolder'\n";
				next;
			};

			system('clear');
			say '_____________________________________________________';
			say "Выбранное сообщение: №$msgid";

			# обрабатываем сообщение
			$string =~ s/(<div>)([^<]*)(<\/div>)/$2\n/g;
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
			say "Нажмите Enter чтобы вернуться к выбору другого сообщения.";
			$string = <STDIN>;
			system('clear');
			next;
		}
	}

	# выходим из почты
	$imap->logout or die "Logout error: ", $imap->LastError, "\n";
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

