## Brainfuck interpreter
I wanted to implement a growable buffer in an assembly language, ended up writing a simple project using it.

### Usage:
```
./bf <source code file>
```

### Note
As an interpreter, it is not designed to be fast.\
If you want to write a high-performance brainfuck interpreter:

1. Reduce the number of system calls passing your file descriptor to `mmap`.
2. Bufferize your output writing at once as many bytes as possible.
3. Implement [optimizations](https://en.wikipedia.org/wiki/Peephole_optimization) of loops ([example](https://github.com/hellodoge/bfcompiler)).
