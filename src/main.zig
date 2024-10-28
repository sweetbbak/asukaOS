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
const pit = @import("pit.zig");
const art = @import("art.zig");

const ALIGN = 1 << 0;
const MEMINFO = 1 << 1;
const MAGIC = 0x1BADB002;
const FLAGS = ALIGN | MEMINFO;

pub fn panic(msg: []const u8, trace: ?*std.builtin.StackTrace, siz: ?usize) noreturn {
    @branchHint(.cold);
    _ = trace;
    _ = siz;

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

    for (art.ASUKA_LOGO) |line| {
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

    // set interrupt (hlt = halt interrupt | cli = clear interrupt)
    asm volatile ("sti");

    console.clear();
    console.writeln(art.KA);
    console.printf("{s}\n", .{art.ASUKA_LOGO2});

    console.writeln("[pit] init");
    // pit.init_pit();
    // pit.init((1 << 16) - 1);
    // pit.init(((1 << 16) - 1) / 2);
    pit.init(100);

    var i: u8 = 1;
    while (ps2.getScanCode() == 0) : (i += 1) {
        console.clear();
        console.printf("{s}\n", .{art.ASUKA_LOGO2});
        console.writeln("press any key to continue...");
        // console.printf("color: {X}\n", .{console.get_colors()});
        console.setColor(@intCast(i));
        if (i > 14) i = 0;
        pit.sleep_ns(1000);
    }

    console.setColor(10);
    console.clear();

    console.printf("pit freq: {d}\n", .{pit.get_frequency()});
    console.writeln("[shell] exec");
    shell.exec();

    while (true) {}
}
