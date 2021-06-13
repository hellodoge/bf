bits 32

%include "vector.inc"

sys_mmap        equ 90
sys_mremap      equ 163
prot_read       equ 1
prot_write      equ 2
map_private     equ 2
map_anonymous   equ 32
mremap_maymove  equ 1
map_failed      equ -1

global NewVector

struc mmap_arg
        .addr           resd 1
        .size           resd 1
        .prot           resd 1
        .flags          resd 1
        .fd             resd 1
        .offset         resd 1
endstruc

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

    cmp     eax, map_failed
    jne     .success

    mov     eax, 0

.success:
    mov     [esi + vector.address], eax
    mov     [esi + vector.size], edi

    mov     esp, ebp
    pop     ebp

    ret

; arguments:
;               esi: pointer to buffer
;               edi: new size
; return value:
;               address on success, 0 on failure

ResizeVector:
    push    esi
    push    edi
    mov     eax, sys_mremap
    mov     ebx, [esi + vector.address]
    mov     ecx, [esi + vector.size]
    mov     edx, edi
    mov     esi, mremap_maymove
    int     0x80
    pop     edi
    pop     esi

    cmp     eax, map_failed
    je      .fail

    mov     [esi + vector.address], eax
    mov     [esi + vector.size], edi
    ret
    
.fail:
    mov     eax, 0
    ret