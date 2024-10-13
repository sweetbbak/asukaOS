const std = @import("std");
const pmm = @import("./mem.zig");
const pic = @import("./pic.zig");
const ps2 = @import("./ps2.zig");

const IDT_ENTRIES = 256;

const segment_select = packed struct { rpl: u2, ti: u1, index: u13 };
const type_attrib = packed struct { gate_type: u4, zero: u1, dpl: u2, p: u1 };
const idt_entry = packed struct {
    offset1: u16,
    selector: segment_select,
    zero: u8,
    type_attributes: type_attrib,
    offset2: u16,
};
const idtr = packed struct { size: u16, offset: u32 };

fn create_entry(offset: u32) idt_entry {
    const type_attr = type_attrib{
        .gate_type = 0b1110,
        .zero = 0b0,
        .dpl = 0b00,
        .p = 0b1,
    };

    const segment_sel = segment_select{
        .rpl = 0b00,
        .ti = 0b0,
        .index = 0b0000000000001,
    };

    return idt_entry{
        .offset1 = @as(u16, @intCast(offset & 0xFFFF)),
        .selector = segment_sel,
        .zero = 0,
        .type_attributes = type_attr,
        .offset2 = @as(u16, @intCast((offset >> 16) & 0xFFFF)),
    };
}

fn interrupt_handler(irq: u8, code: u32) void {
    switch (irq) {
        0 => {
            std.debug.panic("Division Error", .{});
            return;
        },
        1 => {
            std.debug.panic("Debug", .{});
            return;
        },
        2 => {
            std.debug.panic("Non-maskable Interrupt", .{});
            return;
        },
        3 => {
            std.debug.panic("Breakpoint", .{});
            return;
        },
        4 => {
            std.debug.panic("Overflow", .{});
            return;
        },
        5 => {
            std.debug.panic("Bound Range Exceeded", .{});
            return;
        },
        6 => {
            std.debug.panic("Invalid Opcode", .{});
            return;
        },
        7 => {
            std.debug.panic("Device Not Available", .{});
            return;
        },
        8 => {
            std.debug.panic("Double Fault: {d}", .{code});
            return;
        },
        10 => {
            std.debug.panic("Invalid TSS: {d}", .{code});
            return;
        },
        11 => {
            std.debug.panic("Segment Not Present: {d}", .{code});
            return;
        },
        12 => {
            std.debug.panic("Stack-Segment Fault: {d}", .{code});
            return;
        },
        13 => {
            std.debug.panic("General Protection Fault: {d}", .{code});
            return;
        },
        14 => {
            std.debug.panic("Page Fault: {d}", .{code});
            return;
        },
        16 => {
            std.debug.panic("x87 Floating-Point Exception", .{});
            return;
        },
        17 => {
            std.debug.panic("Alignment Check: {d}", .{code});
            return;
        },
        18 => {
            std.debug.panic("Machine Check", .{});
            return;
        },
        19 => {
            std.debug.panic("SIMD Floating-Point Exception", .{});
            return;
        },
        20 => {
            std.debug.panic("Virtualization Exception", .{});
            return;
        },
        21 => {
            std.debug.panic("Control Protection Exception: {d}", .{code});
            return;
        },
        28 => {
            std.debug.panic("Hypervisor Injection Exception", .{});
            return;
        },
        29 => {
            std.debug.panic("VMM Communication Exception: {d}", .{code});
            return;
        },
        30 => {
            std.debug.panic("Security Exception: {d}", .{code});
            return;
        },
        else => {
            if (irq >= 0x20 and irq < 0x30) {
                switch (irq - 0x20) {
                    1 => {
                        ps2.onInterrupt();
                    },
                    else => {},
                }
            }

            pic.sendEOI(@as(u8, @intCast(irq)));
            // pic.sendEOI(@ptrCast(irq));
            // pic.sendEOI(irq);
            return;
        },
    }
}

extern fn load_idt(idt: usize) void;

fn irq0() callconv(.Interrupt) void {
    interrupt_handler(0, 0);
}
fn irq1() callconv(.Interrupt) void {
    interrupt_handler(1, 0);
}
fn irq2() callconv(.Interrupt) void {
    interrupt_handler(2, 0);
}
fn irq3() callconv(.Interrupt) void {
    interrupt_handler(3, 0);
}
fn irq4() callconv(.Interrupt) void {
    interrupt_handler(4, 0);
}
fn irq5() callconv(.Interrupt) void {
    interrupt_handler(5, 0);
}
fn irq6() callconv(.Interrupt) void {
    interrupt_handler(6, 0);
}
fn irq7() callconv(.Interrupt) void {
    interrupt_handler(7, 0);
}
// fn irq8(code: u32) callconv(.Interrupt) void {
//     interrupt_handler(8, code);
// }

fn irq8(code: *u32) callconv(.Interrupt) void {
    interrupt_handler(8, code.*);
}

fn irq9() callconv(.Interrupt) void {
    interrupt_handler(9, 0);
}
fn irq10(code: *u32) callconv(.Interrupt) void {
    interrupt_handler(10, code.*);
}
fn irq11(code: *u32) callconv(.Interrupt) void {
    interrupt_handler(11, code.*);
}
fn irq12(code: *u32) callconv(.Interrupt) void {
    interrupt_handler(12, code.*);
}
fn irq13(code: *u32) callconv(.Interrupt) void {
    interrupt_handler(13, code.*);
}
fn irq14(code: *u32) callconv(.Interrupt) void {
    interrupt_handler(14, code.*);
}
fn irq15() callconv(.Interrupt) void {
    interrupt_handler(15, 0);
}
fn irq16() callconv(.Interrupt) void {
    interrupt_handler(16, 0);
}
fn irq17(code: *u32) callconv(.Interrupt) void {
    interrupt_handler(17, code.*);
}
fn irq18() callconv(.Interrupt) void {
    interrupt_handler(18, 0);
}
fn irq19() callconv(.Interrupt) void {
    interrupt_handler(19, 0);
}
fn irq20() callconv(.Interrupt) void {
    interrupt_handler(20, 0);
}
fn irq21(code: *u32) callconv(.Interrupt) void {
    interrupt_handler(21, code.*);
}
fn irq22() callconv(.Interrupt) void {
    interrupt_handler(22, 0);
}
fn irq23() callconv(.Interrupt) void {
    interrupt_handler(23, 0);
}
fn irq24() callconv(.Interrupt) void {
    interrupt_handler(24, 0);
}
fn irq25() callconv(.Interrupt) void {
    interrupt_handler(25, 0);
}
fn irq26() callconv(.Interrupt) void {
    interrupt_handler(26, 0);
}
fn irq27() callconv(.Interrupt) void {
    interrupt_handler(27, 0);
}
fn irq28() callconv(.Interrupt) void {
    interrupt_handler(28, 0);
}
fn irq29(code: *u32) callconv(.Interrupt) void {
    interrupt_handler(29, code.*);
}
fn irq30(code: *u32) callconv(.Interrupt) void {
    interrupt_handler(30, code.*);
}
fn irq31() callconv(.Interrupt) void {
    interrupt_handler(31, 0);
}
fn irq32() callconv(.Interrupt) void {
    interrupt_handler(32, 0);
}
fn irq33() callconv(.Interrupt) void {
    interrupt_handler(33, 0);
}
fn irq34() callconv(.Interrupt) void {
    interrupt_handler(34, 0);
}
fn irq35() callconv(.Interrupt) void {
    interrupt_handler(35, 0);
}
fn irq36() callconv(.Interrupt) void {
    interrupt_handler(36, 0);
}
fn irq37() callconv(.Interrupt) void {
    interrupt_handler(37, 0);
}
fn irq38() callconv(.Interrupt) void {
    interrupt_handler(38, 0);
}
fn irq39() callconv(.Interrupt) void {
    interrupt_handler(39, 0);
}
fn irq40() callconv(.Interrupt) void {
    interrupt_handler(40, 0);
}
fn irq41() callconv(.Interrupt) void {
    interrupt_handler(41, 0);
}
fn irq42() callconv(.Interrupt) void {
    interrupt_handler(42, 0);
}
fn irq43() callconv(.Interrupt) void {
    interrupt_handler(43, 0);
}
fn irq44() callconv(.Interrupt) void {
    interrupt_handler(44, 0);
}
fn irq45() callconv(.Interrupt) void {
    interrupt_handler(45, 0);
}
fn irq46() callconv(.Interrupt) void {
    interrupt_handler(46, 0);
}
fn irq47() callconv(.Interrupt) void {
    interrupt_handler(47, 0);
}
fn irq48() callconv(.Interrupt) void {
    interrupt_handler(48, 0);
}
fn irq49() callconv(.Interrupt) void {
    interrupt_handler(49, 0);
}
fn irq50() callconv(.Interrupt) void {
    interrupt_handler(50, 0);
}
fn irq51() callconv(.Interrupt) void {
    interrupt_handler(51, 0);
}
fn irq52() callconv(.Interrupt) void {
    interrupt_handler(52, 0);
}
fn irq53() callconv(.Interrupt) void {
    interrupt_handler(53, 0);
}
fn irq54() callconv(.Interrupt) void {
    interrupt_handler(54, 0);
}
fn irq55() callconv(.Interrupt) void {
    interrupt_handler(55, 0);
}
fn irq56() callconv(.Interrupt) void {
    interrupt_handler(56, 0);
}
fn irq57() callconv(.Interrupt) void {
    interrupt_handler(57, 0);
}
fn irq58() callconv(.Interrupt) void {
    interrupt_handler(58, 0);
}
fn irq59() callconv(.Interrupt) void {
    interrupt_handler(59, 0);
}
fn irq60() callconv(.Interrupt) void {
    interrupt_handler(60, 0);
}
fn irq61() callconv(.Interrupt) void {
    interrupt_handler(61, 0);
}
fn irq62() callconv(.Interrupt) void {
    interrupt_handler(62, 0);
}
fn irq63() callconv(.Interrupt) void {
    interrupt_handler(63, 0);
}
fn irq64() callconv(.Interrupt) void {
    interrupt_handler(64, 0);
}
fn irq65() callconv(.Interrupt) void {
    interrupt_handler(65, 0);
}
fn irq66() callconv(.Interrupt) void {
    interrupt_handler(66, 0);
}
fn irq67() callconv(.Interrupt) void {
    interrupt_handler(67, 0);
}
fn irq68() callconv(.Interrupt) void {
    interrupt_handler(68, 0);
}
fn irq69() callconv(.Interrupt) void {
    interrupt_handler(69, 0);
}
fn irq70() callconv(.Interrupt) void {
    interrupt_handler(70, 0);
}
fn irq71() callconv(.Interrupt) void {
    interrupt_handler(71, 0);
}
fn irq72() callconv(.Interrupt) void {
    interrupt_handler(72, 0);
}
fn irq73() callconv(.Interrupt) void {
    interrupt_handler(73, 0);
}
fn irq74() callconv(.Interrupt) void {
    interrupt_handler(74, 0);
}
fn irq75() callconv(.Interrupt) void {
    interrupt_handler(75, 0);
}
fn irq76() callconv(.Interrupt) void {
    interrupt_handler(76, 0);
}
fn irq77() callconv(.Interrupt) void {
    interrupt_handler(77, 0);
}
fn irq78() callconv(.Interrupt) void {
    interrupt_handler(78, 0);
}
fn irq79() callconv(.Interrupt) void {
    interrupt_handler(79, 0);
}
fn irq80() callconv(.Interrupt) void {
    interrupt_handler(80, 0);
}
fn irq81() callconv(.Interrupt) void {
    interrupt_handler(81, 0);
}
fn irq82() callconv(.Interrupt) void {
    interrupt_handler(82, 0);
}
fn irq83() callconv(.Interrupt) void {
    interrupt_handler(83, 0);
}
fn irq84() callconv(.Interrupt) void {
    interrupt_handler(84, 0);
}
fn irq85() callconv(.Interrupt) void {
    interrupt_handler(85, 0);
}
fn irq86() callconv(.Interrupt) void {
    interrupt_handler(86, 0);
}
fn irq87() callconv(.Interrupt) void {
    interrupt_handler(87, 0);
}
fn irq88() callconv(.Interrupt) void {
    interrupt_handler(88, 0);
}
fn irq89() callconv(.Interrupt) void {
    interrupt_handler(89, 0);
}
fn irq90() callconv(.Interrupt) void {
    interrupt_handler(90, 0);
}
fn irq91() callconv(.Interrupt) void {
    interrupt_handler(91, 0);
}
fn irq92() callconv(.Interrupt) void {
    interrupt_handler(92, 0);
}
fn irq93() callconv(.Interrupt) void {
    interrupt_handler(93, 0);
}
fn irq94() callconv(.Interrupt) void {
    interrupt_handler(94, 0);
}
fn irq95() callconv(.Interrupt) void {
    interrupt_handler(95, 0);
}
fn irq96() callconv(.Interrupt) void {
    interrupt_handler(96, 0);
}
fn irq97() callconv(.Interrupt) void {
    interrupt_handler(97, 0);
}
fn irq98() callconv(.Interrupt) void {
    interrupt_handler(98, 0);
}
fn irq99() callconv(.Interrupt) void {
    interrupt_handler(99, 0);
}
fn irq100() callconv(.Interrupt) void {
    interrupt_handler(100, 0);
}
fn irq101() callconv(.Interrupt) void {
    interrupt_handler(101, 0);
}
fn irq102() callconv(.Interrupt) void {
    interrupt_handler(102, 0);
}
fn irq103() callconv(.Interrupt) void {
    interrupt_handler(103, 0);
}
fn irq104() callconv(.Interrupt) void {
    interrupt_handler(104, 0);
}
fn irq105() callconv(.Interrupt) void {
    interrupt_handler(105, 0);
}
fn irq106() callconv(.Interrupt) void {
    interrupt_handler(106, 0);
}
fn irq107() callconv(.Interrupt) void {
    interrupt_handler(107, 0);
}
fn irq108() callconv(.Interrupt) void {
    interrupt_handler(108, 0);
}
fn irq109() callconv(.Interrupt) void {
    interrupt_handler(109, 0);
}
fn irq110() callconv(.Interrupt) void {
    interrupt_handler(110, 0);
}
fn irq111() callconv(.Interrupt) void {
    interrupt_handler(111, 0);
}
fn irq112() callconv(.Interrupt) void {
    interrupt_handler(112, 0);
}
fn irq113() callconv(.Interrupt) void {
    interrupt_handler(113, 0);
}
fn irq114() callconv(.Interrupt) void {
    interrupt_handler(114, 0);
}
fn irq115() callconv(.Interrupt) void {
    interrupt_handler(115, 0);
}
fn irq116() callconv(.Interrupt) void {
    interrupt_handler(116, 0);
}
fn irq117() callconv(.Interrupt) void {
    interrupt_handler(117, 0);
}
fn irq118() callconv(.Interrupt) void {
    interrupt_handler(118, 0);
}
fn irq119() callconv(.Interrupt) void {
    interrupt_handler(119, 0);
}
fn irq120() callconv(.Interrupt) void {
    interrupt_handler(120, 0);
}
fn irq121() callconv(.Interrupt) void {
    interrupt_handler(121, 0);
}
fn irq122() callconv(.Interrupt) void {
    interrupt_handler(122, 0);
}
fn irq123() callconv(.Interrupt) void {
    interrupt_handler(123, 0);
}
fn irq124() callconv(.Interrupt) void {
    interrupt_handler(124, 0);
}
fn irq125() callconv(.Interrupt) void {
    interrupt_handler(125, 0);
}
fn irq126() callconv(.Interrupt) void {
    interrupt_handler(126, 0);
}
fn irq127() callconv(.Interrupt) void {
    interrupt_handler(127, 0);
}
fn irq128() callconv(.Interrupt) void {
    interrupt_handler(128, 0);
}
fn irq129() callconv(.Interrupt) void {
    interrupt_handler(129, 0);
}
fn irq130() callconv(.Interrupt) void {
    interrupt_handler(130, 0);
}
fn irq131() callconv(.Interrupt) void {
    interrupt_handler(131, 0);
}
fn irq132() callconv(.Interrupt) void {
    interrupt_handler(132, 0);
}
fn irq133() callconv(.Interrupt) void {
    interrupt_handler(133, 0);
}
fn irq134() callconv(.Interrupt) void {
    interrupt_handler(134, 0);
}
fn irq135() callconv(.Interrupt) void {
    interrupt_handler(135, 0);
}
fn irq136() callconv(.Interrupt) void {
    interrupt_handler(136, 0);
}
fn irq137() callconv(.Interrupt) void {
    interrupt_handler(137, 0);
}
fn irq138() callconv(.Interrupt) void {
    interrupt_handler(138, 0);
}
fn irq139() callconv(.Interrupt) void {
    interrupt_handler(139, 0);
}
fn irq140() callconv(.Interrupt) void {
    interrupt_handler(140, 0);
}
fn irq141() callconv(.Interrupt) void {
    interrupt_handler(141, 0);
}
fn irq142() callconv(.Interrupt) void {
    interrupt_handler(142, 0);
}
fn irq143() callconv(.Interrupt) void {
    interrupt_handler(143, 0);
}
fn irq144() callconv(.Interrupt) void {
    interrupt_handler(144, 0);
}
fn irq145() callconv(.Interrupt) void {
    interrupt_handler(145, 0);
}
fn irq146() callconv(.Interrupt) void {
    interrupt_handler(146, 0);
}
fn irq147() callconv(.Interrupt) void {
    interrupt_handler(147, 0);
}
fn irq148() callconv(.Interrupt) void {
    interrupt_handler(148, 0);
}
fn irq149() callconv(.Interrupt) void {
    interrupt_handler(149, 0);
}
fn irq150() callconv(.Interrupt) void {
    interrupt_handler(150, 0);
}
fn irq151() callconv(.Interrupt) void {
    interrupt_handler(151, 0);
}
fn irq152() callconv(.Interrupt) void {
    interrupt_handler(152, 0);
}
fn irq153() callconv(.Interrupt) void {
    interrupt_handler(153, 0);
}
fn irq154() callconv(.Interrupt) void {
    interrupt_handler(154, 0);
}
fn irq155() callconv(.Interrupt) void {
    interrupt_handler(155, 0);
}
fn irq156() callconv(.Interrupt) void {
    interrupt_handler(156, 0);
}
fn irq157() callconv(.Interrupt) void {
    interrupt_handler(157, 0);
}
fn irq158() callconv(.Interrupt) void {
    interrupt_handler(158, 0);
}
fn irq159() callconv(.Interrupt) void {
    interrupt_handler(159, 0);
}
fn irq160() callconv(.Interrupt) void {
    interrupt_handler(160, 0);
}
fn irq161() callconv(.Interrupt) void {
    interrupt_handler(161, 0);
}
fn irq162() callconv(.Interrupt) void {
    interrupt_handler(162, 0);
}
fn irq163() callconv(.Interrupt) void {
    interrupt_handler(163, 0);
}
fn irq164() callconv(.Interrupt) void {
    interrupt_handler(164, 0);
}
fn irq165() callconv(.Interrupt) void {
    interrupt_handler(165, 0);
}
fn irq166() callconv(.Interrupt) void {
    interrupt_handler(166, 0);
}
fn irq167() callconv(.Interrupt) void {
    interrupt_handler(167, 0);
}
fn irq168() callconv(.Interrupt) void {
    interrupt_handler(168, 0);
}
fn irq169() callconv(.Interrupt) void {
    interrupt_handler(169, 0);
}
fn irq170() callconv(.Interrupt) void {
    interrupt_handler(170, 0);
}
fn irq171() callconv(.Interrupt) void {
    interrupt_handler(171, 0);
}
fn irq172() callconv(.Interrupt) void {
    interrupt_handler(172, 0);
}
fn irq173() callconv(.Interrupt) void {
    interrupt_handler(173, 0);
}
fn irq174() callconv(.Interrupt) void {
    interrupt_handler(174, 0);
}
fn irq175() callconv(.Interrupt) void {
    interrupt_handler(175, 0);
}
fn irq176() callconv(.Interrupt) void {
    interrupt_handler(176, 0);
}
fn irq177() callconv(.Interrupt) void {
    interrupt_handler(177, 0);
}
fn irq178() callconv(.Interrupt) void {
    interrupt_handler(178, 0);
}
fn irq179() callconv(.Interrupt) void {
    interrupt_handler(179, 0);
}
fn irq180() callconv(.Interrupt) void {
    interrupt_handler(180, 0);
}
fn irq181() callconv(.Interrupt) void {
    interrupt_handler(181, 0);
}
fn irq182() callconv(.Interrupt) void {
    interrupt_handler(182, 0);
}
fn irq183() callconv(.Interrupt) void {
    interrupt_handler(183, 0);
}
fn irq184() callconv(.Interrupt) void {
    interrupt_handler(184, 0);
}
fn irq185() callconv(.Interrupt) void {
    interrupt_handler(185, 0);
}
fn irq186() callconv(.Interrupt) void {
    interrupt_handler(186, 0);
}
fn irq187() callconv(.Interrupt) void {
    interrupt_handler(187, 0);
}
fn irq188() callconv(.Interrupt) void {
    interrupt_handler(188, 0);
}
fn irq189() callconv(.Interrupt) void {
    interrupt_handler(189, 0);
}
fn irq190() callconv(.Interrupt) void {
    interrupt_handler(190, 0);
}
fn irq191() callconv(.Interrupt) void {
    interrupt_handler(191, 0);
}
fn irq192() callconv(.Interrupt) void {
    interrupt_handler(192, 0);
}
fn irq193() callconv(.Interrupt) void {
    interrupt_handler(193, 0);
}
fn irq194() callconv(.Interrupt) void {
    interrupt_handler(194, 0);
}
fn irq195() callconv(.Interrupt) void {
    interrupt_handler(195, 0);
}
fn irq196() callconv(.Interrupt) void {
    interrupt_handler(196, 0);
}
fn irq197() callconv(.Interrupt) void {
    interrupt_handler(197, 0);
}
fn irq198() callconv(.Interrupt) void {
    interrupt_handler(198, 0);
}
fn irq199() callconv(.Interrupt) void {
    interrupt_handler(199, 0);
}
fn irq200() callconv(.Interrupt) void {
    interrupt_handler(200, 0);
}
fn irq201() callconv(.Interrupt) void {
    interrupt_handler(201, 0);
}
fn irq202() callconv(.Interrupt) void {
    interrupt_handler(202, 0);
}
fn irq203() callconv(.Interrupt) void {
    interrupt_handler(203, 0);
}
fn irq204() callconv(.Interrupt) void {
    interrupt_handler(204, 0);
}
fn irq205() callconv(.Interrupt) void {
    interrupt_handler(205, 0);
}
fn irq206() callconv(.Interrupt) void {
    interrupt_handler(206, 0);
}
fn irq207() callconv(.Interrupt) void {
    interrupt_handler(207, 0);
}
fn irq208() callconv(.Interrupt) void {
    interrupt_handler(208, 0);
}
fn irq209() callconv(.Interrupt) void {
    interrupt_handler(209, 0);
}
fn irq210() callconv(.Interrupt) void {
    interrupt_handler(210, 0);
}
fn irq211() callconv(.Interrupt) void {
    interrupt_handler(211, 0);
}
fn irq212() callconv(.Interrupt) void {
    interrupt_handler(212, 0);
}
fn irq213() callconv(.Interrupt) void {
    interrupt_handler(213, 0);
}
fn irq214() callconv(.Interrupt) void {
    interrupt_handler(214, 0);
}
fn irq215() callconv(.Interrupt) void {
    interrupt_handler(215, 0);
}
fn irq216() callconv(.Interrupt) void {
    interrupt_handler(216, 0);
}
fn irq217() callconv(.Interrupt) void {
    interrupt_handler(217, 0);
}
fn irq218() callconv(.Interrupt) void {
    interrupt_handler(218, 0);
}
fn irq219() callconv(.Interrupt) void {
    interrupt_handler(219, 0);
}
fn irq220() callconv(.Interrupt) void {
    interrupt_handler(220, 0);
}
fn irq221() callconv(.Interrupt) void {
    interrupt_handler(221, 0);
}
fn irq222() callconv(.Interrupt) void {
    interrupt_handler(222, 0);
}
fn irq223() callconv(.Interrupt) void {
    interrupt_handler(223, 0);
}
fn irq224() callconv(.Interrupt) void {
    interrupt_handler(224, 0);
}
fn irq225() callconv(.Interrupt) void {
    interrupt_handler(225, 0);
}
fn irq226() callconv(.Interrupt) void {
    interrupt_handler(226, 0);
}
fn irq227() callconv(.Interrupt) void {
    interrupt_handler(227, 0);
}
fn irq228() callconv(.Interrupt) void {
    interrupt_handler(228, 0);
}
fn irq229() callconv(.Interrupt) void {
    interrupt_handler(229, 0);
}
fn irq230() callconv(.Interrupt) void {
    interrupt_handler(230, 0);
}
fn irq231() callconv(.Interrupt) void {
    interrupt_handler(231, 0);
}
fn irq232() callconv(.Interrupt) void {
    interrupt_handler(232, 0);
}
fn irq233() callconv(.Interrupt) void {
    interrupt_handler(233, 0);
}
fn irq234() callconv(.Interrupt) void {
    interrupt_handler(234, 0);
}
fn irq235() callconv(.Interrupt) void {
    interrupt_handler(235, 0);
}
fn irq236() callconv(.Interrupt) void {
    interrupt_handler(236, 0);
}
fn irq237() callconv(.Interrupt) void {
    interrupt_handler(237, 0);
}
fn irq238() callconv(.Interrupt) void {
    interrupt_handler(238, 0);
}
fn irq239() callconv(.Interrupt) void {
    interrupt_handler(239, 0);
}
fn irq240() callconv(.Interrupt) void {
    interrupt_handler(240, 0);
}
fn irq241() callconv(.Interrupt) void {
    interrupt_handler(241, 0);
}
fn irq242() callconv(.Interrupt) void {
    interrupt_handler(242, 0);
}
fn irq243() callconv(.Interrupt) void {
    interrupt_handler(243, 0);
}
fn irq244() callconv(.Interrupt) void {
    interrupt_handler(244, 0);
}
fn irq245() callconv(.Interrupt) void {
    interrupt_handler(245, 0);
}
fn irq246() callconv(.Interrupt) void {
    interrupt_handler(246, 0);
}
fn irq247() callconv(.Interrupt) void {
    interrupt_handler(247, 0);
}
fn irq248() callconv(.Interrupt) void {
    interrupt_handler(248, 0);
}
fn irq249() callconv(.Interrupt) void {
    interrupt_handler(249, 0);
}
fn irq250() callconv(.Interrupt) void {
    interrupt_handler(250, 0);
}
fn irq251() callconv(.Interrupt) void {
    interrupt_handler(251, 0);
}
fn irq252() callconv(.Interrupt) void {
    interrupt_handler(252, 0);
}
fn irq253() callconv(.Interrupt) void {
    interrupt_handler(253, 0);
}
fn irq254() callconv(.Interrupt) void {
    interrupt_handler(254, 0);
}
fn irq255() callconv(.Interrupt) void {
    interrupt_handler(255, 0);
}

pub fn init() void {
    // Initialize buffer and add all entries
    const idt_entries_size = @sizeOf(idt_entry) * IDT_ENTRIES;

    const idt_entries_address = pmm.allocate(idt_entries_size);
    const idt_entries = @as([*]idt_entry, @ptrFromInt(idt_entries_address));

    idt_entries[0] = create_entry(@as(u32, @intFromPtr(&irq0)));
    idt_entries[1] = create_entry(@as(u32, @intFromPtr(&irq1)));
    idt_entries[2] = create_entry(@as(u32, @intFromPtr(&irq2)));
    idt_entries[3] = create_entry(@as(u32, @intFromPtr(&irq3)));
    idt_entries[4] = create_entry(@as(u32, @intFromPtr(&irq4)));
    idt_entries[5] = create_entry(@as(u32, @intFromPtr(&irq5)));
    idt_entries[6] = create_entry(@as(u32, @intFromPtr(&irq6)));
    idt_entries[7] = create_entry(@as(u32, @intFromPtr(&irq7)));
    idt_entries[8] = create_entry(@as(u32, @intFromPtr(&irq8)));
    idt_entries[9] = create_entry(@as(u32, @intFromPtr(&irq9)));
    idt_entries[10] = create_entry(@as(u32, @intFromPtr(&irq10)));
    idt_entries[11] = create_entry(@as(u32, @intFromPtr(&irq11)));
    idt_entries[12] = create_entry(@as(u32, @intFromPtr(&irq12)));
    idt_entries[13] = create_entry(@as(u32, @intFromPtr(&irq13)));
    idt_entries[14] = create_entry(@as(u32, @intFromPtr(&irq14)));
    idt_entries[15] = create_entry(@as(u32, @intFromPtr(&irq15)));
    idt_entries[16] = create_entry(@as(u32, @intFromPtr(&irq16)));
    idt_entries[17] = create_entry(@as(u32, @intFromPtr(&irq17)));
    idt_entries[18] = create_entry(@as(u32, @intFromPtr(&irq18)));
    idt_entries[19] = create_entry(@as(u32, @intFromPtr(&irq19)));
    idt_entries[20] = create_entry(@as(u32, @intFromPtr(&irq20)));
    idt_entries[21] = create_entry(@as(u32, @intFromPtr(&irq21)));
    idt_entries[22] = create_entry(@as(u32, @intFromPtr(&irq22)));
    idt_entries[23] = create_entry(@as(u32, @intFromPtr(&irq23)));
    idt_entries[24] = create_entry(@as(u32, @intFromPtr(&irq24)));
    idt_entries[25] = create_entry(@as(u32, @intFromPtr(&irq25)));
    idt_entries[26] = create_entry(@as(u32, @intFromPtr(&irq26)));
    idt_entries[27] = create_entry(@as(u32, @intFromPtr(&irq27)));
    idt_entries[28] = create_entry(@as(u32, @intFromPtr(&irq28)));
    idt_entries[29] = create_entry(@as(u32, @intFromPtr(&irq29)));
    idt_entries[30] = create_entry(@as(u32, @intFromPtr(&irq30)));
    idt_entries[31] = create_entry(@as(u32, @intFromPtr(&irq31)));
    idt_entries[32] = create_entry(@as(u32, @intFromPtr(&irq32)));
    idt_entries[33] = create_entry(@as(u32, @intFromPtr(&irq33)));
    idt_entries[34] = create_entry(@as(u32, @intFromPtr(&irq34)));
    idt_entries[35] = create_entry(@as(u32, @intFromPtr(&irq35)));
    idt_entries[36] = create_entry(@as(u32, @intFromPtr(&irq36)));
    idt_entries[37] = create_entry(@as(u32, @intFromPtr(&irq37)));
    idt_entries[38] = create_entry(@as(u32, @intFromPtr(&irq38)));
    idt_entries[39] = create_entry(@as(u32, @intFromPtr(&irq39)));
    idt_entries[40] = create_entry(@as(u32, @intFromPtr(&irq40)));
    idt_entries[41] = create_entry(@as(u32, @intFromPtr(&irq41)));
    idt_entries[42] = create_entry(@as(u32, @intFromPtr(&irq42)));
    idt_entries[43] = create_entry(@as(u32, @intFromPtr(&irq43)));
    idt_entries[44] = create_entry(@as(u32, @intFromPtr(&irq44)));
    idt_entries[45] = create_entry(@as(u32, @intFromPtr(&irq45)));
    idt_entries[46] = create_entry(@as(u32, @intFromPtr(&irq46)));
    idt_entries[47] = create_entry(@as(u32, @intFromPtr(&irq47)));
    idt_entries[48] = create_entry(@as(u32, @intFromPtr(&irq48)));
    idt_entries[49] = create_entry(@as(u32, @intFromPtr(&irq49)));
    idt_entries[50] = create_entry(@as(u32, @intFromPtr(&irq50)));
    idt_entries[51] = create_entry(@as(u32, @intFromPtr(&irq51)));
    idt_entries[52] = create_entry(@as(u32, @intFromPtr(&irq52)));
    idt_entries[53] = create_entry(@as(u32, @intFromPtr(&irq53)));
    idt_entries[54] = create_entry(@as(u32, @intFromPtr(&irq54)));
    idt_entries[55] = create_entry(@as(u32, @intFromPtr(&irq55)));
    idt_entries[56] = create_entry(@as(u32, @intFromPtr(&irq56)));
    idt_entries[57] = create_entry(@as(u32, @intFromPtr(&irq57)));
    idt_entries[58] = create_entry(@as(u32, @intFromPtr(&irq58)));
    idt_entries[59] = create_entry(@as(u32, @intFromPtr(&irq59)));
    idt_entries[60] = create_entry(@as(u32, @intFromPtr(&irq60)));
    idt_entries[61] = create_entry(@as(u32, @intFromPtr(&irq61)));
    idt_entries[62] = create_entry(@as(u32, @intFromPtr(&irq62)));
    idt_entries[63] = create_entry(@as(u32, @intFromPtr(&irq63)));
    idt_entries[64] = create_entry(@as(u32, @intFromPtr(&irq64)));
    idt_entries[65] = create_entry(@as(u32, @intFromPtr(&irq65)));
    idt_entries[66] = create_entry(@as(u32, @intFromPtr(&irq66)));
    idt_entries[67] = create_entry(@as(u32, @intFromPtr(&irq67)));
    idt_entries[68] = create_entry(@as(u32, @intFromPtr(&irq68)));
    idt_entries[69] = create_entry(@as(u32, @intFromPtr(&irq69)));
    idt_entries[70] = create_entry(@as(u32, @intFromPtr(&irq70)));
    idt_entries[71] = create_entry(@as(u32, @intFromPtr(&irq71)));
    idt_entries[72] = create_entry(@as(u32, @intFromPtr(&irq72)));
    idt_entries[73] = create_entry(@as(u32, @intFromPtr(&irq73)));
    idt_entries[74] = create_entry(@as(u32, @intFromPtr(&irq74)));
    idt_entries[75] = create_entry(@as(u32, @intFromPtr(&irq75)));
    idt_entries[76] = create_entry(@as(u32, @intFromPtr(&irq76)));
    idt_entries[77] = create_entry(@as(u32, @intFromPtr(&irq77)));
    idt_entries[78] = create_entry(@as(u32, @intFromPtr(&irq78)));
    idt_entries[79] = create_entry(@as(u32, @intFromPtr(&irq79)));
    idt_entries[80] = create_entry(@as(u32, @intFromPtr(&irq80)));
    idt_entries[81] = create_entry(@as(u32, @intFromPtr(&irq81)));
    idt_entries[82] = create_entry(@as(u32, @intFromPtr(&irq82)));
    idt_entries[83] = create_entry(@as(u32, @intFromPtr(&irq83)));
    idt_entries[84] = create_entry(@as(u32, @intFromPtr(&irq84)));
    idt_entries[85] = create_entry(@as(u32, @intFromPtr(&irq85)));
    idt_entries[86] = create_entry(@as(u32, @intFromPtr(&irq86)));
    idt_entries[87] = create_entry(@as(u32, @intFromPtr(&irq87)));
    idt_entries[88] = create_entry(@as(u32, @intFromPtr(&irq88)));
    idt_entries[89] = create_entry(@as(u32, @intFromPtr(&irq89)));
    idt_entries[90] = create_entry(@as(u32, @intFromPtr(&irq90)));
    idt_entries[91] = create_entry(@as(u32, @intFromPtr(&irq91)));
    idt_entries[92] = create_entry(@as(u32, @intFromPtr(&irq92)));
    idt_entries[93] = create_entry(@as(u32, @intFromPtr(&irq93)));
    idt_entries[94] = create_entry(@as(u32, @intFromPtr(&irq94)));
    idt_entries[95] = create_entry(@as(u32, @intFromPtr(&irq95)));
    idt_entries[96] = create_entry(@as(u32, @intFromPtr(&irq96)));
    idt_entries[97] = create_entry(@as(u32, @intFromPtr(&irq97)));
    idt_entries[98] = create_entry(@as(u32, @intFromPtr(&irq98)));
    idt_entries[99] = create_entry(@as(u32, @intFromPtr(&irq99)));
    idt_entries[100] = create_entry(@as(u32, @intFromPtr(&irq100)));
    idt_entries[101] = create_entry(@as(u32, @intFromPtr(&irq101)));
    idt_entries[102] = create_entry(@as(u32, @intFromPtr(&irq102)));
    idt_entries[103] = create_entry(@as(u32, @intFromPtr(&irq103)));
    idt_entries[104] = create_entry(@as(u32, @intFromPtr(&irq104)));
    idt_entries[105] = create_entry(@as(u32, @intFromPtr(&irq105)));
    idt_entries[106] = create_entry(@as(u32, @intFromPtr(&irq106)));
    idt_entries[107] = create_entry(@as(u32, @intFromPtr(&irq107)));
    idt_entries[108] = create_entry(@as(u32, @intFromPtr(&irq108)));
    idt_entries[109] = create_entry(@as(u32, @intFromPtr(&irq109)));
    idt_entries[110] = create_entry(@as(u32, @intFromPtr(&irq110)));
    idt_entries[111] = create_entry(@as(u32, @intFromPtr(&irq111)));
    idt_entries[112] = create_entry(@as(u32, @intFromPtr(&irq112)));
    idt_entries[113] = create_entry(@as(u32, @intFromPtr(&irq113)));
    idt_entries[114] = create_entry(@as(u32, @intFromPtr(&irq114)));
    idt_entries[115] = create_entry(@as(u32, @intFromPtr(&irq115)));
    idt_entries[116] = create_entry(@as(u32, @intFromPtr(&irq116)));
    idt_entries[117] = create_entry(@as(u32, @intFromPtr(&irq117)));
    idt_entries[118] = create_entry(@as(u32, @intFromPtr(&irq118)));
    idt_entries[119] = create_entry(@as(u32, @intFromPtr(&irq119)));
    idt_entries[120] = create_entry(@as(u32, @intFromPtr(&irq120)));
    idt_entries[121] = create_entry(@as(u32, @intFromPtr(&irq121)));
    idt_entries[122] = create_entry(@as(u32, @intFromPtr(&irq122)));
    idt_entries[123] = create_entry(@as(u32, @intFromPtr(&irq123)));
    idt_entries[124] = create_entry(@as(u32, @intFromPtr(&irq124)));
    idt_entries[125] = create_entry(@as(u32, @intFromPtr(&irq125)));
    idt_entries[126] = create_entry(@as(u32, @intFromPtr(&irq126)));
    idt_entries[127] = create_entry(@as(u32, @intFromPtr(&irq127)));
    idt_entries[128] = create_entry(@as(u32, @intFromPtr(&irq128)));
    idt_entries[129] = create_entry(@as(u32, @intFromPtr(&irq129)));
    idt_entries[130] = create_entry(@as(u32, @intFromPtr(&irq130)));
    idt_entries[131] = create_entry(@as(u32, @intFromPtr(&irq131)));
    idt_entries[132] = create_entry(@as(u32, @intFromPtr(&irq132)));
    idt_entries[133] = create_entry(@as(u32, @intFromPtr(&irq133)));
    idt_entries[134] = create_entry(@as(u32, @intFromPtr(&irq134)));
    idt_entries[135] = create_entry(@as(u32, @intFromPtr(&irq135)));
    idt_entries[136] = create_entry(@as(u32, @intFromPtr(&irq136)));
    idt_entries[137] = create_entry(@as(u32, @intFromPtr(&irq137)));
    idt_entries[138] = create_entry(@as(u32, @intFromPtr(&irq138)));
    idt_entries[139] = create_entry(@as(u32, @intFromPtr(&irq139)));
    idt_entries[140] = create_entry(@as(u32, @intFromPtr(&irq140)));
    idt_entries[141] = create_entry(@as(u32, @intFromPtr(&irq141)));
    idt_entries[142] = create_entry(@as(u32, @intFromPtr(&irq142)));
    idt_entries[143] = create_entry(@as(u32, @intFromPtr(&irq143)));
    idt_entries[144] = create_entry(@as(u32, @intFromPtr(&irq144)));
    idt_entries[145] = create_entry(@as(u32, @intFromPtr(&irq145)));
    idt_entries[146] = create_entry(@as(u32, @intFromPtr(&irq146)));
    idt_entries[147] = create_entry(@as(u32, @intFromPtr(&irq147)));
    idt_entries[148] = create_entry(@as(u32, @intFromPtr(&irq148)));
    idt_entries[149] = create_entry(@as(u32, @intFromPtr(&irq149)));
    idt_entries[150] = create_entry(@as(u32, @intFromPtr(&irq150)));
    idt_entries[151] = create_entry(@as(u32, @intFromPtr(&irq151)));
    idt_entries[152] = create_entry(@as(u32, @intFromPtr(&irq152)));
    idt_entries[153] = create_entry(@as(u32, @intFromPtr(&irq153)));
    idt_entries[154] = create_entry(@as(u32, @intFromPtr(&irq154)));
    idt_entries[155] = create_entry(@as(u32, @intFromPtr(&irq155)));
    idt_entries[156] = create_entry(@as(u32, @intFromPtr(&irq156)));
    idt_entries[157] = create_entry(@as(u32, @intFromPtr(&irq157)));
    idt_entries[158] = create_entry(@as(u32, @intFromPtr(&irq158)));
    idt_entries[159] = create_entry(@as(u32, @intFromPtr(&irq159)));
    idt_entries[160] = create_entry(@as(u32, @intFromPtr(&irq160)));
    idt_entries[161] = create_entry(@as(u32, @intFromPtr(&irq161)));
    idt_entries[162] = create_entry(@as(u32, @intFromPtr(&irq162)));
    idt_entries[163] = create_entry(@as(u32, @intFromPtr(&irq163)));
    idt_entries[164] = create_entry(@as(u32, @intFromPtr(&irq164)));
    idt_entries[165] = create_entry(@as(u32, @intFromPtr(&irq165)));
    idt_entries[166] = create_entry(@as(u32, @intFromPtr(&irq166)));
    idt_entries[167] = create_entry(@as(u32, @intFromPtr(&irq167)));
    idt_entries[168] = create_entry(@as(u32, @intFromPtr(&irq168)));
    idt_entries[169] = create_entry(@as(u32, @intFromPtr(&irq169)));
    idt_entries[170] = create_entry(@as(u32, @intFromPtr(&irq170)));
    idt_entries[171] = create_entry(@as(u32, @intFromPtr(&irq171)));
    idt_entries[172] = create_entry(@as(u32, @intFromPtr(&irq172)));
    idt_entries[173] = create_entry(@as(u32, @intFromPtr(&irq173)));
    idt_entries[174] = create_entry(@as(u32, @intFromPtr(&irq174)));
    idt_entries[175] = create_entry(@as(u32, @intFromPtr(&irq175)));
    idt_entries[176] = create_entry(@as(u32, @intFromPtr(&irq176)));
    idt_entries[177] = create_entry(@as(u32, @intFromPtr(&irq177)));
    idt_entries[178] = create_entry(@as(u32, @intFromPtr(&irq178)));
    idt_entries[179] = create_entry(@as(u32, @intFromPtr(&irq179)));
    idt_entries[180] = create_entry(@as(u32, @intFromPtr(&irq180)));
    idt_entries[181] = create_entry(@as(u32, @intFromPtr(&irq181)));
    idt_entries[182] = create_entry(@as(u32, @intFromPtr(&irq182)));
    idt_entries[183] = create_entry(@as(u32, @intFromPtr(&irq183)));
    idt_entries[184] = create_entry(@as(u32, @intFromPtr(&irq184)));
    idt_entries[185] = create_entry(@as(u32, @intFromPtr(&irq185)));
    idt_entries[186] = create_entry(@as(u32, @intFromPtr(&irq186)));
    idt_entries[187] = create_entry(@as(u32, @intFromPtr(&irq187)));
    idt_entries[188] = create_entry(@as(u32, @intFromPtr(&irq188)));
    idt_entries[189] = create_entry(@as(u32, @intFromPtr(&irq189)));
    idt_entries[190] = create_entry(@as(u32, @intFromPtr(&irq190)));
    idt_entries[191] = create_entry(@as(u32, @intFromPtr(&irq191)));
    idt_entries[192] = create_entry(@as(u32, @intFromPtr(&irq192)));
    idt_entries[193] = create_entry(@as(u32, @intFromPtr(&irq193)));
    idt_entries[194] = create_entry(@as(u32, @intFromPtr(&irq194)));
    idt_entries[195] = create_entry(@as(u32, @intFromPtr(&irq195)));
    idt_entries[196] = create_entry(@as(u32, @intFromPtr(&irq196)));
    idt_entries[197] = create_entry(@as(u32, @intFromPtr(&irq197)));
    idt_entries[198] = create_entry(@as(u32, @intFromPtr(&irq198)));
    idt_entries[199] = create_entry(@as(u32, @intFromPtr(&irq199)));
    idt_entries[200] = create_entry(@as(u32, @intFromPtr(&irq200)));
    idt_entries[201] = create_entry(@as(u32, @intFromPtr(&irq201)));
    idt_entries[202] = create_entry(@as(u32, @intFromPtr(&irq202)));
    idt_entries[203] = create_entry(@as(u32, @intFromPtr(&irq203)));
    idt_entries[204] = create_entry(@as(u32, @intFromPtr(&irq204)));
    idt_entries[205] = create_entry(@as(u32, @intFromPtr(&irq205)));
    idt_entries[206] = create_entry(@as(u32, @intFromPtr(&irq206)));
    idt_entries[207] = create_entry(@as(u32, @intFromPtr(&irq207)));
    idt_entries[208] = create_entry(@as(u32, @intFromPtr(&irq208)));
    idt_entries[209] = create_entry(@as(u32, @intFromPtr(&irq209)));
    idt_entries[210] = create_entry(@as(u32, @intFromPtr(&irq210)));
    idt_entries[211] = create_entry(@as(u32, @intFromPtr(&irq211)));
    idt_entries[212] = create_entry(@as(u32, @intFromPtr(&irq212)));
    idt_entries[213] = create_entry(@as(u32, @intFromPtr(&irq213)));
    idt_entries[214] = create_entry(@as(u32, @intFromPtr(&irq214)));
    idt_entries[215] = create_entry(@as(u32, @intFromPtr(&irq215)));
    idt_entries[216] = create_entry(@as(u32, @intFromPtr(&irq216)));
    idt_entries[217] = create_entry(@as(u32, @intFromPtr(&irq217)));
    idt_entries[218] = create_entry(@as(u32, @intFromPtr(&irq218)));
    idt_entries[219] = create_entry(@as(u32, @intFromPtr(&irq219)));
    idt_entries[220] = create_entry(@as(u32, @intFromPtr(&irq220)));
    idt_entries[221] = create_entry(@as(u32, @intFromPtr(&irq221)));
    idt_entries[222] = create_entry(@as(u32, @intFromPtr(&irq222)));
    idt_entries[223] = create_entry(@as(u32, @intFromPtr(&irq223)));
    idt_entries[224] = create_entry(@as(u32, @intFromPtr(&irq224)));
    idt_entries[225] = create_entry(@as(u32, @intFromPtr(&irq225)));
    idt_entries[226] = create_entry(@as(u32, @intFromPtr(&irq226)));
    idt_entries[227] = create_entry(@as(u32, @intFromPtr(&irq227)));
    idt_entries[228] = create_entry(@as(u32, @intFromPtr(&irq228)));
    idt_entries[229] = create_entry(@as(u32, @intFromPtr(&irq229)));
    idt_entries[230] = create_entry(@as(u32, @intFromPtr(&irq230)));
    idt_entries[231] = create_entry(@as(u32, @intFromPtr(&irq231)));
    idt_entries[232] = create_entry(@as(u32, @intFromPtr(&irq232)));
    idt_entries[233] = create_entry(@as(u32, @intFromPtr(&irq233)));
    idt_entries[234] = create_entry(@as(u32, @intFromPtr(&irq234)));
    idt_entries[235] = create_entry(@as(u32, @intFromPtr(&irq235)));
    idt_entries[236] = create_entry(@as(u32, @intFromPtr(&irq236)));
    idt_entries[237] = create_entry(@as(u32, @intFromPtr(&irq237)));
    idt_entries[238] = create_entry(@as(u32, @intFromPtr(&irq238)));
    idt_entries[239] = create_entry(@as(u32, @intFromPtr(&irq239)));
    idt_entries[240] = create_entry(@as(u32, @intFromPtr(&irq240)));
    idt_entries[241] = create_entry(@as(u32, @intFromPtr(&irq241)));
    idt_entries[242] = create_entry(@as(u32, @intFromPtr(&irq242)));
    idt_entries[243] = create_entry(@as(u32, @intFromPtr(&irq243)));
    idt_entries[244] = create_entry(@as(u32, @intFromPtr(&irq244)));
    idt_entries[245] = create_entry(@as(u32, @intFromPtr(&irq245)));
    idt_entries[246] = create_entry(@as(u32, @intFromPtr(&irq246)));
    idt_entries[247] = create_entry(@as(u32, @intFromPtr(&irq247)));
    idt_entries[248] = create_entry(@as(u32, @intFromPtr(&irq248)));
    idt_entries[249] = create_entry(@as(u32, @intFromPtr(&irq249)));
    idt_entries[250] = create_entry(@as(u32, @intFromPtr(&irq250)));
    idt_entries[251] = create_entry(@as(u32, @intFromPtr(&irq251)));
    idt_entries[252] = create_entry(@as(u32, @intFromPtr(&irq252)));
    idt_entries[253] = create_entry(@as(u32, @intFromPtr(&irq253)));
    idt_entries[254] = create_entry(@as(u32, @intFromPtr(&irq254)));
    idt_entries[255] = create_entry(@as(u32, @intFromPtr(&irq255)));

    // Load IDT
    const idt_address = pmm.allocate(@sizeOf(idtr));
    const idt = @as(*idtr, @ptrFromInt(idt_address));

    idt.size = idt_entries_size - 1;
    idt.offset = @as(u32, idt_entries_address);

    load_idt(@as(u32, idt_address));
}
