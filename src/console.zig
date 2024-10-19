const std = @import("std");
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
var color = vgaEntryColor(Colors.Green, Colors.Black);

// init screen buffer, many item pointer (volatile means it will change, tell compiler not to cache) 0xB8000 is the VGA buffer location
// in the BIOS (as far as I know)
var buffer = @as([*]volatile u16, @ptrFromInt(0xB8000));
// var buffer = @as([*]volatile u16, @ptrFromInt(0xA0000)); // framebuffer

// color is an 8bit int with the first 4 bytes being the fg and last 4 bytes being the bg
// BBBBFFFF
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

// get the fg and bg color
pub fn get_colors() u8 {
    return color;
}

// set the fg and bg
pub fn set_colors(fg: Colors, bg: Colors) void {
    color = @intFromEnum(fg) | (@intFromEnum(bg) << 4);
}

// set the fg and bg
pub fn set_bg(bg: u8) void {
    // clear the first 4 bits (bg) shift the new bg over 4 bits and bitwise or them
    color = (bg << 4) | (color & 0x0F);
}

// set the fg and bg
pub fn set_fg(fg: u8) void {
    // clear the last 4 bits (fg) and bitwise or them
    color = fg | (color & 0xF0);
}

// set the fg and bg
pub fn set_bgc(bg: Colors) void {
    // clear the first 4 bits (bg) shift the new bg over 4 bits and bitwise or them
    color = (@intFromEnum(bg) << 4) | (color & 0x0F);
}

// set the fg and bg
pub fn set_fgc(fg: Colors) void {
    // clear the last 4 bits (fg) and bitwise or them
    color = @intFromEnum(fg) | (color & 0xF0);
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

pub fn putCharAt(c: u8, new_color: u8, x: usize, y: usize) void {
    const index = y * VGA_WIDTH + x;
    buffer[index] = vgaEntry(c, new_color);
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

// write the given bytes to output - alias for write
pub fn puts(data: []const u8) void {
    for (data) |c| putChar(c);
}

// write the given bytes to output
pub fn write(data: []const u8) void {
    for (data) |c| putChar(c);
}

// same as write and puts but adds a newline to the given string
pub fn writeln(data: []const u8) void {
    for (data) |c| putChar(c);
    newLine();
}

// standard printf function
pub fn printf(comptime format: []const u8, args: anytype) void {
    console_writer.print(format, args) catch {};
}

pub fn print_err(comptime format: []const u8, args: anytype) void {
    printf("[ERR] " ++ format ++ "\n", args);
}

pub fn print_ok(comptime format: []const u8, args: anytype) void {
    printf("[OK] " ++ format ++ "\n", args);
}

const console_writer = Console.writer();

// TODO: check for errors with the port inbound and outbound and handle them
pub const Console = struct {
    pub fn println(comptime format: []const u8, args: anytype) void {
        print(format ++ "\n", args);
    }

    pub fn print(comptime format: []const u8, args: anytype) void {
        if (@import("builtin").is_test) {
            @import("std").debug.print(format, args);
            return;
        }

        writer.print(format, args) catch {};
    }

    pub fn write(data: []const u8) void {
        for (data) |c| putChar(c);
    }

    pub fn write_array(values: []const u8) usize {
        var written: usize = 0;
        for (values) |value| {
            written += 1;
            putChar(value);
        }

        return written;
    }

    pub fn writeWithContext(self: Console, values: []const u8) WriteError!usize {
        _ = self;
        return write_array(values);
    }

    const WriteError = error{CannotWrite};
    const SerialWriter = std.io.Writer(Console, WriteError, writeWithContext);

    pub fn writer() SerialWriter {
        return .{ .context = Console{} };
    }
};

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
        for (0..VGA_WIDTH) |x| {
            buffer[(y - 1) * VGA_WIDTH + x] = buffer[y * VGA_WIDTH + x];
        }
    }
}
