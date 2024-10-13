/* ENTRY(_start) */
/*   */
/* SECTIONS { */
/*     . = 2M; */
/**/
/*     .text : ALIGN(4K) { */
/*         *(.multiboot) */
/*         *(.text) */
/*     } */
/*   */
/*     .rodata : ALIGN(4K) { */
/*         *(.rodata) */
/*     } */
/*   */
/*     .data : ALIGN(4K) { */
/*         *(.data) */
/*     } */
/*   */
/*     .bss : ALIGN(4K) { */
/*         *(COMMON) */
/*         *(.bss) */
/*     } */
/* } */

ENTRY(_start)
 
SECTIONS {
    . = 1M;

    .text : ALIGN(8K) {
        *(.multiboot)
        *(.text)
    }
 
    .rodata : ALIGN(8K) {
        *(.rodata)
    }
 
    .data : ALIGN(8K) {
        *(.data)
    }
 
    .bss : ALIGN(8K) {
        *(COMMON)
        *(.bss)
    }
}
