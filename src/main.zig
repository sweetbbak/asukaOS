const std = @import("std");
const console = @import("console.zig");
const multiboot = @import("multiboot.zig");
const pmm = @import("mem.zig");
const mmu = @import("malloc.zig");
const gdt = @import("gdt.zig");
const idt = @import("idt.zig");
const pic = @import("pic.zig");
const ps2 = @import("ps2.zig");
const acpi = @import("acpi.zig");
const shell = @import("shell.zig");

const ALIGN = 1 << 0;
const MEMINFO = 1 << 1;
const MAGIC = 0x1BADB002;
const FLAGS = ALIGN | MEMINFO;

// const MultibootHeader = packed struct {
//     magic: i32 = MAGIC,
//     flags: i32,
//     checksum: i32,
//     padding: u32 = 0,
// };

// export var multiboot align(4) linksection(".multiboot") = MultibootHeader{
//     .flags = FLAGS,
//     .checksum = -(MAGIC + FLAGS),
// };

// export var stack_bytes: [16 * 1024]u8 align(16) linksection(".bss") = undefined;

// const stack_bytes_slice = stack_bytes[0..];

// export fn _start() callconv(.Naked) noreturn {
//     asm volatile (
//         \\ movl %[stk], %esp
//         \\ movl %esp, %ebp
//         \\ call kmain
//         :
//         : [stk] "{ecx}" (@intFromPtr(&stack_bytes_slice) + @sizeOf(@TypeOf(stack_bytes_slice))),
//     );
//     while (true) {}
// }

// header

// idk lol
// fn itoa() !void {
// }
//     _              _          ___  ____
// / \   ___ _   _| | ____ _ / _ \/ ___|
// / _ \ / __| | | | |/ / _` | | | \___ \
// / ___ \\__ \ |_| |   < (_| | |_| |___) |
// /_/   \_\___/\__,_|_|\_\__,_|\___/|____/

const ascii_art3 = [_][]const u8{
    "     _              _          ___  ____  ",
    "    / \\   ___ _   _| | ____ _ / _ \\/ ___| ",
    "   / _ \\ / __| | | | |/ / _` | | | \\___ \\ ",
    "  / ___ \\__ \\ |_| |   < (_| | |_| |___) |",
    " /_/   \\_\\___/\\__,_|_|\\_\\__,_|\\___/|____/ ",
};

pub fn panic(msg: []const u8, trace: ?*std.builtin.StackTrace, siz: ?usize) noreturn {
    @branchHint(.cold);
    _ = trace;
    _ = siz;
    // not often used
    // @setCold(true); // zig 14-1

    console.write("PANIC: ");
    console.write(msg);
    while (true) {}
}

export fn kmain(multiboot_info_address: usize) noreturn {
    asm volatile ("cli");
    console.initialize();

    console.setColor(1);
    console.writeln("Welcome!");

    console.setColor(12);
    for (ascii_art3) |line| {
        console.writeln(line);
    }

    console.setColor2(console.Colors.Green);

    console.writeln("[multiboot] init");
    multiboot.init(multiboot_info_address);

    console.writeln("[memory] init");
    pmm.init(multiboot.memoryUpper * 1024, multiboot.entries, multiboot.entryCount);

    console.writeln("[malloc] init");
    mmu.init();

    console.writeln("[gdt] init");
    gdt.init();

    console.writeln("[idt] init");
    idt.init();

    console.writeln("[pic] init");
    pic.init();

    console.writeln("[ps2] init");
    ps2.init();

    console.writeln("[acpi] init");
    acpi.init();

    console.writeln("[acpi] enable");
    acpi.enable();

    // for (0..15) |value| {
    //     const color: u8 = @intCast(value);
    //     console.setColor(color);
    //     console.writeln("[ OK ] manic panic");
    // }

    console.setColor2(console.Colors.Magenta);
    console.writeln(":3");

    asm volatile ("sti");
    console.writeln("[shell] exec");
    shell.exec();

    while (true) {}
}
