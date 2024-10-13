pub const KeyType = enum { unknown, normal, enter, backspace };
pub const Key = struct { type: KeyType, value: u8 };

pub fn getKey(scan_code: u8) Key {
    return switch (scan_code) {
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
        else => .{ .type = .unknown, .value = 0 },
    };
}
