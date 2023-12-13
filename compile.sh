gcc test.c -o test

gcc main.c -c -g
as stdio.asm -o stdio.o -g
gcc main.o stdio.o -z noexecstack -o main