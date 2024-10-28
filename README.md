# AsukaOS

![video example of AsukaOS's console](./assets/recording.mp4)

AsukaOS is a simple x86 operating system written in Zig 0.14.0-dev

# Building + Running

if you have `just` you can just run:

```sh
# build and run the OS in qemu (and clean up the iso and build dir)
just
# it also includes a helper task to download the correct version of Zig into a sub-folder
just download-zig
# and each step individually
# build the iso;
just mkiso
# build the iso and run qemu;
just qemu
# just build the Zig executable:
just build
# you can also run the equivalent in Zig directly:
zig build
zig build run
zig build make-iso
```

# Credits

- ![AnErrupTion/EeeOS](https://github.com/AnErrupTion/EeeOS)

- ![osdev](https://wiki.osdev.org)
