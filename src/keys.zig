const std = @import("std");
const console = @import("./console.zig");
const ps2 = @import("./ps2.zig");
const scanmap = @import("./keys.zig");
// const acpi = @import("./acpi.zig");
// const pmm = @import("./mem.zig");
// const port = @import("port.zig");
// const utils = @import("utils.zig");

pub const unshiftedMap = [128]u8{
    0,    27,  '1', '2', '3', '4', '5', '6', '7',  '8', '9', '0',  '-',  '=', 8,   '\t',
    'q',  'w', 'e', 'r', 't', 'y', 'u', 'i', 'o',  'p', '[', ']',  '\n', 0,   'a', 's',
    'd',  'f', 'g', 'h', 'j', 'k', 'l', ';', '\'', '`', 0,   '\\', 'z',  'x', 'c', 'v',
    'b',  'n', 'm', ',', '.', '/', 0,   '*', 0,    ' ', 0,   0,    0,    0,   0,   0,
    0,    0,   0,   0,   0,   0,   0,   0,   0,    0,   0,   0,    0,    0,   0,   0,
    '\\', 0,   0,   0,   0,   0,   0,   0,   0,    0,   0,   0,    0,    0,   0,   0,
    0,    0,   0,   0,   0,   0,   0,   0,   0,    0,   0,   0,    0,    0,   0,   0,
    0,    0,   0,   0,   0,   0,   0,   0,   0,    0,   0,   0,    0,    0,   0,   0,
};

pub const shiftedMap = [128]u8{
    0,   27,  '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_',  '+', 8,   '\t',
    'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '{', '}', '\n', 0,   'A', 'S',
    'D', 'F', 'G', 'H', 'J', 'K', 'L', ':', '"', '~', 0,   '|', 'Z',  'X', 'C', 'V',
    'B', 'N', 'M', '<', '>', '?', 0,   '*', 0,   ' ', 0,   0,   0,    0,   0,   0,
    0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,    0,   0,   0,
    '|', 0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,    0,   0,   0,
    0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,    0,   0,   0,
    0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,    0,   0,   0,
};

pub const KeyType = enum { unknown, normal, enter, backspace, shift };
pub const Key = struct { type: KeyType, value: u8 };

const BUFFER_SIZE = 4096;
var buffer: [BUFFER_SIZE]u8 = undefined;

pub fn handleKey() usize {
    var index: usize = 0;

    const scan_code = ps2.getScanCode();
    if (scan_code == 0) {
        return 0;
    }

    const key = getKey(scan_code);
    if (key.type == .unknown) {
        return 0;
    }

    if (key.type == .backspace) {
        if (index > 0) {
            index -= 1;
            buffer[index] = ' ';
            console.backspace();
        }

        return 0;
    }

    if (key.type == .enter) {
        console.newLine();
        return index;
    }

    var isShift: bool = false;
    if (key.type == .shift) {
        isShift = true;
    }

    // debug printf - uncomment "continue" above for .unknown
    if (key.type == .unknown) {
        const buf: []u8 = undefined;
        const out = std.fmt.bufPrint(buf, "{}", .{scan_code}) catch {
            return 0;
        };
        console.write(out);
    }

    if (isShift) {
        console.write("shift");
        const up = std.ascii.toUpper(key.value);
        buffer[index] = up;
        console.putChar(up);
    } else {
        buffer[index] = key.value;
        console.putChar(key.value);
    }

    index += 1;
}

pub fn key_isrelease(scancode: u8) bool {
    return scancode & (1 << 7) != 0;
}

// TODO: this is kinda disgusting
pub fn getKey(scan_code: u8) Key {
    return switch (scan_code) {
        2 => .{ .type = .normal, .value = '1' },
        3 => .{ .type = .normal, .value = '2' },
        4 => .{ .type = .normal, .value = '3' },
        5 => .{ .type = .normal, .value = '4' },
        6 => .{ .type = .normal, .value = '5' },
        7 => .{ .type = .normal, .value = '6' },
        8 => .{ .type = .normal, .value = '7' },
        9 => .{ .type = .normal, .value = '8' },
        10 => .{ .type = .normal, .value = '9' },
        11 => .{ .type = .normal, .value = '0' },
        12 => .{ .type = .normal, .value = '-' },
        13 => .{ .type = .normal, .value = '=' },
        14 => .{ .type = .backspace, .value = 0 },
        16 => .{ .type = .normal, .value = 'q' },
        17 => .{ .type = .normal, .value = 'w' },
        18 => .{ .type = .normal, .value = 'e' },
        19 => .{ .type = .normal, .value = 'r' },
        20 => .{ .type = .normal, .value = 't' },
        21 => .{ .type = .normal, .value = 'y' },
        22 => .{ .type = .normal, .value = 'u' },
        23 => .{ .type = .normal, .value = 'i' },
        24 => .{ .type = .normal, .value = 'o' },
        25 => .{ .type = .normal, .value = 'p' },
        28 => .{ .type = .enter, .value = 0 },
        30 => .{ .type = .normal, .value = 'a' },
        31 => .{ .type = .normal, .value = 's' },
        32 => .{ .type = .normal, .value = 'd' },
        33 => .{ .type = .normal, .value = 'f' },
        34 => .{ .type = .normal, .value = 'g' },
        35 => .{ .type = .normal, .value = 'h' },
        36 => .{ .type = .normal, .value = 'j' },
        37 => .{ .type = .normal, .value = 'k' },
        38 => .{ .type = .normal, .value = 'l' },
        44 => .{ .type = .normal, .value = 'z' },
        45 => .{ .type = .normal, .value = 'x' },
        46 => .{ .type = .normal, .value = 'c' },
        47 => .{ .type = .normal, .value = 'v' },
        48 => .{ .type = .normal, .value = 'b' },
        49 => .{ .type = .normal, .value = 'n' },
        50 => .{ .type = .normal, .value = 'm' },
        57 => .{ .type = .normal, .value = ' ' },
        58 => .{ .type = .normal, .value = ' ' },
        42 => .{ .type = .shift, .value = 0 }, // left shift - shift UP is shift + 0x80
        0x36 => .{ .type = .shift, .value = 0 }, // right shift - shift UP is shift + 0x80
        else => .{ .type = .unknown, .value = 0 },
        // else => .{ .type = .unknown, .value = 0 },
    };
}
