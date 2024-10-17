// idk about this file, I just needed somewhere to put 'sleep' lol
const std = @import("std");
const pit = @import("pit.zig");

pub fn sleep(ms: u32) void {
    for (0..ms) |value| {
        _ = value;
        pit.set_count(1193182 / 1000);
        const start = pit.read_count();

        while ((start - pit.read_count()) < 1000) {}
    }
}
