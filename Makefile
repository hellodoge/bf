all: bf

main.o: main.asm
	nasm -f elf main.asm -o main.o

vector.o: vector.asm vector.inc
	nasm -f elf vector.asm -o vector.o

interpreter.o: interpreter.asm vector.inc
	nasm -f elf interpreter.asm -o interpreter.o

bf: main.o vector.o interpreter.o
	ld -m elf_i386 $^ -o bf

clean:
	rm vector.o main.o interpreter.o bf
