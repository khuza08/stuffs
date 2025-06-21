#!/bin/bash

# konfigurasi var
DEFCONFIG="elektra_defconfig"
ZIPNAME="elektra-trinket.zip"
KERNEL_OUT="out"
ANYKERNEL_DIR="../anykernel"
THREADS=$(nproc)
CLANG_DIR="/home/huza/aosp-clang-android15" 

clear

echo -e "\e[33m[Bersih-bersih build lama]\e[0m"
rm -rf "$KERNEL_OUT"
rm -f $ANYKERNEL_DIR/*.dtb $ANYKERNEL_DIR/Image*

# aospclang
export PATH="$CLANG_DIR/bin:$PATH"
export LD_LIBRARY_PATH="$CLANG_DIR/lib:$LD_LIBRARY_PATH"

export ARCH=arm64
export SUBARCH=arm64
export CC="ccache clang"
export LD="ld.lld"
export AR="llvm-ar"
export NM="llvm-nm"
export OBJCOPY="llvm-objcopy"
export OBJDUMP="llvm-objdump"
export STRIP="llvm-strip"
export CROSS_COMPILE="aarch64-linux-gnu-"
export CROSS_COMPILE_ARM32="arm-linux-gnueabi-"
export LLVM=1
export LLVM_IAS=1
export KCFLAGS="-Wno-error=vla -Wno-vla-extension -Wno-incompatible-library-redeclaration"
export KBUILD_BUILD_USER="huza"
export KBUILD_BUILD_HOST="archlinux"
export USE_CCACHE=1
export CCACHE_DIR=~/.ccache

#  output dir
mkdir -p "$KERNEL_OUT"

# build info
echo -e "\e[34m[INFO] Menggunakan Clang: $(clang --version | head -n1)\e[0m"
echo -e "\e[34m[INFO] Defconfig: $DEFCONFIG\e[0m"
echo -e "\e[34m[INFO] Output dir: $KERNEL_OUT\e[0m"

# konfigurasi kernel
make O="$KERNEL_OUT" "$DEFCONFIG" || { echo -e "\e[31mGagal make defconfig!\e[0m"; exit 1; }

# build kernel
echo -e "\e[32m[BUILD] Mulai kompilasi kernel...\e[0m"
START_TIME=$(date +%s)
make -j"$THREADS" O="$KERNEL_OUT" \
    CC="$CC" LD="$LD" AR="$AR" NM="$NM" \
    OBJCOPY="$OBJCOPY" OBJDUMP="$OBJDUMP" STRIP="$STRIP" \
    CROSS_COMPILE="$CROSS_COMPILE" \
    CROSS_COMPILE_ARM32="$CROSS_COMPILE_ARM32" \
    KCFLAGS="$KCFLAGS" \
    LLVM=1 LLVM_IAS=1 \
    2>&1 | tee build.log

BUILD_RESULT=$?
END_TIME=$(date +%s)
BUILD_DURATION=$((END_TIME - START_TIME))

if [[ $BUILD_RESULT -ne 0 ]]; then
    echo -e "\e[31m[ERROR] Build gagal! Lihat build.log untuk detail.\e[0m"
    exit 1
fi

# cek hasil build, zipping
if [[ -f "$KERNEL_OUT/arch/arm64/boot/Image.gz-dtb" ]]; then
    echo -e "\e[32m[SUKSES] Kernel berhasil dibuild dalam $((BUILD_DURATION/60))m $((BUILD_DURATION%60))s\e[0m"
    cp "$KERNEL_OUT/arch/arm64/boot/Image.gz-dtb" "$ANYKERNEL_DIR/"

    if [[ -f "$KERNEL_OUT/arch/arm64/boot/dtbo.img" ]]; then
        cp "$KERNEL_OUT/arch/arm64/boot/dtbo.img" "$ANYKERNEL_DIR/"
    fi
    cd "$ANYKERNEL_DIR" || exit 1
    zip -r9 "$ZIPNAME" * > /dev/null
    echo -e "\e[32m[ZIP] Kernel berhasil dikemas: $ZIPNAME\e[0m"
    echo -e "\e[34m[INFO] Kernel ZIP: $(realpath "$ZIPNAME")\e[0m"
else
    echo -e "\e[31m[ERROR] Hasil kernel (Image.gz-dtb) tidak ditemukan!\e[0m"
    exit 1
fi
