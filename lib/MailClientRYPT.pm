package MailClientRYPT 1.00;

use 5.010;
use strict;
use warnings;

use Mail::IMAPClient;

use Email::Simple;
use Email::Sender::Simple qw(sendmail);
use Email::Sender::Transport::SMTP;

use TablesPRNG;
use EncDecRYPT;
use MIME::Base64;

use utf8;
binmode(STDOUT,':utf8');
use Encode::IMAPUTF7;

use YAML::Tiny;

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

# ToDo использовать ООП

# Ключевые параметры
my ($keyParamsOne, $keyParamsTwo, $currentDict, $currentKeyParams);
my $dictFiles = {
	0 => 'dictOne.json',
	1 => 'dictTwo.json',
};
my $dictCurrentFile;

$currentKeyParams = {
	seconds	=> 10,
	minut	=> 10,
	hour	=> 10,
	day	=> 26,
	month	=> 3,
	year	=> 2018,
	WeekNum	=> 13,
	concat	=> "13-10-10"
};

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

=head1
	Спецификация файла конфигурации:
	MailClient:
		InboxMailServer:             # сервер входящей почты
			Server: 'imap.yandex.ru'  # адрес
			Port: 993                 # порт
			Ssl: 1                    # использовать ли ssl
			Uid: 1                    # uid
		OutboxMailServer:            # сервер исходящей почты
			host: 'smtp.yandex.ru'    # адрес
			port: 465                 # порт
			ssl: 1                    # использовать ли ssl
		encode: '1'                  # Щифровать и расшифровывать ли сообщения (0 - нет, 1 - да)
		clearKey: '1'                # Зачищать ли ключи после использования (0 - нет, 1 - да)
		dict_type: '0'               # Тип используемого словаря (0 - первый тип(короткие ключи), 1 - второй тип(длинные ключи))
		date_params_type: '0'        # Способ определения параметров даты сообщения (0 - дата вводится в ручную(по Гринвичу), 1 - дата берется из заголовка сообщения(локальная дата отправителя))
=cut
my $MailClientParams;	# переменная для загрузки в неё конфигурации
my $encode;
my $clearKey;

=head1 MailClient
	Функция, в которой осуществляется:
		1 - подключение к почтовому серверу
		2 - после удачного подключения выводится список доступных папок
		3 - при выборе папки выводится список доступных сообщений
		4 - при выборе сообщения выводится его содержимое
=cut
sub MailClient {
	my $user = shift;
	my $password = shift;

	# загрузка конфигурации из файла MailClient.yml
	$MailClientParams = YAML::Tiny->read('MailClient.yml');
	$MailClientParams = $MailClientParams->[0];
	$encode = $MailClientParams->{ MailClient }{ encode } // 1;	# включать ли шифрование (по-умолчанию -> включать)
	$clearKey = $MailClientParams->{ MailClient }{ clearKey } // 1;	# зачищать ли ключи (по-умолчанию -> да)
	# $MailClientParams->{ MailClient }{ date_params_type };

	# Cобираем настройки согласно конфигурации + добавляем User и Password
	my %conParams = ( %{ $MailClientParams->{ MailClient }{ InboxMailServer } } );
	$conParams{ User } = $user;
	$conParams{ Password } = $password;

	# Получаем тип активной таблицы (согласно конфигурации) и запоминаем в каком файле должна находиться соответствующая таблица
	my $dictType = $MailClientParams->{ MailClient }{ dict_type };
	$dictCurrentFile = $dictFiles->{$dictType};
	# Если файла с таблицей(словарем) нет, то создать его и сохранить в файл
	unless ( -e $dictCurrentFile ) {
		print "\n" . 'Генерация таблицы ключей (занимает около 5-15 секунд).' . "\n";
		# начальный период - текущий день (по-Гринвичу)
		my ($startParams, $endParams);
		# берем текущее время
		my @time = gmtime(time);
		$startParams->{seconds} = $time[0]; $startParams->{minut} = 0; $startParams->{hour} = $time[2];
		$startParams->{day} = $time[3]; $startParams->{month} = $time[4] + 1; $startParams->{year} = $time[5] + 1900;
		$startParams->{WeekNum} = int($time[7] / 7) + 1;
		# приведем начальную дату к понедельнику текущей недели
		$startParams = TimePartAdd( $startParams, -86400 * ($time[6] - 1) );
		# конечный период + 51/52 недели ( 30844800 + день(86400) / 31449600 ).
		my $endStartDiff;
		if    ($dictType eq '0') { $endStartDiff = 30844800 + 86400; }
		elsif ($dictType eq '1') { $endStartDiff = 31449600; }
		$endParams = TimePartAdd( $startParams, $endStartDiff - 120 );

		# формируем нужный словарь на 52 недели
		if     ($dictType eq '0') { $currentDict = ShortTableGenerator( $startParams, $endParams ); }
		elsif  ($dictType eq '1') { $currentDict = LongTableGenerator ( $startParams, $endParams ); }
		# ToDo проконтролировать что таблица была создана

		print "Итого ключей сгенерированно - " . scalar keys %{$currentDict};
		print "\n" . 'Генерация таблицы ключей завершена' . "\n";
		print 'Сохранение таблицы ключей в файл ' . $dictCurrentFile . " (занимает около 5 секунд)\n";
		# cохраняем полученную таблицу в файл
		SaveTableToFile( $currentDict, $dictCurrentFile );
		# сообщаем пользователю о завершении генерации таблицы и рекомендацию
		print 'Таблица ключей сохранена' . "\n";
		print 'Рекомендуется позаботиться о её передаче собеседнику до дальнейшего использования почтового клиента.' . "\n\n";
	}
	else { # иначе загрузить из существующего файла
		print "\n" . 'Загрузка таблицы ключей из файла ' . $dictCurrentFile . "\n";
		$currentDict = LoadTableFromFile( $dictCurrentFile );
		print 'Таблица ключей загружена' . "\n\n";
	}



	# устанавливаем соединение с почтовым сервером
	my $imap = Mail::IMAPClient->new( %conParams ) or die $colorInfoErrorString . "Can't connect to your mail server." . $colorDefault . "\n";
	# выходить с сообщением об ошибке, если соединение с почтовым сервером не было успешным
	die $colorInfoErrorString . "Can't connect to your mail server." . $colorDefault . "\n" unless ( defined $imap->{Server} );

	# получаем с сервера список папок
	my $folders = $imap->folders
		or die $colorInfoErrorString . "Folders list Error: " . $imap->LastError . $colorDefault . "\n";

	my ($folderNum, $curFolder, $i, @msgs);
	while (1) {
		# запрашиваем у пользователя номер папки для просмотра писем
		$i = 0;
		say $colorQuestions . '-----------------------------------------------------' . $colorDefault;
		say $colorQuestions . 'Введите номер соответствующий нужной папке сообщений:' . $colorDefault;
		say $colorQuestions . '-----------------------------------------------------' . $colorDefault;
		for (@$folders) {
			say $colorMenuNumber . $i++ . $colorMenuString . " -> " . Encode::decode("IMAP-UTF-7", $_) . $colorDefault;
		}
		say $colorMenuNumber . $i++ . $colorMenuSpecString . " -> перейти к отправке сообщений." . $colorDefault;
		# ToDo Добавить отсылку на функцию работы с конфигурацией
		say $colorMenuNumber . $i . $colorMenuExitString . " -> разлогиниться и выйти из почтового клиента." . $colorDefault;
		print $colorAnswerLine . "Выбранная папка - " . $colorDefault;
		$folderNum = <STDIN>;
		chomp($folderNum);

		system('clear');
		# Прокерка валидности номера папки (только число от 0 до $#{$folders} + 2)
		if ($folderNum - 2 > $#{$folders} or $folderNum !~ /^\d+$/) {
			print $colorInfoErrorString . "Введен некорректный номер папки '$folderNum'\n" . $colorDefault;
			next;
		}
		# Перейти к отправке сообщений
		if ($folderNum - 1 == $#{$folders}) {
			SendMail($imap); # вызов функции отправки сообщений
			next;
		}
		# Выход
		if ($folderNum - 2 == $#{$folders}) {
			last;
		}

		# выбираем папку как текущую
		$imap->select( @{ $folders }[$folderNum] );
		$curFolder = Encode::decode("IMAP-UTF-7", @{ $folders }[$folderNum]);
		# получаем список сообщений из данной папки
		@msgs = $imap->messages or do {
			# или возвращаемся к выбору папки если в выбранной нет ни одного письма
			print $colorInfoErrorString . "Нет сообщений в папке '$curFolder'\n" . $colorDefault;
			next;
		};
		# Забираем информацию о сообщениях из текущей папки
		# ToDo вынести в отдельную функцию
		# FLAGS \seen - Просмотрено
		# INTERNALDATE - дата и время отправки по GMT
		my $hashref = $imap->fetch_hash( qw/INTERNALDATE RFC822.HEADER RFC822.TEXT/ );	# FLAGS ENVELOPE BODYSTRUCTURE RFC822.SIZE
		my %msgInfoHash = ();
		for my $k (keys %$hashref) {
			# забираем нужные части из RFC822.HEADER
			my %Head = ();
			my @NeedHead = qw/From Subject Date Content-Transfer-Encoding Content-Type/;
			# ToDo обработка двустрочных частей в RFC822.HEADER
			foreach (@NeedHead) { $Head{ $_ } = $1 if ( $hashref->{ $k }{ 'RFC822.HEADER' } =~ /(?:$_:)\s(.+)/ ); }

			# разбираем и обрабатываем каждый ключ из хеша с нужными заголовками
			for my $k (keys %Head) {
				chop( $Head{ $k } );	# отрезаем символ в конце строки
				# парсим части RFC822.HEADER закодированные в base64 '=?utf-8?B?'
				if ( $Head{ $k } =~ /=\?utf-8\?[Bb]\?/ ) {
					my @ParseHead = ( $Head{ $k } =~ /=\?utf-8\?[Bb]\?(.*)\?=(.*)/g );
					$Head{ $k } = '';
					my $i = 0;
					while ($i <= $#ParseHead) {
						$Head{ $k } .= decode_base64($ParseHead[ $i++ ]) . $ParseHead[ $i++ ];
					}
					$Head{ $k } = Encode::decode("utf8", $Head{ $k });
				}
			}

			# сохраняем поля в нужном виде и добавляем дополнительную информацию
			$msgInfoHash{ $k }{ INTERNALDATE } = $hashref->{ $k }{ INTERNALDATE };
			foreach (@NeedHead) { $msgInfoHash{ $k }{ $_ } = $Head{ $_ } // ''; }
			# информационная строка:
			$msgInfoHash{ $k }{ SInfStr } = "$msgInfoHash{ $k }{ From } ($msgInfoHash{ $k }{ Subject }) ($msgInfoHash{ $k }{ Date })";
			$msgInfoHash{ $k }{ InfStr } = "От: $msgInfoHash{ $k }{ From }\nЗаголовок: $msgInfoHash{ $k }{ Subject }\n" .
				"Время отправления: $msgInfoHash{ $k }{ Date }\nВнутреннее время: " . $msgInfoHash{ $k }{ INTERNALDATE };
		}



		my ($msgid, $string);
		while (1) {
			say $colorInfoString . '_____________________________________________________' . $colorDefault;
			say $colorInfoString . "Текущая папка: $curFolder" . $colorDefault;
			# запрашиваем у пользователя номер желаемого к прочтению сообщения
		    say $colorQuestions . '-----------------------------------------------------' . $colorDefault;
			say $colorQuestions . 'Введите номер соответствующий сообщению для прочтения' . $colorDefault;
			say $colorQuestions . '-----------------------------------------------------' . $colorDefault;
			for (@msgs) {
				say $colorMenuNumber . "$_" . $colorMenuString . " -> " . $msgInfoHash{ $_ }{ SInfStr } . $colorDefault;
			}
			say $colorMenuNumber . "0" . $colorMenuExitString . " -> вернуться к выбору папки." . $colorDefault;
			print $colorAnswerLine . "Выбранное сообщение - " . $colorDefault;
			$msgid = <STDIN>;
			chomp($msgid);

			system('clear');
			# Возврат
			if ($msgid == 0) {
				last;
			}
			# получаем сообщение
			$string = $imap->body_string($msgid) or do {
				# или выводим сообщения с запрошенным номером нет
				print $colorInfoErrorString . "Нет сообщения с таким номером($msgid) в папке '$curFolder'\n" . $colorDefault;
				next;
			};

			# ToDo проверить, периодически попадается(разово) в теле сообщения - "...FLAGS... UID..."
			#use DDP;
			#p $hashref->{ $msgid }{ 'RFC822.TEXT' };
			#p $string;
			say $colorInfoString . '_____________________________________________________'. $colorDefault;
			say $colorInfoString . "Информация о сообщении:\nНомер: $msgid\n" . $msgInfoHash{ $msgid }{ InfStr } . $colorDefault;

			# обрабатываем сообщение
			chomp($string);	# убираем символ переноса в конце
			$string =~ s/.{1}$//;	# убираем символ в конце
			# Проводим расшифрование текста
			$string = decode_base64($string) if ($msgInfoHash{ $msgid }{ 'Content-Transfer-Encoding' } eq 'base64'); # расшифровываем из Base64
			$string = Encode::decode("utf8", $string); # расшифровываем из utf8
			# Расшифровываем текст (если указано)
			if ($encode) {
				# ToDo определение параметров для расшифрования

				# Расшифровываем текст
				my $msgMas = EncDecLong($string, $currentDict, $currentKeyParams, undef, $clearKey);
				$string = '';	$string .= $_->{msg} foreach ( @{ $msgMas } );
			}
			$string =~ s/(<div>)?([^<]*)(<\/div>)?/$2\n/g;	# убираем <div>(если есть) и добавляем перенос строки
			chop($string);	# обрезаем перенос после последнего символа
			# заменим спецсимволы на символы
			$string =~ s/(&lt;)/</g;
			$string =~ s/(&gt;)/>/g;
			$string =~ s/(&amp;)/&/g;

			# выводим сообщение
			say '-----------------------------------------------------';
			say '------------------- Mail contain: -------------------';
			say '-----------------------------------------------------';
			print $string;
			say '-----------------------------------------------------';
			say '------------------- Mail end line -------------------';
			say '-----------------------------------------------------';

			# Если ключ был зачищен, перезаписать файл с ключами
			if ($encode and $clearKey and $string) {
				print "\n" . 'Перезапись таблицы ключей (занимает около 5-10 секунд).' . "\n";
				SaveTableToFile( $currentDict, $dictCurrentFile );
				print 'Таблица ключей перезаписана' . "\n";
			}

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
	say $colorInfoString . '_____________________________________________________' . $colorDefault;
	say $colorInfoString . "Отправка сообщения от $imap->{User}" . $colorDefault;
	# запрашиваем у пользователя номер желаемого к прочтению сообщения
	say $colorQuestions . '-----------------------------------------------------' . $colorDefault;
	say $colorQuestions . 'Введите адрес получателя, тему и содержимое сообщения' . $colorDefault;
	say $colorQuestions . '-----------------------------------------------------' . $colorDefault;
	# запрашиваем у пользователя данные для отправки
	print $colorAnswerLine . "Получатель - " . $colorDefault;
	$to = <STDIN>;	# Получатель ($to = 'SomePostAdr@Post.com';)
	chomp($to);
	print $colorAnswerLine . "Тема - " . $colorDefault;
	$subject = <STDIN>;	# Тема ($subject = 'AutoMsg';)
	chomp($subject);
	print $colorAnswerLine . "Сообщение - " . $colorDefault;
	$body = <STDIN>;	# Сообщение ($body = "My msg like this.\n";)
	chomp($body);
	# ToDo обработка не указанных полей

	# шифруем текст (если указано)
	if ($encode) {
		# ToDo определение параметров для шифрования (они же временные параметры для отправки сообщения)

		# шифруем текст
		my $msgMas = EncDecLong($body, $currentDict, $currentKeyParams, undef, $clearKey);	# шифруем сообщение (разбивая на части если нужно)
		$body = '';	$body .= $_->{msg} foreach ( @{ $msgMas } );	# собираем зашифрованный вариант в одно целое

		# ToDo проверяем результат шифрования на undef - ошибка повторного использования ключа(возможно устарела таблица, или некорректность дат)
	}
	$body = Encode::encode("utf8", $body);	# шифруем в utf8
	$body = encode_base64($body);	# шифруем в base64 (чтобы не терять символы \r \n (\r = \r\n \n = \r\n))

	# формируем сообщение
	my $email = Email::Simple->create(
		header => [
			To      => $to,
			From    => $imap->{User},
			Subject => $subject,
			'Content-Transfer-Encoding' => 'base64',
			'Content-Type' => 'text/html; charset=utf-8',
		],
		body => $body,
	);
	# получаем параметры из конфига для сервера через который будем отправлять сообщение
	my %conParams = ( %{ $MailClientParams->{ MailClient }{ OutboxMailServer } } );
	$conParams{ sasl_username } = $imap->{User};
	$conParams{ sasl_password } = $imap->{Password};
	# сообщаем через какой сервер будет отправлять сообщение
	my $transport = Email::Sender::Transport::SMTP->new( %conParams );
	# отправляем сообщение
	sendmail(
		$email,
		{
			transport => $transport,
		}
	);

	# ожидание ввода:
	say '';
	say $colorInfoString . "Нажмите Enter чтобы вернуться к выбору папки." . $colorDefault;
	$body = <STDIN>;
	system('clear');

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

