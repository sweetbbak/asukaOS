const port = @import("./port.zig");
const pic = @import("./pic.zig");

// https://wiki.osdev.org/%228042%22_PS/2_Controller
// contains all PS2 definitions for reading and writing to the keyboard controller
const DATA_PORT = 0x60;
const STATUS_PORT = 0x64;
const COMMAND_PORT = 0x64;

const FIFO_SIZE = 256;
var fifo_buffer: [FIFO_SIZE]u8 = undefined;
var fifo_start: usize = 0;
var fifo_end: usize = 0;

pub fn onInterrupt() void {
    const status = port.inb(STATUS_PORT) & 0x01;

    if (status == 0x01) {
        const data = port.inb(DATA_PORT);

        var next = fifo_end + 1;
        if (next == FIFO_SIZE) next = 0; // Wrap around
        if (next == fifo_start) return; // We're out of room

        fifo_buffer[next] = data;
        fifo_end = next;
    }
}

pub fn init() void {
    // Enable keyboard handler in PIC (IRQ 1)
    pic.irq_clear_mask(1);
    // flush the output buffer
    _ = port.inb(DATA_PORT);
}

pub fn getScanCode() u8 {
    if (fifo_start == fifo_end) return 0;

    const value = fifo_buffer[fifo_start];
    fifo_start += 1;
    if (fifo_start == FIFO_SIZE) fifo_start = 0; // Wrap around

    return value;
}
