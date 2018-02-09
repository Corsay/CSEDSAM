#!/usr/bin/perl
use 5.010;
use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

plan tests => 23;

use TablesPRNG;

# ToDO вынести в TestUtil модуль подобные функции
use Time::Moment;
=head
	Функция получения времени выполнения функции
	Входные параметры:
		1 - ссылка на массив для добавления статистики;
		2 - ссылка на функцию;
		3 - ссылка на массив параметров для функции;
		4 - префикс к записываемому в массив времени.
	Выходные параметры:
		1 - модифицированный массив статистики; (с добавленной строкой вида 'Префикс sprintf("%7d %12d %12d %11d", $seconds, $milliseconds, $microseconds, $nanoseconds);')
		2 - результат;
=cut
sub AddTimeMeter {
	my $timerMas = shift;
	my $subRef = shift;
	my $subParamsRef = shift;
	my $prefix = shift;

	# фиксируем время начала
	my ($tm1, $tm2, $tm);
	$tm1 = Time::Moment->now;

	# выполняем функцию
	my $rezPerem = $subRef->( @$subParamsRef );

	# фиксируем время завершения и сохраняем разницу
	$tm2 = Time::Moment->now;
	my $seconds      = $tm1->delta_seconds($tm2);
	my $milliseconds = $tm1->delta_milliseconds($tm2);
	my $microseconds = $tm1->delta_microseconds($tm2);
	my $nanoseconds  = $tm1->delta_nanoseconds($tm2);
	$tm = sprintf(" %7d %12d %12d %11d", $seconds, $milliseconds, $microseconds, $nanoseconds);

	# добавляем в массив запись о времени
	push @$timerMas, $prefix . $tm;

	return $rezPerem;
}


##### Тестирование модуля генерации таблиц
### Генерация ключей
# 'ключ' 'догенерированный ключ' 'ГПСЧ' 'Вектор состояния'
my ($key, $keyMax, $prng, @stateVect);
# без передачи ссылки на генератор
$key = GenerateKey( {}, $TablesPRNG::SHORT_KEY_LEN);
is( length($key), $TablesPRNG::SHORT_KEY_LEN, 'Key generator: Short key len generate');
$key = GenerateKey( {}, $TablesPRNG::LONG_KEY_LEN);
is( length($key), $TablesPRNG::LONG_KEY_LEN, 'Key generator: Long key len generate');
$key = GenerateKey( {}, $TablesPRNG::MAX_KEY_LEN);
is( length($key), $TablesPRNG::MAX_KEY_LEN, 'Key generator: Max key len generate');

# с передачей ссылки на генератор
$prng = Math::Random::MT::Auto->new();
$key = GenerateKey( {}, $TablesPRNG::SHORT_KEY_LEN, $prng);
is( length($key), $TablesPRNG::SHORT_KEY_LEN, 'Key generator: Short key len generate with preinit PRNG');
$key = GenerateKey( {}, $TablesPRNG::LONG_KEY_LEN, $prng);
is( length($key), $TablesPRNG::LONG_KEY_LEN, 'Key generator: Long key len generate with preinit PRNG');
$key = GenerateKey( {}, $TablesPRNG::MAX_KEY_LEN, $prng);
is( length($key), $TablesPRNG::MAX_KEY_LEN, 'Key generator: Max key len generate with preinit PRNG');

# проверка идентичности генерации при передаче stateVect
@stateVect = $prng->get_state();
$key = GenerateKey( {}, $TablesPRNG::SHORT_KEY_LEN, undef, \@stateVect);
$keyMax = GenerateKey( {}, $TablesPRNG::MAX_KEY_LEN, undef, \@stateVect);
is ( $key, substr($keyMax, 0, $TablesPRNG::SHORT_KEY_LEN) , 'Key generator: Short key equal with part of Max Key with the same StateVect');



### Генерация таблиц
# 'начальные параметры' 'конечные параметры' 'сгенерированная таблица первого типа' 'сгенерированная таблица второго типа' 'дубликаты суточных таблиц каждого типа'
my ($startParams, $endParams, $hashTable, $hashTableLong, $hashTableDay, $hashTableDayLong);
my @timingMasShor = ("     PREFIX     : seconds milliseconds microseconds nanoseconds"); # 'массив для тайминга'
my @timingMasLong = ("     PREFIX     : seconds milliseconds microseconds nanoseconds"); # 'массив для тайминга'
# Заметка
note("\n" . 'Short table generator and Long table generator TESTS imply what $defTimePartExpander = 120 (2 minutes in unix_time).');
note('If you change $defTimePartExpander, you can ignore mistakes in this part of tests. Part of table generation tests can take few seconds (around ten)');
note('');
# начало периода 1 января 2018 года 00:00 (начало первой недели - понедельник)
$startParams = { seconds => 0, minut => 0, hour => 0, day => 1, month => 1, year => 2018, WeekNum => 1, };
# Генерация таблицы первого и второго типа
$endParams = { seconds => 59, minut => 59, hour => 23, day => 31, month => 12, year => 2017, };
$hashTable     = AddTimeMeter(\@timingMasShor, \&ShortTableGenerator, [ $startParams, $endParams ], ' Short :      0 :');
$hashTableLong = AddTimeMeter(\@timingMasLong, \&LongTableGenerator,  [ $startParams, $endParams ], ' Long  :      0 :');
is( scalar keys %{$hashTable}, 0, 'Short table generator: end time less then start time key count check (0)');
is( scalar keys %{$hashTableLong}, 0, 'Long table generator: end time less then start time key count check (0)');

$endParams = { seconds => 0, minut => 0, hour => 0, day => 1, month => 1, year => 2018, };
$hashTable     = AddTimeMeter(\@timingMasShor, \&ShortTableGenerator, [ $startParams, $endParams ], ' Short :      1 :');
$hashTableLong = AddTimeMeter(\@timingMasLong, \&LongTableGenerator,  [ $startParams, $endParams ], ' Long  :      1 :');
is( scalar keys %{$hashTable}, 1, 'Short table generator: equal time key count check (1)');
is( scalar keys %{$hashTableLong}, 1, 'Long table generator: equal time key count check (1)');

$endParams = { seconds => 0, minut => 2, hour => 0, day => 1, month => 1, year => 2018, };
$hashTable     = AddTimeMeter(\@timingMasShor, \&ShortTableGenerator, [ $startParams, $endParams ], ' Short :      2 :');
$hashTableLong = AddTimeMeter(\@timingMasLong, \&LongTableGenerator,  [ $startParams, $endParams ], ' Long  :      2 :');
is( scalar keys %{$hashTable}, 2, 'Short table generator: two minute key count check (2)');
is( scalar keys %{$hashTableLong}, 2, 'Long table generator: two minute key count check (2)');

$endParams = { seconds => 0, minut => 58, hour => 0, day => 1, month => 1, year => 2018, };
$hashTable     = AddTimeMeter(\@timingMasShor, \&ShortTableGenerator, [ $startParams, $endParams ], ' Short :     30 :');
$hashTableLong = AddTimeMeter(\@timingMasLong, \&LongTableGenerator,  [ $startParams, $endParams ], ' Long  :     30 :');
is( scalar keys %{$hashTable}, 30, 'Short table generator: one hour key count check (30)');
is( scalar keys %{$hashTableLong}, 30, 'Long table generator: one hour key count check (30)');

$endParams = { seconds => 0, minut => 58, hour => 23, day => 1, month => 1, year => 2018, };
$hashTableDay     = $hashTable     = AddTimeMeter(\@timingMasShor, \&ShortTableGenerator, [ $startParams, $endParams ], ' Short :    720 :');
$hashTableDayLong = $hashTableLong = AddTimeMeter(\@timingMasLong, \&LongTableGenerator,  [ $startParams, $endParams ], ' Long  :    720 :');
is( scalar keys %{$hashTable}, 720, 'Short table generator: one day key count check (720)');
is( scalar keys %{$hashTableLong}, 720, 'Long table generator: one day key count check (720)');

$endParams = { seconds => 0, minut => 0, hour => 0, day => 8, month => 1, year => 2018, };
$hashTable     = AddTimeMeter(\@timingMasShor, \&ShortTableGenerator, [ $startParams, $endParams ], ' Short :    721 :');
$hashTableLong = AddTimeMeter(\@timingMasLong, \&LongTableGenerator,  [ $startParams, $endParams ], ' Long  :   5041 :');
is( scalar keys %{$hashTable}, 721, 'Short table generator: full one week + one minute from next week key count check (721)');
is( scalar keys %{$hashTableLong}, 5041, 'Long table generator: full one week + one minute from next week key count check (5041)');

$endParams = { seconds => 0, minut => 58, hour => 23, day => 30, month => 12, year => 2018, };
$hashTable     = AddTimeMeter(\@timingMasShor, \&ShortTableGenerator, [ $startParams, $endParams ], ' Short :  37440 :');
$hashTableLong = AddTimeMeter(\@timingMasLong, \&LongTableGenerator,  [ $startParams, $endParams ], ' Long  : 262080 :');
is( scalar keys %{$hashTable}, 37440, 'Short table generator: 52 week key count check (37440)');
is( scalar keys %{$hashTableLong}, 262080, 'Long table generator: 52 week key count check (262080)');



### Сохранение и загрузка таблицы
# 'Таблица для сохранения в файл' 'Выгруженная из файла таблица'
my ($dictToFile, $dictFromFile);
if (defined $ARGV[0] and $ARGV[0] eq '0') { # жесткий тест (загрузка таблиц на 52 недели)
	# Заметка
	note("\n" . 'Save\Load tests in 52 week Variant can take some time (around one minute)');
	note('');
	# Тестирование словаря первого типа:
	$dictToFile = $hashTable;
	SaveTableToFile $dictToFile, 'dictOne.json';
	$dictFromFile = LoadTableFromFile 'dictOne.json';
	is_deeply($dictToFile, $dictFromFile, "Save/Load test: dict type one (52 week)");
	unlink('dictOne.json');
	# Тестирование словаря второго типа:
	$dictToFile = $hashTableLong;
	SaveTableToFile $dictToFile, 'dictTwo.json';
	$dictFromFile = LoadTableFromFile 'dictTwo.json';
	is_deeply($dictToFile, $dictFromFile, "Save/Load test: dict type two (52 week)");
	unlink('dictTwo.json');
}
else { # мягкий тест (загрузка таблиц на день)
	# Заметка
	note("\n" . 'Save\Load tests');
	note('');
	# Тестирование словаря первого типа:
	$dictToFile = $hashTableDay;
	SaveTableToFile $dictToFile, 'dictOne.json';
	$dictFromFile = LoadTableFromFile 'dictOne.json';
	is_deeply($dictToFile, $dictFromFile, "Save/Load test: dict type one (Day)");
	unlink('dictOne.json');
	# Тестирование словаря второго типа:
	$dictToFile = $hashTableDayLong;
	SaveTableToFile $dictToFile, 'dictTwo.json';
	$dictFromFile = LoadTableFromFile 'dictTwo.json';
	is_deeply($dictToFile, $dictFromFile, "Save/Load test: dict type two (Day)");
	unlink('dictTwo.json');
}

note("\n" . 'Generation time statistics');
note('');
say $_ foreach (@timingMasShor);
say '';
say $_ foreach (@timingMasLong);
