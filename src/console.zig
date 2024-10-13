const fmt = @import("std").fmt;
const port = @import("./port.zig");

const VGA_WIDTH = 80;
const VGA_HEIGHT = 25;
const VGA_SIZE = VGA_WIDTH * VGA_HEIGHT;

// console colors
pub const Colors = enum(u8) {
    Black = 0,
    Blue = 1,
    Green = 2,
    Cyan = 3,
    Red = 4,
    Magenta = 5,
    Brown = 6,
    LightGray = 7,
    DarkGray = 8,
    LightBlue = 9,
    LightGreen = 10,
    LightCyan = 11,
    LightRed = 12,
    LightMagenta = 13,
    LightBrown = 14,
    White = 15,
};

var row: usize = 0;
var column: usize = 0;

// default console colors
var color = vgaEntryColor(Colors.LightGray, Colors.Black);

// init screen buffer, many item pointer (volatile means it will change, tell compiler not to cache) 0xB8000 is the VGA buffer location
// in the BIOS (as far as I know)
var buffer = @as([*]volatile u16, @ptrFromInt(0xB8000));

fn vgaEntryColor(fg: Colors, bg: Colors) u8 {
    return @intFromEnum(fg) | (@intFromEnum(bg) << 4);
}

fn vgaEntry(uc: u8, new_color: u8) u16 {
    const c: u16 = new_color;

    return uc | (c << 8);
}

pub fn initialize() void {
    clear();
}

pub fn setColor(new_color: u8) void {
    color = new_color;
}

pub fn setColor2(new_color: Colors) void {
    color = @intFromEnum(new_color);
}

pub fn clear() void {
    // clear the screen buffer with the set colors
    @memset(buffer[0..VGA_SIZE], vgaEntry(' ', color));

    // set cursor to home position
    setCursor(0, 0);

    // reset position
    column = 0;
    row = 0;
}

// pub fn clear(self: *VGA) void {
//     std.mem.set(VGAEntry, self.vram[0..VGA_SIZE], self.entry(' '));
//
//     self.cursor = 80; // skip 1 line for topbar
//     self.updateCursor();
// }

pub fn putCharAt(c: u8, new_color: u8, x: usize, y: usize) void {
    const index = y * VGA_WIDTH + x;
    buffer[index] = vgaEntry(c, new_color);
}

pub fn putChar_old(c: u8) void {
    putCharAt(c, color, column, row);
    column += 1;
    if (column == VGA_WIDTH) {
        column = 0;
        row += 1;
        if (row == VGA_HEIGHT)
            row = 0;
    }
}

pub fn putChar(c: u8) void {
    if (row == VGA_HEIGHT - 1) {
        scrollUp();
        row -= 1;
    }

    // handle control sequences
    switch (c) {
        '\n' => {
            column = 0;
            row += 1;
        },
        '\r' => {
            column = 0;
        },
        '\t' => {
            column += 4;
        },
        else => {
            putCharAt(c, color, column, row);
            column += 1;
            setCursor(column, row);
        },
    }

    // wrap back around when we reach the right side
    if (column >= VGA_WIDTH) {
        column = 0;
        row += 1;

        if (row >= VGA_HEIGHT) row = 0;
    }
}

pub fn puts(data: []const u8) void {
    for (data) |c|
        putChar(c);
}

pub fn write(data: []const u8) void {
    for (data) |c| putChar(c);
}

pub fn writeln(data: []const u8) void {
    for (data) |c| putChar(c);
    newLine();

    // if (row == VGA_HEIGHT)
    //     row = 0;
}

pub fn newLine() void {
    column = 0;
    row += 1;
}

pub fn backspace() void {
    column -= 1;
    putCharAt(' ', color, column, row);
    setCursor(column, row);
}

pub fn enableCursor() void {
    // start pos
    port.outb(0x3D4, 0x0A);
    port.outb(0x3D5, (port.inb(0x3D5) & 0xC0) | 0); // 0 for the cursor_start position

    // end pos
    port.outb(0x3D4, 0x0B);
    port.outb(0x3D5, (port.inb(0x3D5) & 0xE0) | VGA_HEIGHT); // 0 for the cursor_start position
}

pub fn disableCursor() void {
    port.outb(0x3D4, 0x0A);
    port.outb(0x3D5, 0x20);
}

pub fn setCursor(x: usize, y: usize) void {
    const position = y * VGA_WIDTH + x;

    port.outb(0x3D4, 0x0F);
    port.outb(0x3D5, @as(u8, @intCast(position & 0xFF)));

    port.outb(0x3D4, 0x0E);
    port.outb(0x3D5, @as(u8, @intCast((position >> 8) & 0xFF)));
}

pub fn scrollUp() void {
    for (1..VGA_HEIGHT) |y| {
        for (0..row) |x| {
            buffer[(y - 1) * VGA_WIDTH + x] = buffer[y * VGA_WIDTH + x];
        }
    }
}
