const acpi = @import("./acpi.zig");
const vga = @import("./console.zig");

const MultibootHeaderTag = extern struct {
    type: u16 align(1),
    flags: u16 align(1),
    size: u32 align(1),
};

const Multiboot = extern struct {
    magic: u32 align(8),
    architecture: u32 align(1),
    header_length: u32 align(1),
    checksum: u32 align(1),
    end_tag: MultibootHeaderTag align(8),
};

const MAGIC = 0xE85250D6;
const ARCHITECTURE = 0; // i386 (protected mode)
const HEADER_LENGTH = @sizeOf(Multiboot);

export const multiboot align(8) linksection(".multiboot") = Multiboot{
    .magic = MAGIC,
    .architecture = ARCHITECTURE,
    .header_length = HEADER_LENGTH,
    .checksum = 0x100000000 - (MAGIC + ARCHITECTURE + HEADER_LENGTH),
    .end_tag = .{ .type = 0, .flags = 0, .size = @sizeOf(MultibootHeaderTag) },
};

pub const MultibootTag = extern struct {
    type: u32 align(8),
    size: u32 align(1),
};

const TAG_SIZE = @sizeOf(MultibootTag);

pub const MultibootMemoryMapEntry = extern struct {
    address: u64 align(1),
    length: u64 align(1),
    type: u32 align(1),
    reserved: u32 align(1),
};

pub var commandLine: [*]u8 = undefined;
pub var bootloaderName: [*]u8 = undefined;
pub var memoryLower: u32 = undefined;
pub var memoryUpper: u32 = undefined;
pub var entrySize: u32 = undefined;
pub var entryVersion: u32 = undefined;
pub var entries: [*]MultibootMemoryMapEntry = undefined;
pub var entryCount: u32 = undefined;
pub var acpiVersion2: bool = undefined;
pub var acpiOldRsdp: acpi.rsdp = undefined;
pub var acpiNewRsdp: acpi.rsdp_20 = undefined;

pub fn init(multiboot_info_address: usize) void {
    var entry_address = multiboot_info_address + 8;

    while (true) {
        const entry: *MultibootTag = @ptrFromInt(entry_address);
        if (entry.type == 0) break;

        switch (entry.type) {
            1 => commandLine = @ptrFromInt(entry_address + TAG_SIZE),
            2 => bootloaderName = @ptrFromInt(entry_address + TAG_SIZE),
            4 => {
                const basic_memory: [*]u32 = @ptrFromInt(entry_address + TAG_SIZE);
                memoryLower = basic_memory[0];
                memoryUpper = basic_memory[1];
            },
            6 => {
                const memory_map: [*]u32 = @ptrFromInt(entry_address + TAG_SIZE);
                entrySize = memory_map[0];
                entryVersion = memory_map[1];

                const entries_offset = TAG_SIZE + @sizeOf(u32) * 2;
                entries = @ptrFromInt(entry_address + entries_offset);
                entryCount = (entry.size - entries_offset) / entrySize;
            },
            14 => {
                acpiVersion2 = false;

                const rsdp: *acpi.rsdp = @ptrFromInt(entry_address + TAG_SIZE);
                acpiOldRsdp = rsdp.*;
            },
            15 => {
                acpiVersion2 = true;

                const rsdp: *acpi.rsdp_20 = @ptrFromInt(entry_address + TAG_SIZE);
                acpiNewRsdp = rsdp.*;
            },
            else => {},
        }

        entry_address += (entry.size + 7) & ~@as(usize, 7);
    }
}
