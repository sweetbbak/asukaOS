// const InputKey = @import("scanmap.zig").InputKey;
// const ft = @import("../../ft/ft.zig");
// const keymaps = @import("keymap_index.zig");
// const keyboard = @import("../keyboard.zig");

// var current_map: *const [232][6]u16 = &keymaps.@"us-std";

pub const MAP_COLS: u8 = 6;
// pub const NB_SCANCODES: u8 = @typeInfo(InputKey).Enum.fields.len;

pub const EXT: u16 = 0x0100;
pub const CTRLKEY: u16 = 0x0200;
pub const SHIFT: u16 = 0x0400;
pub const ALT: u16 = 0x0800;
pub const HASNUM: u16 = 0x4000;
pub const HASCAPS: u16 = 0x8000;

pub const escape_map: [12][]const u8 = [_][]const u8{
    "\x1b[H",
    "\x1b[Y",
    "\x1b[A",
    "\x1b[B",
    "\x1b[D",
    "\x1b[C",
    "\x1bD",
    "\x1bM",
    "\x1b[G",
    "\x1b[S",
    "\x1b[T",
    "\x1b[@",
};

/// Map to control code
pub inline fn C(comptime scancode: u16) u16 {
    return scancode & 0x1F;
}

/// Set eight bit (ALT)
pub inline fn A(comptime scancode: u16) u16 {
    return scancode | 0x80;
}

/// Control + Alt
pub inline fn CA(comptime scancode: u16) u16 {
    return A(C(scancode));
}

/// Add "Num lock has effect" attribute
pub inline fn N(comptime scancode: u16) u16 {
    return scancode | HASNUM;
}

/// Add "Caps lock has effect" attribute
pub inline fn L(comptime scancode: u16) u16 {
    return scancode | HASCAPS;
}

/// set the keymap to use
// pub fn set_keymap(name: []const u8) error{KeymapNotFound}!void {
//     inline for (@typeInfo(keymaps).Struct.decls) |decl| {
//         if (ft.mem.eql(u8, decl.name, name)) {
//             current_map = &@field(keymaps, decl.name);
//             return;
//         }
//     }
//     return error.KeymapNotFound;
// }

// fn get_keymap_list() [@typeInfo(keymaps).Struct.decls.len][]const u8 {
//     comptime {
//         var ret: [@typeInfo(keymaps).Struct.decls.len][]const u8 = undefined;
//         for (@typeInfo(keymaps).Struct.decls, 0..) |decl, i| {
//             ret[i] = decl.name;
//         }
//         return ret;
//     }
// }

/// list of all the existing keymaps
// pub const keymap_list = get_keymap_list();

// pub fn map_key(index: u16) u16 {
//     var caps: bool = false;
//     var col: u8 = 0;
//     const row: [6]u16 = current_map[index];
//
//     if (row[0] & HASNUM != 0) {
//         if (keyboard.locks.num_lock) caps = true;
//     } else {
//         caps = keyboard.keyState.shift;
//         if ((keyboard.locks.caps_lock) and (row[0] & HASCAPS) != 0)
//             caps = !caps;
//     }
//
//     if (keyboard.keyState.alt) {
//         col = 2;
//         if (keyboard.keyState.ctrl or keyboard.keyState.alt_right) col = 3;
//         if (caps) col = 4;
//     } else {
//         col = 0;
//         if (caps) col = 1;
//         if (keyboard.keyState.ctrl) col = 5;
//     }
//
//     return row[col] & ~(HASCAPS | HASNUM);
// }

// Lock Keys
pub const CALOCK = 0x0D + EXT;
pub const NLOCK = 0x0E + EXT;
pub const SLOCK = 0x0F + EXT;

// Function Keys
pub const F1 = 0x10 + EXT;
pub const F2 = 0x11 + EXT;
pub const F3 = 0x12 + EXT;
pub const F4 = 0x13 + EXT;
pub const F5 = 0x14 + EXT;
pub const F6 = 0x15 + EXT;
pub const F7 = 0x16 + EXT;
pub const F8 = 0x17 + EXT;
pub const F9 = 0x18 + EXT;
pub const F10 = 0x19 + EXT;
pub const F11 = 0x1A + EXT;
pub const F12 = 0x1B + EXT;

pub const DEL = 0x7f;

// Alt + Numeric keypad
pub const AHOME = 0x01 + ALT;
pub const AEND = 0x02 + ALT;
pub const AUP = 0x03 + ALT;
pub const ADOWN = 0x04 + ALT;
pub const ALEFT = 0x05 + ALT;
pub const ARIGHT = 0x06 + ALT;
pub const APGUP = 0x07 + ALT;
pub const APGDN = 0x08 + ALT;
pub const AMID = 0x09 + ALT;
pub const AMIN = 0x0A + ALT;
pub const APLUS = 0x0B + ALT;
pub const AINSRT = 0x0C + ALT;

// Shift+Fn
pub const SF1 = 0x10 + SHIFT;
pub const SF2 = 0x11 + SHIFT;
pub const SF3 = 0x12 + SHIFT;
pub const SF4 = 0x13 + SHIFT;
pub const SF5 = 0x14 + SHIFT;
pub const SF6 = 0x15 + SHIFT;
pub const SF7 = 0x16 + SHIFT;
pub const SF8 = 0x17 + SHIFT;
pub const SF9 = 0x18 + SHIFT;
pub const SF10 = 0x19 + SHIFT;
pub const SF11 = 0x1A + SHIFT;
pub const SF12 = 0x1B + SHIFT;

// Alt + Fn
pub const AF1 = 0x10 + ALT;
pub const AF2 = 0x11 + ALT;
pub const AF3 = 0x12 + ALT;
pub const AF4 = 0x13 + ALT;
pub const AF5 = 0x14 + ALT;
pub const AF6 = 0x15 + ALT;
pub const AF7 = 0x16 + ALT;
pub const AF8 = 0x17 + ALT;
pub const AF9 = 0x18 + ALT;
pub const AF10 = 0x19 + ALT;
pub const AF11 = 0x1A + ALT;
pub const AF12 = 0x1B + ALT;

// Alt + Shift + Fn
pub const ASF1 = 0x10 + ALT + SHIFT;
pub const ASF2 = 0x11 + ALT + SHIFT;
pub const ASF3 = 0x12 + ALT + SHIFT;
pub const ASF4 = 0x13 + ALT + SHIFT;
pub const ASF5 = 0x14 + ALT + SHIFT;
pub const ASF6 = 0x15 + ALT + SHIFT;
pub const ASF7 = 0x16 + ALT + SHIFT;
pub const ASF8 = 0x17 + ALT + SHIFT;
pub const ASF9 = 0x18 + ALT + SHIFT;
pub const ASF10 = 0x19 + ALT + SHIFT;
pub const ASF11 = 0x1A + ALT + SHIFT;
pub const ASF12 = 0x1B + ALT + SHIFT;

// Ctrl + Fn
pub const CF1 = 0x10 + CTRLKEY;
pub const CF2 = 0x11 + CTRLKEY;
pub const CF3 = 0x12 + CTRLKEY;
pub const CF4 = 0x13 + CTRLKEY;
pub const CF5 = 0x14 + CTRLKEY;
pub const CF6 = 0x15 + CTRLKEY;
pub const CF7 = 0x16 + CTRLKEY;
pub const CF8 = 0x17 + CTRLKEY;
pub const CF9 = 0x18 + CTRLKEY;
pub const CF10 = 0x19 + CTRLKEY;
pub const CF11 = 0x1A + CTRLKEY;
pub const CF12 = 0x1B + CTRLKEY;

// Numeric keypad
pub const HOME = 0x01 + EXT;
pub const END = 0x02 + EXT;
pub const UP = 0x03 + EXT;
pub const DOWN = 0x04 + EXT;
pub const LEFT = 0x05 + EXT;
pub const RIGHT = 0x06 + EXT;
pub const PGUP = 0x07 + EXT;
pub const PGDN = 0x08 + EXT;
pub const MID = 0x09 + EXT;
pub const INSRT = 0x0C + EXT;

// Ctrl + Numeric keypad
pub const CHOME = 0x01 + CTRLKEY;
pub const CEND = 0x02 + CTRLKEY;
pub const CUP = 0x03 + CTRLKEY;
pub const CDOWN = 0x04 + CTRLKEY;
pub const CLEFT = 0x05 + CTRLKEY;
pub const CRIGHT = 0x06 + CTRLKEY;
pub const CPGUP = 0x07 + CTRLKEY;
pub const CPGDN = 0x08 + CTRLKEY;
pub const CMID = 0x09 + CTRLKEY;
pub const CNMIN = 0x0A + CTRLKEY;
pub const CPLUS = 0x0B + CTRLKEY;
pub const CINSRT = 0x0C + CTRLKEY;

// Keys affected by Num Lock
pub const NHOME = N(HOME);
pub const NEND = N(END);
pub const NUP = N(UP);
pub const NDOWN = N(DOWN);
pub const NLEFT = N(LEFT);
pub const NRIGHT = N(RIGHT);
pub const NPGUP = N(PGUP);
pub const NPGDN = N(PGDN);
pub const NMID = N(MID);
pub const NINSRT = N(INSRT);
pub const NDEL = N(DEL);

// The left and right versions for the actual keys in the keymap.
pub const LCTRL = CTRLKEY;
pub const RCTRL = (CTRLKEY | EXT);
pub const LSHIFT = SHIFT;
pub const RSHIFT = (SHIFT | EXT);
pub const LALT = ALT;
pub const RALT = (ALT | EXT);
