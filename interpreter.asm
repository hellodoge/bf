bits 32

%include "vector.inc"

extern  NewVector
extern  DeleteVector

sys_read    equ 3
sys_write   equ 4
stdin       equ 0
stdout      equ 1
buf_size    equ 4096
mem_size    equ 30000

global  RunInterpreter


section .bss
    current         resb 1
    loop_buffer     resb vector_size
    mem             resb mem_size
    fd              resd 1


section .text

; arguments:
;               eax: file descriptor
; return value:
;               eax: value of pointed bf cell

RunInterpreter:
    push    ebp
    mov     ebp, esp

    mov     [fd], eax

    mov     edi, buf_size
    mov     esi, loop_buffer
    call    NewVector           ; allocate space for loops bufferization

    mov     edi, mem            ; memory pointer
    mov     esi, eax            ; buffer writing cursor
    mov     ebx, esi            ; buffer reading cursor
    xor     edx, edx            ; loops counter

.GetNextOperation:
    call    ReadByte

.OperationSwitch:

    cmp     al, '+'
    je      .OperationIncrement

    cmp     al, '-'
    je      .OperationDecrement

    cmp     al, '>'
    je      .OperationNextCell

    cmp     al, '<'
    je      .OperationPreviousCell

    cmp     al, '['
    je      .OperationLoopInit

    cmp     al, ']'
    je      .OperationLoopRepeat
    
    cmp     al, '.'
    je      .OperationOutput

    cmp     al, ','
    je      .OperationInput

    jmp     .GetNextOperation

.OperationIncrement:
    inc     byte [edi]
    jmp     .BufferizeOperation

.OperationDecrement:
    dec     byte [edi]
    jmp     .BufferizeOperation

.OperationNextCell:
    inc     edi
    jmp     .BufferizeOperation

.OperationPreviousCell:
    dec     edi
    jmp     .BufferizeOperation

.OperationLoopInit:
    inc     edx
    cmp     [edi], byte 0
    jnz     .EnterLoop
    call    SkipLoop
    jmp     .GetNextOperation
.EnterLoop:
    cmp     edx, 1                  ; if this loop isn't nested, then reset buffer
    jnz     .ContinueWritingInExistingBuffer
    mov     esi, [loop_buffer + vector.address]
    mov     ebx, esi
.ContinueWritingInExistingBuffer:
    push    ebx                     ; save position of next operation in buffer
    inc     dword [esp]
    jmp     .BufferizeOperation

.OperationLoopRepeat:
    call    BufferizeOperationInBuffer
    cmp     [edi], byte 0
    jnz     .RepeatLoop
    add     esp, 4                  ; remove pointer to first operation of current loop
    dec     edx
    jmp     .GetNextOperation
.RepeatLoop:
    mov     ebx, [esp]
    jmp     .GetNextOperation

.OperationOutput:
    push    ebx
    push    edx
    mov     eax, sys_write
    mov     ebx, stdout
    mov     ecx, edi
    mov     edx, 1
    int     0x80
    pop     edx
    pop     ebx
    mov     al, '.'
    jmp     .BufferizeOperation

.OperationInput:
    push    ebx
    push    edx
    mov     eax, sys_read
    mov     ebx, stdin
    mov     ecx, edi
    mov     edx, 1
    int     0x80
    pop     edx
    pop     ebx
    mov     al, ','
    jmp     .BufferizeOperation

.BufferizeOperation:
    cmp     edx, 0                  ; do not bufferize if the byte outside of a loop
    je      .GetNextOperation

    call    BufferizeOperationInBuffer
    jmp     .GetNextOperation

Eof:
    mov     esp, ebp
    pop     ebp

    mov     esi, loop_buffer
    call    DeleteVector

    mov     al, [edi]
    ret

ReadByte:
    cmp     ebx, esi
    jl      .ReadBuffer

.ReadFile:
    push    edx
    mov     eax, sys_read
    mov     ebx, [fd]
    mov     ecx, current
    mov     edx, 1
    int     0x80
    pop     edx

    test    eax, eax
    jz      Eof                 ; Eof will restore stack pointer

    mov     ebx, esi
    mov     al, [current]
    ret

.ReadBuffer:
    mov     al, [ebx]
    inc     ebx
    ret


BufferizeOperationInBuffer:
    cmp     ebx, esi            ; ret if the byte is from buffer
    jl      .Ret                ; does x86 have conditional ret?

    mov     [esi], al
    inc     esi
    inc     ebx
.Ret:
    ret


SkipLoop:
    mov     ecx, edx            ; current level of nesting 
    jmp     .OperationSwitch    ; current byte should be processed too

.Loop:
    cmp     ecx, edx            ; if we reached end of the loop then return
    jl      .Ret

.ReadNextByte:
    push    ecx
    push    edx
    call    ReadByte
    pop     edx
    pop     ecx

.OperationSwitch:
    cmp     al, '+'
    je      .BufferizeOperation

    cmp     al, '-'
    je      .BufferizeOperation

    cmp     al, '>'
    je      .BufferizeOperation

    cmp     al, '<'
    je      .BufferizeOperation

    cmp     al, '['
    je      .Opening

    cmp     al, ']'
    je      .Closing
    
    cmp     al, '.'
    je      .BufferizeOperation

    cmp     al, ','
    je      .BufferizeOperation

    jmp     .Loop

.Opening:
    inc     ecx
    jmp     .BufferizeOperation

.Closing:
    dec     ecx
    jmp     .BufferizeOperation

.BufferizeOperation:
    cmp     edx, 1              ; do not bufferize skipped loops if it not nested
    je      .Loop

    call    BufferizeOperationInBuffer

.Ret:
    dec     edx                 ; we're out of skipped loop
    ret

