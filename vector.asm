bits 32

%include "vector.inc"

sys_mmap        equ 90
prot_read       equ 1
prot_write      equ 2
map_private     equ 2
map_anonymous   equ 32

global NewVector

struc mmap_arg
        .addr           resd 1
        .size           resd 1
        .prot           resd 1
        .flags          resd 1
        .fd             resd 1
        .offset         resd 1
endstruc

struc mremap_arg
        .old_addr       resd 1
        .old_size       resd 1
        .new_size       resd 1
        .flags          resd 1
        .new_addr       resd 1
endstruc

; TODO implement ResizeVector

section .text

; arguments:
;               esi: pointer to buffer
;               edi: initial size
; return value:
;               address on success, 0 on failure

NewVector:
    push    ebp
    mov     ebp, esp
    sub     esp, mmap_arg_size

    mov     [ebp - mmap_arg_size + mmap_arg.addr],      dword 0
    mov     [ebp - mmap_arg_size + mmap_arg.size],      edi
    mov     [ebp - mmap_arg_size + mmap_arg.prot],      dword prot_read | prot_write
    mov     [ebp - mmap_arg_size + mmap_arg.flags],     dword map_private | map_anonymous
    mov     [ebp - mmap_arg_size + mmap_arg.fd],        dword -1
    mov     [ebp - mmap_arg_size + mmap_arg.offset],    dword 0
    mov     eax, sys_mmap
    mov     ebx, esp
    int     0x80

    mov     [esi + vector.address], eax
    mov     [esi + vector.size], edi

    mov     esp, ebp
    pop     ebp

    ret
