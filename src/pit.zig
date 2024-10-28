const port = @import("port.zig");
const pic = @import("pic.zig");
// the most rudimentary form of a timer
// TODO: switch to HPET, APIC and IOAPIC

// the base frequency - we can set a divisor from 0-65535
// to modify the frequency
const MAX_FREQ = 1193182;
var TIME_SINCE_BOOT: f64 = 0.0;

// Registers or Channels
const Channel0 = 0x40;
const Channel1 = 0x41;
const Channel2 = 0x42;
const Control = 0x43;

const Mode = enum(u3) {
    Interrupt = 0b000,
    HwOneShot = 0b001,
    RateGen = 0b010,
    SquareWave = 0b011,
    SwStrobe = 0b100,
    HwStrobe = 0b101,
    // RateGen    = 0b110,
    // SquareWave = 0b111
};

const Access = enum(u2) {
    Count = 0,
    ReloadLsb = 1,
    ReloadMsb = 2,
    /// Reload value (first LSB, then MSB)
    Reload = 3,
};

pub fn set_count(count: u16) void {
    // disable interrupts
    asm volatile ("cli");
    // set low byte
    // port.outw(Channel0, (count & 0xFF)); // Low byte
    // port.outb(Channel0, count); // Low byte
    // port.outb(Channel0, count >> 8); // High byte

    port.outb(Channel0, @as(u8, @truncate(count))); // Low byte
    port.outb(Channel0, @as(u8, @truncate((count >> 8)))); // High byte
    asm volatile ("sti");
}

// max is 16bit
pub var DIVISOR: u16 = 65535;

// set the PITs divisor
pub fn set_divisor(div: u16) void {
    var divisor = div;
    if (divisor < 100) divisor = 100;

    // set self.DIVISOR
    DIVISOR = divisor;

    // example: 0xABCD outputs...
    const low_byte: u8 = @truncate(divisor); // 0xCD
    const high_byte: u8 = @truncate(divisor >> 8); // 0xAB
    //
    port.outb(Channel0, low_byte);
    port.io_wait();
    port.outb(Channel0, high_byte);
}

// get the PITs current frequency (u64)
pub fn get_frequency() u64 {
    return MAX_FREQ / @as(u64, DIVISOR);
    // const div: u64 = @intCast(DIVISOR);
    // return (MAX_FREQ / div);
}

// set the PITs frequency
pub fn set_frequency(freq: u64) void {
    // set_divisor(@as(u16, MAX_FREQ / freq));
    // set_divisor(@intCast(MAX_FREQ / freq));
    set_divisor(@truncate(MAX_FREQ / freq));
}

// TODO: why is TIME_SINCE_BOOT and PIT frequency the same?
//
// counting each tick from the PIT on interrupt
pub fn tick() void {
    TIME_SINCE_BOOT += @floatFromInt(get_frequency());
}

pub fn init(freq: u16) void {
    pic.irq_clear_mask(0);
    set_frequency(freq);
}

// counting each tick from the PIT on interrupt
pub fn uptime() f64 {
    return TIME_SINCE_BOOT;
}

// Sleep for specified nanoseconds
pub fn sleep_ns(ns: f64) void {
    const start_time: f64 = TIME_SINCE_BOOT;
    while (TIME_SINCE_BOOT < start_time + ns) {
        asm volatile ("hlt"); // halt
    }
}

// sleep in milliseconds
pub fn sleep_ms(ns: f64) void {
    sleep_ms(ns * 1000);
}

// sleep in seconds
pub fn sleep(sec: f64) void {
    sleep_ns(sec * 10000);
}

// https://wiki.osdev.org/Programmable_Interval_Timer
pub fn read_count() u16 {
    var count: u16 = 0;
    // disable interrupts
    asm volatile ("cli");

    // al = channel in bits 6 and 7, remaining bits clear
    port.outb(Control, 0b0000000);
    // count = port.inb(Channel0); // Low byte
    // count = port.inb(Channel0);
    // count |= @truncate(port.inb(Channel0) << 8); // High byte

    const low: u8 = port.inb(Channel0); // Low byte
    const high: u8 = port.inb(Channel0); // High byte
    //
    asm volatile ("sti");

    count = ((@as(u16, high)) | @as(u16, low));

    // return port.inb(Channel0) | (port.inb(Channel0) << 8);
    // count = port.inb(Channel0);
    // count |= (@truncate(port.inb(Channel0) << 8));
    return count;
    // return count;
}

// Version 3 - Full PIT initialization
pub fn set_count2(count: u16) void {
    asm volatile ("cli");
    defer asm volatile ("sti");

    // Common initialization for channel 0, mode 3
    const command: u8 = (0 << 6) // Channel 0
    | (3 << 4) // Access mode: lobyte/hibyte
    | (3 << 1) // Mode 3 (square wave)
    | (0 << 0); // 16-bit binary

    port.outb(0x43, command); // Command port

    // LSB then MSB
    port.outb(0x40, @as(u8, @truncate(count)));
    port.outb(0x40, @as(u8, @truncate(count >> 8)));
}

// configures the chan0 with a rate generator, which will trigger irq0
pub const divisor1 = 2685;
// pub const tick = 2251; // f = 1.193182 MHz, TODO: turn into a function

pub fn configPIT() void {
    const chanNum = 0;
    // const chan = PIT_CHAN0;
    const LOHI = 0b11; // bit4 | bit5
    const PITMODE_RATE_GEN = 0x2;

    port.outb(Control, chanNum << 6 | LOHI << 4 | PITMODE_RATE_GEN << 1);
    port.outb(Channel0, divisor1 & 0xff);
    port.outb(Channel0, divisor1 >> 8);
}

pub fn init2(freq: u32) void {
    // const reloadVal: u16 = @truncate(@divTrunc(MAX_FREQ + @divTrunc(freq, 2), freq));
    const div: u32 = MAX_FREQ / freq;
    port.outb(Control, (div & 0xFF));
    port.outb(Channel0, @truncate(div));
    port.outb(Channel0, @truncate(div >> 8));
}

pub fn init_freq(freq: u32) void {
    const reloadVal: u16 = @truncate(@divTrunc(MAX_FREQ + @divTrunc(freq, 2), freq));
    port.outb(Control, .{ .counter = 0, .access = .Reload, .mode = .SquareWave });

    port.outb(Channel0, @truncate(reloadVal));
    port.outb(Channel0, @truncate(reloadVal >> 8));
}

// ----------------
const PitFrequency = 1193182; // PIT's base frequency in Hz

// Initialize PIT in one-shot mode for sleep
pub fn init_pit_one_shot() void {
    const command: u8 = (0 << 6) // Channel 0
    | (3 << 4) // Access mode: lobyte/hibyte
    | (0 << 1); // Mode 0 (interrupt on terminal count)
    // One-shot mode is better for sleep

    asm volatile ("cli");
    port.outb(Control, command);
    asm volatile ("sti");
}

// Convert milliseconds to PIT ticks
pub fn ms_to_ticks(ms: u32) u16 {
    const ticks = (ms * PitFrequency) / 1000;
    return @truncate(if (ticks > 65535) 65535 else ticks);
}

// Sleep for specified milliseconds
pub fn sleep_old(ms: u32) void {
    const ticks = ms_to_ticks(ms);

    asm volatile ("cli");
    // Load count
    port.outb(Channel0, @as(u8, @truncate(ticks)));
    port.outb(Channel0, @as(u8, @truncate(ticks >> 8)));
    asm volatile ("sti");

    // Wait for the count to finish
    while (true) {
        port.outb(Control, 0xE2); // Latch count value for channel 0
        const status = port.inb(Channel0);
        if ((status & 0x80) != 0) { // Check if we've reached terminal count
            break;
        }
        asm volatile ("pause"); // Don't burn CPU while waiting
    }
}
