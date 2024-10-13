const std = @import("std");

pub fn run_executable(alloc: std.mem.Allocator, args: [][]const u8) void {
    // the command to run
    const proc = try std.process.Child.run(.{
        .allocator = alloc,
        .argv = &args,
    });

    // on success, we own the output streams
    defer alloc.free(proc.stdout);
    defer alloc.free(proc.stderr);

    const term = proc.term;

    try std.testing.expectEqual(term, std.ChildProcess.Term{ .Exited = 0 });
}

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    var disabled_features = std.Target.Cpu.Feature.Set.empty;
    var enabled_features = std.Target.Cpu.Feature.Set.empty;

    disabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.mmx));
    disabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.sse));
    disabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.sse2));
    disabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.avx));
    disabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.avx2));
    enabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.soft_float));

    const target_query = std.Target.Query{
        .cpu_arch = std.Target.Cpu.Arch.x86,
        .os_tag = std.Target.Os.Tag.freestanding,
        .abi = std.Target.Abi.none,
        .cpu_features_sub = disabled_features,
        .cpu_features_add = enabled_features,
    };

    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    // const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "asuka-os",
        .root_source_file = b.path("src/main.zig"),
        .target = b.resolveTargetQuery(target_query),
        .optimize = optimize,
        .code_model = .kernel,
    });

    exe.setLinkerScript(b.path("src/linker.ld"));
    exe.addAssemblyFile(b.path("src/asm/entry.s"));
    exe.addAssemblyFile(b.path("src/asm/helpers.s"));

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    // add step to check if our executables header is correct
    // const grub = b.addSystemCommand(&.{ "grub-file", "--is-x86-multiboot" });
    // const exe_path = b.path("zig-out/bin/asuka-os");
    // grub.addFileArg(exe_path);
    // grub.expectExitCode(0);

    // b.getInstallStep().dependOn(&grub.step);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    // run_step.dependOn(&grub.step);

    const make_iso_step = b.step("make-iso", "Create a bootable ISO image");
    make_iso_step.makeFn = make_iso;
    make_iso_step.dependOn(b.getInstallStep());

    run_step.makeFn = run;
    run_step.dependOn(make_iso_step);
}

// fn make_iso(self: *std.Build.Step, progress: std.Progress.Node) !void {
fn make_iso(self: *std.Build.Step, opts: std.Build.Step.MakeOptions) anyerror!void {
    _ = self;
    _ = opts;

    const current_dir = std.fs.cwd();
    current_dir.makeDir("iso") catch {};

    var isoDirectory = current_dir.openDir("iso", std.fs.Dir.OpenDirOptions{}) catch unreachable;
    defer isoDirectory.close();

    current_dir.copyFile("limine/limine-bios-cd.bin", isoDirectory, "limine-bios-cd.bin", .{}) catch unreachable;
    current_dir.copyFile("limine/limine-bios.sys", isoDirectory, "limine-bios.sys", .{}) catch unreachable;
    current_dir.copyFile("limine/limine.cfg", isoDirectory, "limine.cfg", .{}) catch unreachable;
    current_dir.copyFile("zig-out/bin/asuka-os", isoDirectory, "asuka.elf", .{ .override_mode = 0o777 }) catch unreachable;

    const xorriso_argv = [_][]const u8{
        "xorriso",
        "-as",
        "mkisofs",
        "-b",
        "limine-bios-cd.bin",
        "-no-emul-boot",
        "-boot-load-size",
        "4",
        "-boot-info-table",
        "iso",
        "-o",
        "asuka-os.iso",
    };

    var xor = std.process.Child.init(&xorriso_argv, std.heap.page_allocator);
    try xor.spawn();
    const term = try xor.wait();

    try std.testing.expectEqual(term, std.process.Child.Term{ .Exited = 0 });

    // const limine_deploy_argv = [_][]const u8{
    //     "limine/limine",
    //     "bios-install",
    //     "asuka-os.iso",
    // };
    //
    // var proc = std.process.Child.init(&limine_deploy_argv, std.heap.page_allocator);
    // try proc.spawn();
    // const res = try proc.wait();
    // try std.testing.expectEqual(res, std.process.Child.Term{ .Exited = 0 });
}

fn run(self: *std.Build.Step, opts: std.Build.Step.MakeOptions) anyerror!void {
    // fn run(self: *std.Build.Step, progress: std.Progress.Node) !void {
    _ = self;
    _ = opts;

    const qemu_argv = [_][]const u8{
        "qemu-system-i386",
        "-cpu",
        "pentium2",
        "-m",
        "256M", // or 128M
        "-cdrom",
        "asuka-os.iso",
    };

    var qemu = std.process.Child.init(&qemu_argv, std.heap.page_allocator);
    try qemu.spawn();
    _ = try qemu.wait();
}
