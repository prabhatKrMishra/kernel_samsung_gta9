#!/bin/bash

ROOT_PATH=$(pwd)
BUILD_DIRECTORY=$ROOT_PATH/kernel
SOURCE_DIRECTORY=$ROOT_PATH/kernel-5.10
OUTPUT_DIRECTORY=out
OUTPUT_DIRECTORY_PATH=$ROOT_PATH/out
MODULES_DIRECTORY=$OUTPUT_DIRECTORY_PATH/modules
VENDOR_BOOT_MODULES_LIST=$SOURCE_DIRECTORY/setup/moduleslist/vendor_boot/"modules.list"
VENDOR_DLKM_MODULES_LIST=$SOURCE_DIRECTORY/setup/moduleslist/vendor_dlkm/"modules.list"

handle_arguments() {
    case "$1" in
        --new)
            SKIP_MRPROPER=0
            SKIP_DEFCONFIG=0
            rm -rf $OUTPUT_DIRECTORY_PATH
            mkdir -p $OUTPUT_DIRECTORY_PATH
            ;;
        --rebuild)
            SKIP_MRPROPER=1
            SKIP_DEFCONFIG=0
            ;;
        --modules)
            SKIP_MRPROPER=1
            SKIP_DEFCONFIG=1
            ;;
        *)
            echo "Invalid option: $1"
            echo "Usage: $0 --new | --rebuild | --modules"
            exit 1
            ;;
    esac
}

handle_arguments "$1"

rm -rf $OUTPUT_DIRECTORY_PATH/modules

cd $SOURCE_DIRECTORY ;
python scripts/gen_build_config.py --kernel-defconfig gta9_00_defconfig --kernel-defconfig-overlays "entry_level.config ot11.config ot11_data.config ot11_wifi.config" -m user -o ../$OUTPUT_DIRECTORY/build.config

export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-android-
export CROSS_COMPILE_COMPAT=arm-linux-gnueabi-
export OUT_DIR=../$OUTPUT_DIRECTORY
export DIST_DIR=../$OUTPUT_DIRECTORY
export BUILD_CONFIG=../$OUTPUT_DIRECTORY/build.config
export KERNEL_BUILD_MODE=user

if [ "$SKIP_MRPROPER" -eq 1 ]; then
    export SKIP_MRPROPER=1
fi

if [ "$SKIP_DEFCONFIG" -eq 1 ]; then
    export SKIP_DEFCONFIG=1
fi

cd $BUILD_DIRECTORY
./build/build.sh LLVM_IAS=1 -j$(($(nproc) - 1))

copy_modules() {
    echo "========================================================"
    echo " Proceeding with copying modules."
    rm -rf "$MODULES_DIRECTORY"
    mkdir "$MODULES_DIRECTORY"
    mv $OUTPUT_DIRECTORY_PATH/*.ko "$MODULES_DIRECTORY"
}

rename_modules() {
    echo " Renaming vendor modules."
    mv "$MODULES_DIRECTORY/mtk_fpsgo.ko" "$MODULES_DIRECTORY/fpsgo.ko"
    echo " mtk_fpsgo.ko ==> fpsgo.ko"
}

select_modules_vendor_boot() {
	echo " Selecting vendor_boot modules"
	if [ -z "$(ls -A "$MODULES_DIRECTORY")" ]; then
	  echo "Modules does not exist in $COMPILED_MODULES_DIR"
	else
	  COMPILED_MODULES_DIR=$MODULES_DIRECTORY
	  DEST_DIR=$OUTPUT_DIRECTORY_PATH/vendor_boot_modules

	  rm -rf "$DEST_DIR"
	  mkdir -p "$DEST_DIR"

	  while IFS= read -r module; do
	    if [ -f "$COMPILED_MODULES_DIR/$module" ]; then
	        cp "$COMPILED_MODULES_DIR/$module" "$DEST_DIR"
	    else
	        echo " vendor_boot_modules: Module $module does not exist in $COMPILED_MODULES_DIR"
	    fi
	  done < "$VENDOR_BOOT_MODULES_LIST"
	fi
}

select_modules_vendor_dlkm() {
	echo " Selecting vendor_dlkm modules"
	if [ -z "$(ls -A "$MODULES_DIRECTORY")" ]; then
	  echo "Modules does not exist in $COMPILED_MODULES_DIR"
	else
	  COMPILED_MODULES_DIR=$MODULES_DIRECTORY
	  DEST_DIR=$OUTPUT_DIRECTORY_PATH/vendor_dlkm_modules

	  rm -rf "$DEST_DIR"
	  mkdir -p "$DEST_DIR"

	  while IFS= read -r module; do
	    if [ -f "$COMPILED_MODULES_DIR/$module" ]; then
	        cp "$COMPILED_MODULES_DIR/$module" "$DEST_DIR"
	    else
	        echo " vendor_dlkm_modules: Module $module does not exist in $COMPILED_MODULES_DIR"
	    fi
	  done < "$VENDOR_DLKM_MODULES_LIST"
	fi
	echo "========================================================"
}

copy_binaries() {
	echo " Copying kernel binaries"
	KERNEL_BINARY_DIR=$OUTPUT_DIRECTORY_PATH/kernel-5.10/arch/arm64/boot
	KERNEL_DTB_DIR=$OUTPUT_DIRECTORY_PATH/kernel-5.10/arch/arm64/boot/dts/mediatek

	cp "$KERNEL_BINARY_DIR/Image.gz" "$OUTPUT_DIRECTORY_PATH"
	cp "$KERNEL_DTB_DIR/mt6789.dtb" "$OUTPUT_DIRECTORY_PATH/dtb"
	cp "$KERNEL_DTB_DIR/mt8781_gta9_eur_open_00.dtbo" "$OUTPUT_DIRECTORY_PATH/dtbo"
}

# Check if 'arch/arm64/boot/Image.gz' exists
if [ -f $OUTPUT_DIRECTORY_PATH/kernel-5.10/arch/arm64/boot/Image.gz ]; then
    echo ''
    echo " Kernel build successful! "
    echo ''
    copy_modules
    echo ''
    rename_modules
    echo ''
    select_modules_vendor_boot
    echo ''
    select_modules_vendor_dlkm
    #echo " Proceeding with generating dtb"
    echo ''
    copy_binaries
    echo ''
    echo " KERNEL binary file is ready as out/Image.gz"
    echo " DTB binary file is ready as out/dtb"
    echo " DTBO binary file is ready as out/dtbo"
    echo " VENDOR_BOOT modules are ready in out/vendor_boot_modules"
    echo " VENDOR_DLKM modules are ready in out/vendor_dlkm_modules"
    echo ''
else
    echo ''
    echo " Kernel build failed !"
    echo ''
fi

