const std = @import("std");
const console = @import("./console.zig");
const scanmap = @import("./keys.zig");
const ps2 = @import("./ps2.zig");
const acpi = @import("./acpi.zig");
const port = @import("port.zig");
const pmm = @import("./mem.zig");
const kernel = @import("kernel.zig");
const art = @import("art.zig");
const utils = @import("utils.zig");

const pit = @import("pit.zig");
const history = @import("history.zig");

const eql = @import("std").mem.eql;

const BUFFER_SIZE = 4096;
var buffer: [BUFFER_SIZE]u8 = undefined;

fn read_line() usize {
    var index: usize = 0;
    while (true) {
        const scan_code = ps2.getScanCode();
        if (scan_code == 0) {
            continue;
        }

        // read the scan code and translate it into a key
        const key = scanmap.HandleKeyboard(scan_code);

        if (key.type == .unknown or key.type == .shift or key.type == .ctrl) {
            continue;
        }

        if (key.type == .backspace) {
            if (index > 0) {
                index -= 1;
                buffer[index] = ' ';
                console.backspace();
            }

            continue;
        }

        if (key.type == .enter) {
            console.newLine();
            return index;
        }

        if (key.type == .arrow_up) {
            console.clear_line();
            // const line = hist.last().?;
            // @memcpy(&buffer[0..lastcmd.len], lastcmd);
            // buffer = lastcmd;
            // for (lastcmd, 0..lastcmd.len) |value, i| {
            //     buffer[i] = value;
            // }

            // @memcpy(&buffer, &lastcmd);
            // console.write(buffer[0..lastlen]);
            // return lastcmd.len;
            // return line.len;
            // continue;
            // return lastlen;
        }

        // debug printf - uncomment "continue" above for .unknown
        // if (key.type == .unknown) {
        // const out = std.fmt.hex(key.value, .upper);
        // const sc = utils.uitoa(scan_code, utils.PrintStyle.hex).arr;
        // console.write(&sc);
        // continue;
        // };

        buffer[index] = key.value;
        console.putChar(key.value);
        index += 1;
    }
}

// var gpa = std.heap.GeneralPurposeAllocator(.{}){};
// const alloc = std.heap.page_allocator;
// const alloc = gpa.allocator();
// var hist = history.init();

var lastcmd: [BUFFER_SIZE]u8 = undefined;
var lastlen: usize = undefined;

pub fn exec() void {
    const format_buffer_size = 1024;
    var format_buffer: [format_buffer_size]u8 = undefined;

    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // defer {
    // const deinit_status = gpa.deinit();
    //fail test; can't try in defer as defer is executed after we return
    // if (deinit_status == .leak) {
    // @panic("deinit failed");
    // }
    // }

    // const alloc = gpa.allocator();
    // const hist = history.init(alloc);
    // defer hist.deinit();

    while (true) {
        console.write("> ");
        // var histor_cursor: usize = 0;

        const size = read_line();
        const command = buffer[0..size];
        @memcpy(&lastcmd, &buffer);
        lastlen = size;

        if (std.mem.eql(u8, command, "help")) {
            console.writeln(
                \\help     - Shows all commands.
                \\usedmem  - (mem) Shows the amount of used RAM, in KiB.
                \\totalmem - (tmem) Shows the total amount of usable RAM, in MiB.
                \\shutdown - Shuts down the computer via ACPI.
                \\reset    - Resets the computer via ACPI.
                \\ascii    - Print the ascii OS logo
                \\echo     - Echo the given text
                \\color    - (c) change console colors fg (0-15) fg+bg(16-255) (green|red)
                \\fg       - (c) change console colors fg (0-15) fg+bg(16-255) (green|red)
                \\bg       - (c) change console colors fg (0-15) fg+bg(16-255) (green|red)
            );
        } else if (std.mem.eql(u8, command, "clear")) {
            console.clear();
        } else if (std.mem.eql(u8, command, "usedmem") or eql(u8, command, "mem")) {
            const format = std.fmt.bufPrint(&format_buffer, "RAM in use: {d} kiB", .{pmm.pages_in_use * pmm.PAGE_SIZE / 1024}) catch unreachable;
            console.writeln(format);
        } else if (eql(u8, command, "totalmem") or eql(u8, command, "tmem")) {
            const format = std.fmt.bufPrint(&format_buffer, "Total usable RAM: {d} MiB", .{pmm.total_size / 1024 / 1024}) catch unreachable;
            console.writeln(format);
        } else if (std.mem.eql(u8, command, "shutdown")) {
            console.writeln("Shutting down...");
            acpi.shutdown();
            // qemu -> qemu 2.0 -> virtualbox -> cloud hypervisor
            console.writeln("qemu new versions...");
            port.outw(0x604, 0x2000);
            console.writeln("qemu old 2.0...");
            port.outw(0xB004, 0x2000);
            console.writeln("virtualbox...");
            port.outw(0x4004, 0x3400);
            console.writeln("cloud hypervisor...");
            port.outw(0x600, 0x34);
        } else if (std.mem.eql(u8, command, "reset")) {
            console.writeln("Resetting...");
            acpi.reset();
        } else if (std.mem.eql(u8, command, "ascii")) {
            for (art.ASUKA_LOGO) |line| {
                console.writeln(line);
            }
        } else if (std.mem.eql(u8, command, "")) {
            continue;
        } else if (std.mem.eql(u8, command, "uptime")) {
            console.printf("uptime {d}\n", .{pit.uptime()});
            continue;
        } else if (std.mem.eql(u8, command, "neofetch")) {
            for (art.ASUKA_LOGO) |line| {
                console.writeln(line);
            }
            console.printf("uptime:   {d}\n", .{pit.uptime()});
            console.printf("pit freq: {d}\n", .{pit.uptime()});
            const color = console.get_colors();
            console.set_bg(@intFromEnum(console.Colors.Green));
            console.write("  ");
            console.set_bg(@intFromEnum(console.Colors.Blue));
            console.write("  ");
            console.set_bg(@intFromEnum(console.Colors.Red));
            console.write("  ");
            console.set_bg(@intFromEnum(console.Colors.Magenta));
            console.write("  ");
            console.set_bg(@intFromEnum(console.Colors.Cyan));
            console.write("  ");
            console.set_bg(@intFromEnum(console.Colors.LightBlue));
            console.writeln("  ");
            console.setColor(color);
            continue;
        } else if (std.mem.eql(u8, command, "alloc")) {
            const addy = pmm.allocate(100);
            console.write("allocated 100bytes for funsies uwu ");
            const x = utils.uitoa(addy, utils.PrintStyle.hex).arr;
            console.write("at address: 0x");
            console.writeln(&x);
            continue;
        } else if (std.mem.eql(u8, command, "trans")) {
            const color = console.get_colors();
            console.set_bg(@intFromEnum(console.Colors.Cyan));
            console.writeln("                     ");
            console.set_bg(@intFromEnum(console.Colors.LightMagenta));
            console.writeln("                     ");
            console.set_bg(@intFromEnum(console.Colors.White));
            console.writeln("                     ");
            console.set_bg(@intFromEnum(console.Colors.LightMagenta));
            console.writeln("                     ");
            console.set_bg(@intFromEnum(console.Colors.Cyan));
            console.writeln("                     ");
            console.setColor(color);
        } else {
            var line = std.mem.splitSequence(u8, command, " ");
            const first = line.first();

            if (first.len == 0) {
                console.write("error reading command...");
                continue;
            }

            if (eql(u8, first, "color") or eql(u8, first, "c")) {
                if (line.peek() == null) {
                    console.setColor2(console.Colors.Red);
                    console.write("error: ");
                    console.setColor2(console.Colors.Green);
                    console.writeln("must provide a value between 0-15");
                    continue;
                }

                while (line.next()) |value| {
                    if (value.len < 1) {
                        console.setColor2(console.Colors.Red);
                        console.write("error: ");
                        console.setColor2(console.Colors.Green);
                        console.writeln("must provide a value between 0-15");
                        continue;
                    }

                    if (eql(u8, value, "green")) {
                        console.setColor2(console.Colors.Green);
                        continue;
                    }

                    if (eql(u8, value, "red")) {
                        console.setColor2(console.Colors.Red);
                        continue;
                    }

                    const col = std.fmt.parseInt(u8, value, 10) catch |e| {
                        switch (e) {
                            error.InvalidCharacter => {
                                console.writeln("uh uh uh >-< bad char");
                                continue;
                            },
                            error.Overflow => {
                                console.writeln("uh uh uh >-< buffaw ovofwow");
                                continue;
                            },
                        }
                    };

                    console.setColor(col);
                    continue;
                }
            }

            if (eql(u8, first, "fg") or eql(u8, first, "bg")) {
                while (line.next()) |value| {
                    const col = std.fmt.parseInt(u8, value, 10) catch |e| {
                        switch (e) {
                            error.InvalidCharacter => {
                                console.writeln("uh uh uh >-< bad char");
                                continue;
                            },
                            error.Overflow => {
                                console.writeln("uh uh uh >-< buffaw ovofwow");
                                continue;
                            },
                        }
                    };

                    if (eql(u8, first, "fg")) {
                        console.set_fg(col);
                    } else {
                        console.set_bg(col);
                    }
                }
                continue;
            }

            if (eql(u8, first, "echo")) {
                while (line.next()) |value| {
                    console.write(value);
                    console.write(" ");
                }
                console.writeln("");
                continue;
            }

            if (eql(u8, first, "sleep")) {
                while (line.next()) |value| {
                    const time = std.fmt.parseFloat(f64, value) catch |e| {
                        switch (e) {
                            error.InvalidCharacter => {
                                console.writeln("uh uh uh >-< bad char");
                                continue;
                            },
                        }
                    };

                    console.printf("sleeping for {d}\n", .{time});
                    // pit.sleep(time * 100_000);
                    pit.sleep(time);
                }

                continue;
            }

            // console.write("Unknown command: ");
            // console.writeln(command);
        }
    }
}
