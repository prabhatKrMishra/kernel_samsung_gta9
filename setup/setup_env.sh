#!/bin/bash

# Create a master folder
# Inside master folder clone using below command:
# git clone https://github.com/prabhatKrMishra/kernel_samsung_X115.git kernel-5.10
# Run setup_env.sh
# Done !

TOP_DIRECTORY="../.."

cp -r vendor $TOP_DIRECTORY/vendor
cp -r kernel $TOP_DIRECTORY/kernel
cp build_kernel.sh $TOP_DIRECTORY/build_kernel.sh
mkdir $TOP_DIRECTORY/out
cd $TOP_DIRECTORY/kernel

