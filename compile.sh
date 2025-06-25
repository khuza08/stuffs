#!/bin/bash
# elektra build script
# khzx 2k25

# configuration
DATE="$(date +%d%m%y)"
DEFCONFIG="elektra_defconfig"
ZIPNAME="elektra-trinket-$DATE.zip"
KERNEL_OUT="out"
ANYKERNEL_DIR="../anykernel"
THREADS=$(nproc)
CLANG_DIR="/home/huza/aosp-clang-r547379"
BUILD_LOG="build.log"

# cleanup
clear
echo -e "\e[33m[🧹] Membersihkan build sebelumnya...\e[0m"
rm -rf "$KERNEL_OUT"
rm -f $ANYKERNEL_DIR/{*.dtb,Image*,*.img}
rm -f "$BUILD_LOG" || true
rm -f /home/huza/repo/kernel/anykernel/*zip

# clang setup
echo -e "\e[34m[⚙️] Menyiapkan environment Clang...\e[0m"
export PATH="$CLANG_DIR/bin:$PATH"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-}:$CLANG_DIR/lib"
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

# out dir
mkdir -p "$KERNEL_OUT"

# build info
echo -e "\e[36m[ℹ️] Clang: $(clang --version | head -n1)"
echo -e "Defconfig: $DEFCONFIG"
echo -e "Output: $KERNEL_OUT\e[0m"
echo -e "\e[35m[⚙️] Membuat defconfig...\e[0m"

# kernel build
make O="$KERNEL_OUT" "$DEFCONFIG"
echo -e "\e[32m[🔨] Memulai kompilasi kernel...\e[0m"
START_TIME=$(date +%s)

# build time
END_TIME=$(date +%s)
BUILD_DURATION=$((END_TIME - START_TIME))
echo -e "\e[32m[✅] Build sukses ($((BUILD_DURATION/60))m $((BUILD_DURATION%60))s)\e[0m"

# verify build
KERNEL_IMAGE="$KERNEL_OUT/arch/arm64/boot/Image.gz-dtb"
if [[ ! -f "$KERNEL_IMAGE" ]]; then
    echo -e "\e[31m[❌] File kernel tidak ditemukan: $KERNEL_IMAGE\e[0m"
    exit 1
fi

# packaging
echo -e "\e[36m[📦] Mempersiapkan paket kernel...\e[0m"
cp "$KERNEL_IMAGE" "$ANYKERNEL_DIR/"
DTBO_IMAGE="$KERNEL_OUT/arch/arm64/boot/dtbo.img"
if [[ -f "$DTBO_IMAGE" ]]; then
    cp "$DTBO_IMAGE" "$ANYKERNEL_DIR/"
fi

# zipping
cd "$ANYKERNEL_DIR" || exit 1
if ! zip -r9 "$ZIPNAME" * > zip.log; then
    echo -e "\e[31m[❌] Gagal membuat ZIP package!"
    echo "Lihat log: $ANYKERNEL_DIR/zip.log\e[0m"
    exit 1
fi

echo -e "\e[32m[📦] Kernel berhasil dikemas: $(realpath "$ZIPNAME")\e[0m"
echo -e "\e[32m[🎉] Build selesai!\e[0m"
