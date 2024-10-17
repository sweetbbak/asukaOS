const std = @import("std");
// Thanks to: https://github.com/Rheydskey/zros

pub fn TicketLock(comptime value_type: type) type {
    return struct {
        last_ticket: std.atomic.Value(u32),
        current_ticket: std.atomic.Value(u32),
        value: value_type,

        pub fn init(value: value_type) @This() {
            return .{
                .last_ticket = std.atomic.Value(u32).init(0),
                .current_ticket = std.atomic.Value(u32).init(0),
                .value = value,
            };
        }

        pub fn lock(self: *@This()) *value_type {
            const a = self.last_ticket.fetchAdd(1, .acquire);

            while (self.current_ticket.load(.acquire) != a) {
                asm volatile ("pause" ::: "memory");
            }

            return &self.value;
        }

        pub fn unlock(self: *@This()) void {
            _ = self.current_ticket.fetchAdd(1, .acquire);
        }
    };
}
