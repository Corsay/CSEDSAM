#!/usr/bin/perl
use 5.010;
use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

plan tests => 4;

use TablesPRNG;

##### Тестирование модуля генерации таблиц
### Генерация таблицы первого типа
ok(1, "test1");
#ToDo tests


### Генерация таблицы второго типа
ok(1, "test2");
#ToDo tests


### Сохранение и загрузка таблицы
# Тестирование словаря первого типа:
my $dictToFile = {
	"2-10-10" => { WeekNum	=> 2, hour	=> 10, minut	=> 10, key	=> "123456", },
	"2-10-12" => { WeekNum	=> 2, hour	=> 10, minut	=> 12, key	=> "789012", },
	"2-10-14" => { WeekNum	=> 2, hour	=> 10, minut	=> 14, key	=> "345678", },
	"2-10-16" => { WeekNum	=> 2, hour	=> 10, minut	=> 16, key	=> "234567", },
	"2-10-18" => { WeekNum	=> 2, hour	=> 10, minut	=> 18, key	=> "234567", },
	"2-10-20" => { WeekNum	=> 2, hour	=> 10, minut	=> 20, key	=> "234567", },
	"2-10-22" => { WeekNum	=> 2, hour	=> 10, minut	=> 22, key	=> "234567", },
	"2-10-24" => { WeekNum	=> 2, hour	=> 10, minut	=> 24, key	=> "234567", },
	"2-10-26" => { WeekNum	=> 2, hour	=> 10, minut	=> 26, key	=> "234567", },
	"2-10-28" => { WeekNum	=> 2, hour	=> 10, minut	=> 28, key	=> "234567", },
	"2-10-30" => { WeekNum	=> 2, hour	=> 10, minut	=> 30, key	=> "234567", },
	"2-10-32" => { WeekNum	=> 2, hour	=> 10, minut	=> 32, key	=> "234567", },
	"2-10-34" => { WeekNum	=> 2, hour	=> 10, minut	=> 34, key	=> "234567", },
	"2-10-36" => { WeekNum	=> 2, hour	=> 10, minut	=> 36, key	=> "234567", },
	"2-10-38" => { WeekNum	=> 2, hour	=> 10, minut	=> 38, key	=> "234567", },
	"2-10-40" => { WeekNum	=> 2, hour	=> 10, minut	=> 40, key	=> "234567", },
	"2-10-42" => { WeekNum	=> 2, hour	=> 10, minut	=> 42, key	=> "234567", },
	"2-10-44" => { WeekNum	=> 2, hour	=> 10, minut	=> 44, key	=> "234567", },
	"2-10-46" => { WeekNum	=> 2, hour	=> 10, minut	=> 46, key	=> "234567", },
	"2-10-48" => { WeekNum	=> 2, hour	=> 10, minut	=> 48, key	=> "234567", },
	"2-10-50" => { WeekNum	=> 2, hour	=> 10, minut	=> 50, key	=> "234567", },
	"2-10-52" => { WeekNum	=> 2, hour	=> 10, minut	=> 52, key	=> "234567", },
};
my $dictFromFile = ();
SaveTableToFile $dictToFile, 'dictOne.json';
$dictFromFile = LoadTableFromFile 'dictOne.json';
is_deeply($dictToFile, $dictFromFile, "Save/Load test: dict one");
unlink('dictOne.json');

# Тестирование словаря второго типа:
$dictToFile = {
	"1-10-10-10" => { month	=> 1, day	=> 10, hour	=> 10, minut	=> 10, key	=> "123456", },
	"1-10-10-12" => { month	=> 1, day	=> 10, hour	=> 10, minut	=> 12, key	=> "789012", },
	"1-10-10-14" => { month	=> 1, day	=> 10, hour	=> 10, minut	=> 14, key	=> "345678", },
	"1-10-10-16" => { month	=> 1, day	=> 10, hour	=> 10, minut	=> 16, key	=> "234567", },
};
SaveTableToFile $dictToFile, 'dictTwo.json';
$dictFromFile = LoadTableFromFile 'dictTwo.json';
is_deeply($dictToFile, $dictFromFile, "Save/Load test: dict two");
unlink('dictTwo.json');
