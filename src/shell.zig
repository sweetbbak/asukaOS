const std = @import("std");
const eql = @import("std").mem.eql;
const console = @import("./console.zig");
const ps2 = @import("./ps2.zig");
const acpi = @import("./acpi.zig");
const pmm = @import("./mem.zig");
const scanmap = @import("./keys.zig");
const art = @import("art.zig");
const port = @import("port.zig");
const utils = @import("utils.zig");

const BUFFER_SIZE = 4096;

var buffer: [BUFFER_SIZE]u8 = undefined;

fn read_line() usize {
    var index: usize = 0;

    while (true) {
        const scan_code = ps2.getScanCode();

        if (scan_code == 0) {
            continue;
        }

        const key = scanmap.getKey(scan_code);

        if (key.type == .unknown) {
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

        var isShift: bool = false;
        if (key.type == .shift) {
            isShift = true;
        }

        // debug printf - uncomment "continue" above for .unknown
        if (key.type == .unknown) {
            // const out = std.fmt.hex(scan_code, .upper);
            // const sc = utils.uitoa(scan_code, utils.PrintStyle.hex).arr;
            // console.write(&sc);
            const buf: []u8 = undefined;
            const out = std.fmt.bufPrint(buf, "{}", .{scan_code}) catch {
                continue;
            };
            console.write(out);
            // console.write(@as([]const u8, scan_code));
        }

        if (isShift) {
            const up = std.ascii.toUpper(key.value);
            buffer[index] = up;
            console.putChar(up);
        } else {
            buffer[index] = key.value;
            console.putChar(key.value);
        }

        index += 1;
    }
}

pub fn exec() void {
    const format_buffer_size = 1024;

    var format_buffer: [format_buffer_size]u8 = undefined;

    while (true) {
        console.write("> ");

        const size = read_line();
        const command = buffer[0..size];

        if (std.mem.eql(u8, command, "help")) {
            console.writeln(
                \\help     - Shows all commands.
                \\usedram  - Shows the amount of used RAM, in KiB.
                \\totalram - Shows the total amount of usable RAM, in MiB.
                \\shutdown - Shuts down the computer via ACPI.
                \\reset    - Resets the computer via ACPI.
                \\ascii    - Print the ascii OS logo
                \\echo     - Echo the given text
                \\color    - change console colors fg (0-15) fg+bg(16-255) (green|red)
            );
        } else if (std.mem.eql(u8, command, "clear")) {
            console.clear();
        } else if (std.mem.eql(u8, command, "usedram")) {
            const format = std.fmt.bufPrint(&format_buffer, "RAM in use: {d} kiB", .{pmm.pages_in_use * pmm.PAGE_SIZE / 1024}) catch unreachable;
            console.writeln(format);
        } else if (std.mem.eql(u8, command, "totalram")) {
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
        } else if (std.mem.eql(u8, command, "alloc")) {
            const addy = pmm.allocate(100);
            console.write("allocated 100bytes for funsies uwu ");
            const x = utils.uitoa(addy, utils.PrintStyle.hex).arr;
            console.write("at address: 0x");
            console.writeln(&x);
            continue;
        } else {
            var line = std.mem.splitSequence(u8, command, " ");
            const first = line.first();

            if (first.len == 0) {
                console.write("error reading command...");
                continue;
            }

            if (eql(u8, first, "color")) {
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

            if (eql(u8, first, "echo")) {
                while (line.next()) |value| {
                    console.write(value);
                    console.write(" ");
                }
                console.writeln("");
                continue;
            }

            // console.write("Unknown command: ");
            // console.writeln(command);
        }
    }
}
