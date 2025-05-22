#!/bin/bash

ROOT_PATH=$(pwd)
BUILD_DIRECTORY=$ROOT_PATH/kernel
SOURCE_DIRECTORY=$ROOT_PATH/kernel-5.10
OUTPUT_DIRECTORY=../out
MODULES_DIRECTORY=$OUTPUT_DIRECTORY/modules
VENDOR_BOOT_MODULES_LIST=$SOURCE_DIRECTORY/setup/moduleslist/vendor_boot/"modules.list"
VENDOR_DLKM_MODULES_LIST=$SOURCE_DIRECTORY/setup/moduleslist/vendor_dlkm/"modules.list"

handle_arguments() {
    case "$1" in
        --new)
            SKIP_MRPROPER=0
            SKIP_DEFCONFIG=0
            rm -rf $OUTPUT_DIRECTORY
            mkdir -p $OUTPUT_DIRECTORY
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

rm -rf $OUTPUT_DIRECTORY/modules

cd $SOURCE_DIRECTORY ;
python scripts/gen_build_config.py --kernel-defconfig gta9_00_defconfig --kernel-defconfig-overlays "entry_level.config ot11.config ot11_data.config ot11_wifi.config" -m user -o $OUTPUT_DIRECTORY/build.config

export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-android-
export CROSS_COMPILE_COMPAT=arm-linux-gnueabi-
export OUT_DIR=$OUTPUT_DIRECTORY
export DIST_DIR=$OUTPUT_DIRECTORY
export BUILD_CONFIG=$OUTPUT_DIRECTORY/build.config
export KERNEL_BUILD_MODE="user"

if [ "$SKIP_MRPROPER" -eq 1 ]; then
    export SKIP_MRPROPER=1
fi

if [ "$SKIP_DEFCONFIG" -eq 1 ]; then
    export SKIP_DEFCONFIG=1
fi

cd $BUILD_DIRECTORY
./build/build.sh

copy_modules() {
    echo "========================================================"
    echo " Proceeding with copying modules."
    rm -rf "$MODULES_DIRECTORY"
    mkdir "$MODULES_DIRECTORY"
    mv $OUTPUT_DIRECTORY/*.ko "$MODULES_DIRECTORY"
}

rename_modules() {
    echo " Renaming vendor modules."
    mv "$MODULES_DIRECTORY/mtk_fpsgo.ko" "$MODULES_DIRECTORY/fpsgo.ko"
    echo " mtk_fpsgo.ko ==> fpsgo.ko"
    mv "$MODULES_DIRECTORY/mali_mgm_mt6789.ko" "$MODULES_DIRECTORY/mali_mgm.ko"
    echo " mali_mgm_mt6789.ko ==> mali_mgm.ko"
    mv "$MODULES_DIRECTORY/mali_prot_alloc_mt6789.ko" "$MODULES_DIRECTORY/mali_prot_alloc.ko"
    echo " mali_prot_alloc_mt6789.ko ==> mali_prot_alloc.ko"
}

select_modules_vendor_boot() {
	echo " Selecting vendor_boot modules"
	if [ -z "$(ls -A "$MODULES_DIRECTORY")" ]; then
	  echo "Modules does not exist in $COMPILED_MODULES_DIR"
	else
	  COMPILED_MODULES_DIR=$MODULES_DIRECTORY
	  DEST_DIR=$OUTPUT_DIRECTORY/vendor_boot_modules
	  
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
	  DEST_DIR=$OUTPUT_DIRECTORY/vendor_dlkm_modules
	  
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

create_dtb_img() {
    DIST_DIR=${OUTPUT_DIRECTORY}/gen_dtb
    rm -rf ${DIST_DIR}
    mkdir -p ${DIST_DIR}

    BASE_DIRS=(
        mediatek
    )

    for BASE_DIR in "${BASE_DIRS[@]}"; do
        DIR_PATH="${OUTPUT_DIRECTORY}/kernel-5.10/arch/arm64/boot/dts/${BASE_DIR}"
        if [ -d "$DIR_PATH" ]; then
            DTB_FILES=$(find "$DIR_PATH" -name "*.dtb")
            for FILE in $DTB_FILES; do
                cp "$FILE" "${DIST_DIR}/"
            done
        else
            echo "Directory $DIR_PATH does not exist!"
        fi
    done

    DTB_FILE_LIST=$(find ${DIST_DIR} -name "*.dtb" | sort)
    cat $DTB_FILE_LIST > ${OUTPUT_DIRECTORY}/kernel-5.10/arch/arm64/boot/dtb
    rm -rf $DIST_DIR
}

# Check if 'arch/arm64/boot/Image.gz' exists
if [ -f $OUTPUT_DIRECTORY/kernel-5.10/arch/arm64/boot/Image.gz ]; then
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
    #create_dtb
    echo ''
    echo " KERNEL binary is ready in $OUTPUT_DIRECTORY/kernel-5.10/arch/arm64/boot/Image"
    echo " MDULES are ready in $OUTPUT_DIRECTORY/vendor_boot_modules & $OUTPUT_DIRECTORY/vendor_dlkm_modules"
    echo ''
else
    echo ''
    echo " Kernel build failed !"
    echo ''
fi

