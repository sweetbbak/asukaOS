const std = @import("std");
const console = @import("./console.zig");
const ps2 = @import("./ps2.zig");
const acpi = @import("./acpi.zig");
const pmm = @import("./mem.zig");
const scanmap = @import("./keys.zig");

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

        buffer[index] = key.value;
        console.putChar(key.value);

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
                \\help - Shows all commands.
                \\usedram - Shows the amount of used RAM, in KiB.
                \\totalram - Shows the total amount of usable RAM, in MiB.
                \\shutdown - Shuts down the computer via ACPI.
                \\reset - Resets the computer via ACPI.
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
        } else if (std.mem.eql(u8, command, "reset")) {
            console.writeln("Resetting...");
            acpi.reset();
        } else {
            console.write("Unknown command: ");
            console.writeln(command);
        }
    }
}
