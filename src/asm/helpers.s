.global load_gdt
.type load_gdt, @function
.align 4

load_gdt:
    mov 4(%esp), %eax
    lgdt (%eax)
    ljmp $0x08, $jmp_done
jmp_done:
    mov $0x10, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %fs
    mov %ax, %gs
    mov %ax, %ss
    ret

.global load_idt
.type load_idt, @function
.align 4

load_idt:
    mov 4(%esp), %eax
    lidt (%eax)
    ret

.global load_page_directory
.type load_page_directory, @function
.align 4

load_page_directory:
    mov 4(%esp), %eax
    mov %eax, %cr3
    ret

.global enable_paging
.type enable_paging, @function
.align 4

enable_paging:
    mov %cr0, %eax
    or $0x80000000, %eax
    mov %eax, %cr0
    ret

