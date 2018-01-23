#!/usr/bin/perl
use 5.010;
use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

plan tests => 3;

use EncDecRYPT;

# Тестирование наложение ГАММЫ на сообщение, с учетом особенностей
# 1 - при длине сообщения больше длины ключа (гаммы)
ok(1,"test 1");
# ToDo Tests


# 2 - при длине сообщения меньше длины ключа (гаммы)
ok(1,"test 2");
# ToDo Tests


# 3 - при длине сообщения больше длины ключа (гаммы), но при этом длина последней части сообщения меньше длины ключа (гаммы)
ok(1,"test 3");
# ToDo Tests
