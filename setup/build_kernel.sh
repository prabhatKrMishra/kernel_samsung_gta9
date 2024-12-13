#!/bin/bash

ROOT_PATH=$(pwd)
BUILD_DIRECTORY=$ROOT_PATH/kernel
SOURCE_DIRECTORY=$ROOT_PATH/kernel-5.10
OUTPUT_DIRECTORY=../out
MODULES_DIRECTORY=$OUTPUT_DIRECTORY/modules
MODULES_LIST=$SOURCE_DIRECTORY/setup/stock/system/"module.list"
MODULES_LIST_VENDOR=$SOURCE_DIRECTORY/setup/stock/vendor/"modules.list"

handle_arguments() {
    case "$1" in
        --new)
            SKIP_MRPROPER=0
            rm -rf $OUTPUT_DIRECTORY
            mkdir -p $OUTPUT_DIRECTORY
            ;;
        --rebuild)
            SKIP_MRPROPER=1
            ;;
        *)
            echo "Invalid option: $1"
            echo "Usage: $0 --new | --rebuild"
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

cd $BUILD_DIRECTORY
./build/build.sh

copy_modules() {
    rm -rf "$MODULES_DIRECTORY"
    mkdir "$MODULES_DIRECTORY"
    mv $OUTPUT_DIRECTORY/*.ko "$MODULES_DIRECTORY"
}

select_modules() {
	if [ -z "$(ls -A "$MODULES_DIRECTORY")" ]; then
	  echo "Modules does not exist in $COMPILED_MODULES_DIR"
	else
	  COMPILED_MODULES_DIR=$MODULES_DIRECTORY
	  DEST_DIR=$OUTPUT_DIRECTORY/selected_modules
	  
	  rm -rf "$DEST_DIR"
	  mkdir -p "$DEST_DIR"
	  
	  while IFS= read -r module; do
	    if [ -f "$COMPILED_MODULES_DIR/$module" ]; then
	        mv "$COMPILED_MODULES_DIR/$module" "$DEST_DIR"
	    else
	        echo "Module $module does not exist in $COMPILED_MODULES_DIR"
	    fi
	  done < "$MODULES_LIST"
	  cp $OUTPUT_DIRECTORY/staging/lib/modules/5.10*/modules.alias $DEST_DIR
	  cp $OUTPUT_DIRECTORY/staging/lib/modules/5.10*/modules.softdep $DEST_DIR
	fi
}

select_modules_vendor() {
	if [ -z "$(ls -A "$MODULES_DIRECTORY")" ]; then
	  echo "Modules does not exist in $COMPILED_MODULES_DIR"
	else
	  COMPILED_MODULES_DIR=$MODULES_DIRECTORY
	  DEST_DIR=$OUTPUT_DIRECTORY/selected_modules_vendor
	  
	  rm -rf "$DEST_DIR"
	  mkdir -p "$DEST_DIR"
	  
	  while IFS= read -r module; do
	    if [ -f "$COMPILED_MODULES_DIR/$module" ]; then
	        mv "$COMPILED_MODULES_DIR/$module" "$DEST_DIR"
	    else
	        echo "Module $module does not exist in $COMPILED_MODULES_DIR"
	    fi
	  done < "$MODULES_LIST_VENDOR"
	  cp $OUTPUT_DIRECTORY/staging/lib/modules/5.10*/modules.alias $DEST_DIR
	  cp $OUTPUT_DIRECTORY/staging/lib/modules/5.10*/modules.softdep $DEST_DIR
	fi
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

# Check if 'arch/arm64/boot/Image' exists
if [ -f $OUTPUT_DIRECTORY/kernel-5.10/arch/arm64/boot/Image ]; then
    echo ''
    echo " Kernel build successful! "
    echo " Proceeding with copying modules."
    copy_modules
    select_modules
    select_modules_vendor
    #echo " Proceeding with generating dtb"
    #create_dtb
    echo ''
    echo ' Done!'
    echo ''
else
    echo ''
    echo " Kernel build failed !"
    echo ''
fi

