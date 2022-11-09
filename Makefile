CC := clang
LD := lld
ARCH ?= x86-64

ifeq ($(ARCH),x86-64)
include x86-64.env
else
include aarch64.env
endif

export

SRCS := main.c clib.c io.c loader.c config.c log.c kernel.c

default: all

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

hello.efi: main_helloworld.o
	$(LD) $(LDFLAGS) $^ -out:$@

boot.efi: clib.o io.o loader.o config.o log.o main.o
	$(LD) $(LDFLAGS) $^ -out:$@

kernel.elf: kernel.c
	$(CC) $(KERNEL_CFLAGS) -c $< -o kernel.o
	$(LD) $(KERNEL_LDFLAGS) kernel.o -o $@

qemu-image-hello: hello.efi
	dd if=/dev/zero of=flash0.img bs=1M count=64
	dd if=/usr/share/qemu-efi-$(ARCH)/QEMU_EFI.fd of=flash0.img conv=notrunc
	dd if=/dev/zero of=flash1.img bs=1M count=64
	mkdir -p root/efi/boot
	cp hello.efi root/efi/boot/bootaa64.efi

qemu-run-hello: qemu-image-hello
	qemu-system-aarch64 -m 1024 -cpu cortex-a72 -M virt -drive if=pflash,format=raw,file=flash0.img -drive if=pflash,format=raw,file=flash1.img -drive format=raw,file=fat:rw:root -net none -nographic

-include $(SRCS:.c=.d)

.PHONY: clean all default

all: boot.efi kernel.elf

clean:
	rm -rf *.efi *.elf *.o *.d *.lib

# Run hello world EFI app:  ARCH=aarch64 make qemu-run-hello
