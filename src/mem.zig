const std = @import("std");
const multiboot = @import("./multiboot.zig");
const console = @import("./console.zig");
// pmm

// Currently, we take 4 KiB from the stack (our program's stack space when it's loaded into memory)
// This is to ensure we have plenty of space for what we want to do
// linksection adds this variable to the '.bss' section of the executable which is where uninitialized
// variables live
export var buffer: [4 * 1024]u8 align(16) linksection(".bss") = undefined;

pub const PAGE_SIZE = 4096;
const BITMAP_UNIT_SIZE = 8;
const BitmapUnit = u8;

const Map = struct { address: usize, size: usize };
const AddressRange = struct { from: usize, to: usize };

// allow zero addressed pointers
var bitmap: [*]allowzero volatile BitmapUnit = undefined;

pub var total_pages: usize = 0;
var bitmap_size: usize = 0;
var number_of_pages: usize = 0;
pub var pages_in_use: usize = 0;
pub var total_size: usize = 0;

fn initialize_bitmap(best_map_address: usize, memory_maps: []Map, number_of_maps: usize) void {
    bitmap = @ptrFromInt(best_map_address);

    // Initialize bitmap by marking unavailable pages as "allocated", else setting them free
    var address: usize = 0;

    for (0..bitmap_size) |i| {
        var unit: BitmapUnit = 0;

        for (0..BITMAP_UNIT_SIZE) |j| {
            const mask: u8 = @intCast(@as(u16, 1) << @as(u4, @intCast(j)));
            var address_free = false;

            for (0..number_of_maps) |k| {
                if (address_free) break;

                const range = memory_maps[k];
                if (address >= range.address and address <= range.address + range.size) address_free = true;
            }

            // The address is in an unavailable range, mark it as "allocated"
            if (!address_free) unit |= mask;

            address += PAGE_SIZE;
        }

        bitmap[i] = unit;
    }

    // Reserve number_of_pages pages for bitmap, in the bitmap itself
    var satisfied_pages: usize = 0;
    var index: usize = 0;

    while (true) : (index += 1) {
        var unit = bitmap[index];

        for (0..BITMAP_UNIT_SIZE) |j| {
            // We have allocated the required number of pages, we can safely return the buffer now.
            if (satisfied_pages == number_of_pages) return;

            const mask: u8 = @intCast(@as(u16, 1) << @as(u4, @intCast(j)));

            if ((unit & mask) == 0) {
                // We found a free page!
                satisfied_pages += 1;
                unit |= mask;
                bitmap[index] = unit;
            } else {
                // This should never happen
                std.debug.panic("[pmm] found allocated page while trying to allocate bitmap", .{});
                return;
            }
        }
    }
}

//https://github.com/limine-bootloader/limine/blob/886523359c85aa10691e6b82229c91f31f21a04f/common/lib/misc.h#L66
fn div_round_up(a: usize, b: usize) usize {
    return (a + (b - 1)) / b;
}

pub fn init(max_memory_address: usize, entries: [*]multiboot.MultibootMemoryMapEntry, entry_count: usize) void {
    // Get a temporary fixed buffer allocator for our stack space
    var fba = std.heap.FixedBufferAllocator.init(&buffer);

    const allocator = fba.allocator();

    const memory_maps = allocator.alloc(Map, entry_count) catch unreachable;
    defer allocator.free(memory_maps);

    var number_of_maps: usize = 0;
    var best_map: Map = undefined;
    var found_map = false;

    // Find all available memory map entries
    for (0..entry_count) |i| {
        const entry = entries[i];

        // See https://en.wikipedia.org/wiki/PCI_hole
        if (entry.type == 1 and entry.address <= max_memory_address) { // Available && writable
            const size: usize = @intCast(entry.length);
            const map = Map{ .address = @intCast(entry.address), .size = size };

            memory_maps[number_of_maps] = map;
            number_of_maps += 1;
            total_size += size;

            // Calculate the required values
            total_pages = total_size / PAGE_SIZE;
            bitmap_size = div_round_up(total_pages, BITMAP_UNIT_SIZE);

            // Check if the current memory map is the best suited for the bitmap
            if (!found_map and bitmap_size <= size) {
                best_map = map;
                found_map = true;
            }
        }
    }

    // Calculate the rest of the values
    number_of_pages = div_round_up(bitmap_size, PAGE_SIZE);

    if (!found_map) {
        std.debug.panic("[pmm] not enough memory to initialize", .{});
        return;
    }

    // Initialize the bitmap with the memory map we found
    initialize_bitmap(best_map.address, memory_maps, number_of_maps);

    // At this point, we are using number_of_pages pages
    pages_in_use = number_of_pages;
}

pub fn allocate(size: usize) usize {
    // Calculate the required values
    var sz = size;
    while (sz % PAGE_SIZE != 0) sz += 1;

    const required_pages = sz / PAGE_SIZE;
    var satisfied_pages: usize = 0;
    var index: usize = 0;
    var address: usize = 0;

    while (true) : (index += 1) {
        var unit = bitmap[index];

        for (0..BITMAP_UNIT_SIZE) |j| {
            // We have allocated the required number of pages, we can safely return the buffer now.
            if (satisfied_pages == required_pages) {
                pages_in_use += satisfied_pages;
                return address;
            }

            const mask = @as(u8, @intCast(@as(u16, 1) << @as(u4, @intCast(j))));

            if ((unit & mask) == 0) {
                // We found a free page!
                satisfied_pages += 1;
                unit |= mask;
                bitmap[index] = unit;
            } else {
                // Either we still didn't find a free page, or the next page is allocated.
                address += PAGE_SIZE;
                satisfied_pages = 0;
            }
        }
    }
}

pub fn free(buffer_address: usize, size: usize) void {
    // Calculate the required values
    var sz = size;
    while (sz % PAGE_SIZE != 0) sz += 1;

    const required_pages = sz / PAGE_SIZE;
    var satisfied_pages: usize = 0;
    var index: usize = 0;
    var address: usize = 0;

    while (true) : (index += 1) {
        var unit = bitmap[index];

        for (0..BITMAP_UNIT_SIZE) |j| {
            // We have freed the required number of pages, we can safely return now.
            if (satisfied_pages == required_pages) {
                pages_in_use -= satisfied_pages;
                return;
            }

            if (address == buffer_address) {
                satisfied_pages += 1;
                unit &= ~(@as(u8, @intCast(@as(u16, 1) << @as(u4, @intCast(j)))));
                bitmap[index] = unit;
            } else address += PAGE_SIZE;
        }
    }
}
