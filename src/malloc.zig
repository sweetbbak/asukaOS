const std = @import("std");
const pmm = @import("./mem.zig");
// mmu

const PAGE_DIRECTORY_SIZE = 1024;
const PAGE_TABLE_SIZE = 1024;

extern fn load_page_directory(address: usize) void;
extern fn enable_paging() void;

pub fn init() void {
    const page_directory_address = pmm.allocate(PAGE_DIRECTORY_SIZE * @sizeOf(u32));
    const page_directory_pointer = @as([*]u32, @ptrFromInt(page_directory_address));

    // Start address, here it's 0
    var address: usize = 0;

    // Align the number of total pages to a 4096-byte boundary
    var total_pages = pmm.total_pages;
    while (total_pages % 4096 != 0) total_pages += 1;

    // The page directory has 1024 possible entries
    const page_directory_pages = total_pages / PAGE_DIRECTORY_SIZE;

    // Map each available page table entry
    for (0..page_directory_pages) |i| {
        // One page table maps 4 MiB of RAM
        const page_table_address = pmm.allocate(PAGE_TABLE_SIZE * @sizeOf(u32));
        const page_table_pointer = @as([*]u32, @ptrFromInt(page_table_address));

        for (0..PAGE_TABLE_SIZE) |j| {
            // The "3" here means "Supervisor level, Read/Write and Present"
            page_table_pointer[j] = (@as(u32, address) * 0x1000) | 3;
            address += 1;
        }

        // Set the first page table entry in the page directory
        page_directory_pointer[i] = @as(u32, page_table_address) | 3;
    }

    // Mark every other entry as "not present"
    for (page_directory_pages..PAGE_DIRECTORY_SIZE) |i| page_directory_pointer[i] = 2;

    // Load the page directory address and enable paging
    load_page_directory(page_directory_address);
    enable_paging();
}
