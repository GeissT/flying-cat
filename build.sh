echo "Kernel Compilation:"
echo "    -   Assembling bootloader..."
nasm -i "kernel_src/" -f bin -o kernelbin/loader.o kernelsrc/loader.asm

echo "    -   Compiling kernel..."
gcc -o kernelbin/kernel.o -c kernelsrc/kernel.c -nostdlib -nostartfiles -nodefaultlibs #-masm=intel

echo "    -   Linking..."
#ld -T kernel_src/linker.ld -o kernel_bin/os.bin kernel_bin/loader.o kernel_bin/kernel.o
ld -o kernelbin/os.bin kernelbin/loader.o kernelbin/kernel.o

echo "Creating bootdisk image:"
echo "    -   Creating floppy image"
bin/pad floppy.img 0 1474560 > /dev/null
echo "    -   Formatting to FAT"
mkfs -t vfat floppy.img

echo "Done."
