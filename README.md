Постановка задачи
-----------------
Предположим что имеется два Абонента (Абонент А и Абонент Б) общающихся между собой по почте(исключительно на английском языке(однобайтовые символы)) и предпологаемый противник, заинтересованный в прослушивании их общения.
Абонентам захотелось защитить своё общение и совместными усилиями они приняли решение шифровать свои особо важные сообщения.


Последовательность решения
--------------------------
1. Шифровать сообщение на ключе(гамме) той же длины(в битах) что и сообщение (наложением XOR).
2. Протестировать реализованное за- и рас-шифрование путем за- и рас-шифрования небольшого сообщения.

3. В случае, если длина сообщения больше длины ключа, то разделать сообщение на несколько частей (над каждой выполняя пункт 1).
4. Протестировать реализованное за- и рас-шифрование путем за- и рас-шифрования большого сообщения (большего чем длина ключа).

5. В случае, если длина сообщения меньше длины ключа, то дополнять последнюю его часть незначащими нулевыми битами, для выполнения словия равенства длин сообщения и ключа (гаммы).
6. Протестировать реализованное за- и рас-шифрование путем за- и рас-шифрования большого сообщения (большего чем длина ключа).

7. Подключить качественный ГПСЧ(Генератор ПсевдоСлучайных Чисел).
8. Протестировать подключенный ГПСЧ.

9. Реализовать консольный почтовый клиент - приём и передачу почтовых сообщений:
	* Без указания времени отправки сообщения;
	* С указанием времени отправки сообщения.
10. Протестировать консольный почтовый клиент, создав два тестовых почтовых ящика и обменявшись между ними сообщениями через реализованный клиент.

11. Добавить в почтовый клиент надстройку за- и рас-шифрования.
12. Протестировать надстройку путем передачи зашифрованного сообщения от Абонента А к Абоненту Б и его приёма и расшифрования на стороне Абонента Б.


ЛИЦЕНЗИЯ
-----------------
LICENSE AND COPYRIGHT

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
