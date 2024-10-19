default:
    just run && just clean

build:
    zig build

run:
    zig build run

mkiso:
    zig build make-iso

download-zig:
    #!/usr/bin/env bash
    printf "\e[32m%s\e[0m\n" "[ DOWNLOADING ZIG 14.0 ]"
    curl -fsSl https://ziglang.org/builds/zig-linux-$(uname -m)-0.14.0-dev.1860+2e2927735.tar.xz | tar xvfJ -
    mkdir -p bin
    ln -sf `pwd`/zig-linux-x86_64-0.14.0-dev.1860+2e2927735/zig bin/zig
    printf "\e[32m%s\e[0m\n" "[ DONE ] Add $(pwd)/bin to PATH"
    # [ -d zig-linux-x86_64-0.14.0-dev.1860+2e2927735 ] && rm -r zig-linux-x86_64-0.14.0-dev.1860+2e2927735

clean:
    #!/usr/bin/env bash
    [ -d ./iso ] && rm -r ./iso
    [ -f ./asuka-os.iso ] && rm ./asuka-os.iso
    # [ -d zig-linux-x86_64-0.14.0-dev.1860+2e2927735 ] && rm -r zig-linux-x86_64-0.14.0-dev.1860+2e2927735

qemu:
    qemu-system-i386 -cpu pentium2 -m 256M -cdrom asuka-os.iso

# outdated from grub to limine switch
__all:
    just
    just grub-config
    just iso
    just qemu

__iso:
    mkdir -p iso/boot/grub
    cp zig-out/bin/asuka-os iso/boot/kernel.elf
    cp grub.cfg iso/boot/grub/grub.cfg
    grub-mkrescue -o asuka-os.iso iso

__grub-config:
    #!/usr/bin/env bash
    cat<<EOF > grub.cfg
    menuentry "Zig Bare Bones" {
        multiboot /boot/kernel.elf
    }
    EOF
