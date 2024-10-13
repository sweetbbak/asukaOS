//The 8259 Programmable Interrupt Controller (PIC) is one of the most important chips making up the x86 architecture.
//Without it, the x86 architecture would not be an interrupt driven architecture.
//The function of the 8259A is to manage hardware interrupts and send them to the appropriate system interrupt.
//This allows the system to respond to devices needs without loss of time (from polling the device, for instance).
// It is important to note that APIC has replaced the 8259 PIC in more modern systems, especially those with multiple cores/processors.
// https://wiki.osdev.org/8259_PIC
//
// The 8259 PIC controls the CPU's interrupt mechanism, by accepting several interrupt requests and feeding them to the processor in order.
// For instance, when a keyboard registers a keyhit, it sends a pulse along its interrupt line (IRQ 1) to the PIC chip, which then translates
// the IRQ into a system interrupt
// and sends a message to interrupt the CPU from whatever it is doing. Part of the kernel's job is to either handle these IRQs
// and perform the necessary procedures (poll the keyboard for the scancode) or alert a userspace program to the interrupt
// (send a message to the keyboard driver).
// Without a PIC, you would have to poll all the devices in the system to see if they want to do anything (signal an event)
// but with a PIC, your system can run along nicely until such time that a device wants to signal an event
// which means you don't waste time going to the devices, you let the devices come to you when they are ready.
const port = @import("./port.zig");

// PIC = programmable interrupt controller
// IRQ = interrupt request

// IO base address for master (PIC1) and slave (PIC2)
const PIC1 = 0x20;
const PIC2 = 0xA0;

// master PIC
const PIC1_COMMAND = PIC1;
const PIC1_DATA = PIC1 + 1;

// slave PIC
const PIC2_COMMAND = PIC2;
const PIC2_DATA = PIC2 + 1;

// end of interrupt command code
const PIC_EOI = 0x20;

// initialization commands
const ICW1_ICW4 = 0x01;
const ICW1_SINGLE = 0x02;
const ICW1_INTERVAL4 = 0x04;
const ICW1_LEVEL = 0x08;
const ICW1_INIT = 0x10;

// When you enter protected mode (or even before hand, if you're not using GRUB)
// the first command you will need to give the two PICs is the initialise command (code 0x11).
// This command makes the PIC wait for 3 extra "initialisation words" on the data port. These bytes give the PIC:
//  - Its vector offset. (ICW2)
//  - Tell it how it is wired to master/slaves. (ICW3)
//  - Gives additional information about the environment. (ICW4)
const ICW4_8086 = 0x01;
const ICW4_AUTO = 0x02;
const ICW4_BUF_SLAVE = 0x08;
const ICW4_BUF_MASTER = 0x0C;
const ICW4_SFNM = 0x10;

pub fn init() void {
    remap(0x20, 0x20);
}

// Perhaps the most common command issued to the PIC chips is the end of interrupt (EOI) command (code 0x20).
// This is issued to the PIC chips at the end of an IRQ-based interrupt routine. If the IRQ came from the Master PIC,
// it is sufficient to issue this command only to the Master PIC; however if the IRQ came from the Slave PIC,
// it is necessary to issue the command to both PIC chips.
pub fn sendEOI(irq: u8) void {
    if (irq >= 8) {
        port.outb(PIC2_COMMAND, PIC_EOI);
    }

    port.outb(PIC1_COMMAND, PIC_EOI);
}

// arguments:
//  - offset1 - vector offset for master PIC
//      vectors on the master become offset1..offset1+7
//  - offset2 - same for slave PIC: offset2..offset2+7
//
// io_wait gives the PIC sometime to react to commands
pub fn remap(offset1: u8, offset2: u8) void {
    // save masks
    const a = port.inb(PIC1_DATA);
    const b = port.inb(PIC2_DATA);

    port.outb(PIC1_COMMAND, ICW1_INIT | ICW1_ICW4); // start init sequence in cascade mode
    port.io_wait();
    port.outb(PIC2_COMMAND, ICW1_INIT | ICW1_ICW4); // start init sequence in cascade mode
    port.io_wait();
    port.outb(PIC1_DATA, offset1);
    port.io_wait();
    port.outb(PIC2_DATA, offset2);
    port.io_wait();
    port.outb(PIC1_DATA, 4);
    port.io_wait();
    port.outb(PIC2_DATA, 2);
    port.io_wait();

    // restore saved masks
    port.outb(PIC1_DATA, a);
    port.outb(PIC2_DATA, b);
}

// If you are going to use the processor local APIC and the IOAPIC, you must first disable the PIC.
// This is done by masking every single interrupt.
pub fn disable() void {
    port.outb(PIC1_DATA, 0xFF);
    port.outb(PIC2_DATA, 0xFF);
}

// The PIC has an internal register called the IMR, or the Interrupt Mask Register.
// It is 8 bits wide. This register is a bitmap of the request lines going into the PIC.
// When a bit is set, the PIC ignores the request and continues normal operation.
// Note that setting the mask on a higher request line will not affect a lower line.
// Masking IRQ2 will cause the Slave PIC to stop raising IRQs.
// Here is an example of how to mask an IRQ:
pub fn irq_set_mask(irq: u8) void {
    var portq: u16 = 0;
    var intr = irq;

    if (intr < 8) {
        portq = PIC1_DATA;
    } else {
        portq = PIC2_DATA;
        intr -= 8;
    }

    const value = port.inb(portq) | @as(u8, @intCast(@as(u16, 1) << @as(u4, @intCast(intr))));
    port.outb(portq, value);
}

pub fn irq_clear_mask(irq: u8) void {
    var portq: u16 = 0;
    var intr = irq;

    if (intr < 8) {
        portq = PIC1_DATA;
    } else {
        portq = PIC2_DATA;
        intr -= 8;
    }

    const value = port.inb(portq) & ~@as(u8, @intCast(@as(u16, 1) << @as(u4, @intCast(intr))));
    port.outb(portq, value);
}
