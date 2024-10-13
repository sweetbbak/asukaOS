const std = @import("std");
const pmm = @import("mem.zig");

const GDT_ENTRIES = 3;

const gdt_entry = packed struct {
    limit_low: u16,
    base_low: u16,
    base_middle: u8,
    access: u8,
    granularity: u8,
    base_high: u8,
};
const gdtr = packed struct { size: u16, offset: u32 };

extern fn load_gdt(gdt: usize) void;

fn create_entry(address: u32, limit: u32, access: u8, granularity: u8) gdt_entry {
    return gdt_entry{
        .base_low = @as(u16, @intCast(address & 0xFFFF)),
        .base_middle = @as(u8, @intCast((address >> 16) & 0xFF)),
        .base_high = @as(u8, @intCast((address >> 24) & 0xFF)),
        .limit_low = @as(u16, @intCast(limit & 0xFFFF)),
        .granularity = @as(u8, @intCast(@as(u8, @intCast((limit >> 16) & 0x0F)) | (granularity & 0xF0))),
        .access = access,
    };
}

pub fn init() void {
    // Initialize buffer and add all segments
    const gdt_entries_size = @sizeOf(gdt_entry) * GDT_ENTRIES;

    const gdt_entries_address = pmm.allocate(gdt_entries_size);
    const gdt_entries = @as([*]gdt_entry, @ptrFromInt(gdt_entries_address));

    gdt_entries[0] = create_entry(0, 0, 0, 0); // Null segment
    gdt_entries[1] = create_entry(0, 0xFFFFFFFF, 0x9A, 0xCF); // Code segment
    gdt_entries[2] = create_entry(0, 0xFFFFFFFF, 0x92, 0xCF); // Data segment

    // Load GDT
    const gdt_address = pmm.allocate(@sizeOf(gdtr));
    const gdt = @as(*gdtr, @ptrFromInt(gdt_address));

    gdt.size = gdt_entries_size - 1;
    gdt.offset = @as(u32, gdt_entries_address);

    load_gdt(@as(u32, gdt_address));
}
