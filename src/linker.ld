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

/* the name of the entry label */
ENTRY(_start)
 
SECTIONS {
    . = 1M; /* the code should be loaded at 1MB (bios, bootloader, mmap IO lives in the first 1MB) */

    .text : ALIGN(8K) { /* align at 8KB */
        *(.multiboot)
        *(.text) /* all text sections from all files */
    }
 
    .rodata : ALIGN(8K) {
        *(.rodata) /* all read-only data sections */
    }
 
    .data : ALIGN(8K) {
        *(.data) /* all data sections */
    }
 
    .bss : ALIGN(8K) {
        *(COMMON) /* all COMMON sections */
        *(.bss) /* all bss sections */
    }
}
