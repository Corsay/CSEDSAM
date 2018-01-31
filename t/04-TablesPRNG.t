#!/usr/bin/perl
use 5.010;
use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

plan tests => 4;

use TablesPRNG;

# Тестирование модуля генерации таблиц
# Генерация таблицы первого типа
ok(1, "test1");
#ToDo tests

# Генерация таблицы второго типа
ok(1, "test2");
#ToDo tests

# Сохранение таблицы в файл (json)
ok(1, "test3");
#ToDo tests

# Выгрузка таблицы из файла
ok(1, "test4");
#ToDo tests
