bits 32

sys_exit    equ 1
sys_write   equ 4
sys_open    equ 5
sys_close   equ 6
stdout      equ 1
read_only   equ 0

extern RunInterpreter

global _start


section .text

_start:
    pop     ecx                 ; number of command line arguments
    cmp     ecx, 2              ; requires only one argument
    jne     PrintUsageMessage

    mov     eax, sys_open
    add     esp, 4              ; skip executable path argument
    pop     ebx                 ; first argument (brainfuck source code)
    mov     ecx, read_only
    int     0x80

    test    eax, eax            ; all errors currently processed the same
    js      InvalidFilename

    push    eax                 ; push file descriptor
    call    RunInterpreter

    pop     ebx                 ; file descriptor
    push    eax                 ; RunInterpreter saves return code in eax
    mov     eax, sys_close
    int     0x80 

    pop     ebx                 ; return code given by RunInterpreter
    mov     eax, sys_exit
    int     0x80


InvalidFilename:

    section .data
        .error_msg      db      "error: file does not exist", 10
        .error_msg_len  equ     $ - .error_msg

    section .text
        mov     eax, sys_write
        mov     ebx, stdout
        mov     ecx, .error_msg
        mov     edx, .error_msg_len
        int     0x80

        mov     eax, sys_exit
        mov     ebx, -1
        int     0x80


PrintUsageMessage: 

    section .data
                                ; TODO: pop program name
        .help_msg       db      "usage: bf <source code>", 10
        .help_msg_len   equ     $ - .help_msg

    section .text
        mov     eax, sys_write
        mov     ebx, stdout
        mov     ecx, .help_msg
        mov     edx, .help_msg_len
        int     0x80

        mov     eax, sys_exit
        mov     ebx, 0
        int     0x80
