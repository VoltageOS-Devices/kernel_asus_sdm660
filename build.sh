#!/bin/bash

#set -e

## Copy this script inside the kernel directory
KERNEL_DEFCONFIG=X00TD_defconfig
ANYKERNEL3_DIR=$PWD/AnyKernel3/
FINAL_KERNEL_ZIP=Zeus-X00T-$(date '+%Y%m%d').zip
export PATH="$HOME/trb_clang/bin:$PATH"
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_COMPILER_STRING="$($HOME/trb_clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"

if ! [ -d "$HOME/trb_clang" ]; then
echo "trb_clang not found! Cloning..."
if ! git clone https://gitlab.com/varunhardgamer/trb_clang --depth=1 --single-branch ~/trb_clang; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi

# Speed up build process
MAKE="./makeparallel"

BUILD_START=$(date +"%s")
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

# Clean build always lol
echo "**** Cleaning ****"
rm -rf Zeus*.zip
mkdir -p out
make O=out clean

echo "**** Kernel defconfig is set to $KERNEL_DEFCONFIG ****"
echo -e "$blue***********************************************"
echo "          BUILDING KERNEL          "
echo -e "***********************************************$nocol"
make $KERNEL_DEFCONFIG O=out
make -j$(nproc --all) O=out LLVM=1\
		ARCH=arm64 \
		AS="$HOME/trb_clang/bin/llvm-as" \
		CC="$HOME/trb_clang/bin/clang" \
		LD="$HOME/trb_clang/bin/ld.lld" \
		AR="$HOME/trb_clang/bin/llvm-ar" \
		NM="$HOME/trb_clang/bin/llvm-nm" \
		STRIP="$HOME/trb_clang/bin/llvm-strip" \
		OBJCOPY="$HOME/trb_clang/bin/llvm-objcopy" \
		OBJDUMP="$HOME/trb_clang/bin/llvm-objdump" \
		CLANG_TRIPLE=aarch64-linux-gnu- \
		CROSS_COMPILE="$HOME/trb_clang/bin/clang" \
                CROSS_COMPILE_COMPAT="$HOME/trb_clang/bin/clang" \
                CROSS_COMPILE_ARM32="$HOME/trb_clang/bin/clang"

echo "**** Kernel Compilation Completed ****"
echo "**** Verify Image.gz-dtb ****"
ls $PWD/out/arch/arm64/boot/Image.gz-dtb

# Anykernel 3 time!!
echo "**** Verifying AnyKernel3 Directory ****"
ls $ANYKERNEL3_DIR
echo "**** Removing leftovers ****"
rm -rf $ANYKERNEL3_DIR/Image.gz-dtb
rm -rf $ANYKERNEL3_DIR/$FINAL_KERNEL_ZIP

echo "**** Copying Image.gz-dtb ****"
cp $PWD/out/arch/arm64/boot/Image.gz-dtb $ANYKERNEL3_DIR/

echo "**** Time to zip up! ****"
cd $ANYKERNEL3_DIR/
zip -r9 "../$FINAL_KERNEL_ZIP" * -x README $FINAL_KERNEL_ZIP

echo "**** Done, here is your sha1 ****"
cd ..
rm -rf $ANYKERNEL3_DIR/$FINAL_KERNEL_ZIP
rm -rf $ANYKERNEL3_DIR/Image.gz-dtb
rm -rf out/

sha1sum $FINAL_KERNEL_ZIP

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo -e "$yellow Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol"

echo "**** Uploading your zip now ****"
		curl -sL https://git.io/file-transfer | sh
                ./transfer wet $FINAL_KERNEL_ZIP
