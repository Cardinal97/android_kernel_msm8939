#!/bin/bash


 ########################################################################
 ########################################################################
 #                                                                      #
 # Author: Dhinesh Ravi aka "Cardinal97" <dhinesh11201@gmail.com>       #
 #                                                                      #
 # Copyright © 2015                                                     #
 #                                                                      #
 # Kernel build automation script                                       #
 #                                                                      #
 # This software is licensed under the terms of the GNU General Public  #
 # License version 2, as published by the Free Software Foundation, and #
 # may be copied, distributed, and modified under those terms.          #
 #                                                                      #
 # This program is distributed in the hope that it will be useful,      #
 # but WITHOUT ANY WARRANTY; without even the implied warranty of       #
 # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the        #
 # GNU General Public License for more details.                         #
 #                                                                      #
 ########################################################################
 ########################################################################


# Constants

JOBLOAD=-j$(grep -c ^processor /proc/cpuinfo)
KERNEL_DIR=$PWD
KERNEL=$KERNEL_DIR/arch/arm64/boot/Image
FLASHABLE=$KERNEL_DIR/flashable
DTBTOOL=$KERNEL_DIR/dtbToolCM
DTIMG=$KERNEL_DIR/arch/arm64/boot/dt.img
DATE=$(date +"%y%m%d")



# Variables

KERNEL_NAME=
ARCHITECTURE=arm64
DEFCONFIG=cyanogenmod_tomato-64_defconfig
VENDOR=yu
DEVICE=tomato



# Export Variables

export CROSS_COMPILE=$HOME/toolchain/aarch64-linux-android-4.9/bin/aarch64-linux-android-
export ARCH=$ARCHITECTURE
export PATH="$PATH:/bin/"
export KBUILD_BUILD_USER="dhineshravi97"
export KBUILD_BUILD_HOST="Cardinal-Chaos"



# Colors

red='\033[0;31m'
green='\033[0;32m'
blue='\033[0;34m'
cyan='\033[0;36m'
purple='\033[0;35m'
yellow='\033[0;33m'
plain='\033[0m'



BUILD_START=$(date +"%s")



# The Cleaning Part
	
clean_directory () {

 if [ "$OPTION" == "clean" ]; then
 	CLEANDIR=y
 else
 	read -p "Clean kernel directory ? (y|n) : " CLEANDIR
 fi


 if [ "$CLEANDIR" == "y" ]; then
 	echo -e "$blue***************************************************"
	echo "***************************************************"
 	echo "*            Cleaning kernel directory            *"
	echo "***************************************************"
 	echo -e "***************************************************$plain"
	clean_source_files

 elif [ "$CLEANDIR" == "n" ]; then
	echo -e "$cyan Proceeding to build kernel $plain"

 else
	echo -e "$red Not a valid option! Enter a valid option! $plain"
	read -p "Clean kernel directory ? (y|n) : " CLEANDIR

 fi

}


clean_source_files() {

 make clean $JOBLOAD
 
 if [ -a $KERNEL_DIR/$KERNEL_NAME_*.zip ]; then
	rm $KERNEL_DIR/$KERNEL_NAME_*.zip
	
 fi
 
 clean_bkup

} 


clean_bkup() {

 read -p "Clean self generated backup files ? (y|n) : " BACKUP

 	if [ "$BACKUP" == "y" ]; then
 		find . -type f -name "*~" -exec rm -f {} \;
		find . -type f -name "*.rej" -exec rm -f {} \;
		clean_config

	elif [ "$BACKUP" == "n" ]; then
	 	clean_config

	else
	 	echo -e "$red Not a valid option! Enter a valid option! $plain"
		read -p "Clean self generated backup files ? (y|n) : " BACKUP

 	fi
	
}


clean_config() {

 read -p "Clean kernel defconfig ? (y|n) : " CLEANCONFIG

	if [ "$CLEANCONFIG" == "y" ]; then
	  	make mrproper

	directory_cleaned

 	elif [ "$CLEANCONFIG" == "n" ]; then
	 	directory_cleaned

 	else
	 	echo -e "$red Not a valid option! Enter a valid option! $plain"
	 	read -p "Clean kernel defconfig ? (y|n) : " CLEANCONFIG

 	fi

}


directory_cleaned () {

 if [ "$OPTION" == "clean" ]; then

	if [ "$BACKUP" == "y" ]; then

		if [ "$CLEANCONFIG" == "y" ]; then
			echo -e "$green Kernel directory cleaned completely $plain"

		else
			echo -e "$green Kernel directory cleaned $plain"

		fi

	else
		echo -e "$green Kernel directory cleaned $plain"

	fi

 else

	if [ "$BACKUP" == "y" ]; then

		if [ "$CLEANCONFIG" == "y" ]; then
			echo -e "$green Kernel directory cleaned completely $plain"
			echo -e "$cyan Proceeding to build kernel $plain"

		else
			echo -e "$green Kernel directory cleaned $plain"
			echo -e "$cyan Proceeding to build kernel $plain"

		fi

	else
		echo -e "$green Kernel directory cleaned $plain"
		echo -e "$cyan Proceeding to build kernel $plain"

	fi

 fi

}



# The Kernel Compilation Part

compile_kernel () {

 if ! [ -a $KERNEL_DIR/.config ]; then
	make $DEFCONFIG

 fi


 read -p "Wanna make a menu-driven kernel config UI ? (y|n) : " MENUCONFIG

	if [ "$MENUCONFIG" == "y" ]; then
		make menuconfig

	elif [ "$MENUCONFIG" == "n" ]; then
		:

	else
	 	echo -e "$red Not a valid option! Enter a valid option! $plain"
		read -p "Wanna make a menu driven kernel config UI ? (y|n) : " MENUCONFIG

	fi


 echo -e "$cyan******************************************"
 echo "******************************************"
 echo "*            Compiling Kernel            *"
 echo "******************************************"
 echo -e "******************************************$plain"

 make Image $JOBLOAD

 if [ -a $KERNEL ]; then
	echo -e "$green Profit :P ...Kernel compilation successfull... $plain"
	 cp $KERNEL $FLASHABLE/tools/zImage

 else
 	echo -e "$red Oopss :/ ...Kernel compilation unsuccessfull... $plain"
	exit 1

 fi

 make dtbs $JOBLOAD
 $DTBTOOL --force-v2 -o $DTIMG -s 2048 -p $KERNEL_DIR/scripts/dtc/ $KERNEL_DIR/arch/arm/boot/dts/
 cp $DTIMG $FLASHABLE/tools/dt.img

 make modules $JOBLOAD
 find . -name '*.ko' -exec cp {} $FLASHABLE/system/lib/modules/ \;
 $CROSS_COMPILE"strip" --strip-unneeded $FLASHABLE/system/lib/modules/*.ko

 make_flashable_zip

}



# The Flashable ZIP Part

make_flashable_zip () {

 echo -e "$blue**********************************************"
 echo "**********************************************"
 echo "*            Making Flashable ZIP            *"
 echo "**********************************************"
 echo -e "**********************************************$plain"

 cd $FLASHABLE
 zip -r "$KERNEL_NAME"Kernel_build-"$DATE"_"$ARCHITECTURE"_"$VENDOR"-"$DEVICE".zip .
 mv "$KERNEL_NAME"Kernel_build-"$DATE"_"$ARCHITECTURE"_"$VENDOR"-"$DEVICE".zip $KERNEL_DIR

 finally_done

}



# The End Card

finally_done() {

 rm $FLASHABLE/tools/zImage
 rm $FLASHABLE/tools/dt.img
 rm $FLASHABLE/system/lib/modules/*.ko

 echo -e "$green Everything OK! Flash it nd Enjoy ! $plain"

}



# Build options

build() {

 clean_directory
 compile_kernel

}


clean() {

 clean_directory

}


option_query() {

 read -p "Choose between the option to proceed (build|clean) : " OPTION

 if [ "$OPTION" == "build" ]; then
	build

 elif [ "$OPTION" == "clean" ]; then
	clean

 else
	echo -e "$red Not a valid option! Enter a valid option! $plain"
	read -p "Choose between the option to proceed (build|clean) : " OPTION

 fi

}



# Prior Interrogation Entry Cases


 if [ "$1" == "build" ]; then
	build

 elif [ "$1" == "clean" ]; then
	clean

 elif [ "$1" == "" ]; then
	option_query

 else
	echo -e "$red Not a valid option! Enter a valid option! $plain"
	option_query

 fi




BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))

 if [ "$(($DIFF / 60))" == 0 ]; then
	if [ "$(($DIFF % 60))" == 0 ]; then
		echo -e "$yellow Build completed in no time.$plain"

	elif [ "$(($DIFF % 60))" == 1 ]; then
		echo -e "$yellow Build completed in a second.$plain"
	
	else
		echo -e "$yellow Build completed in $(($DIFF % 60)) seconds.$plain"
	
	fi

 elif [ "$(($DIFF / 60))" == 1 ]; then
	if [ "$(($DIFF % 60))" == 0 ]; then
		echo -e "$yellow Build completed in a minute.$plain"

	elif [ "$(($DIFF % 60))" == 1 ]; then
		echo -e "$yellow Build completed in a minute and a second.$plain"
	
	else
		echo -e "$yellow Build completed in a minute and $(($DIFF % 60)) seconds.$plain"
	
	fi

 elif [ "$(($DIFF % 60))" == 0 ]; then
	echo -e "$yellow Build completed in $(($DIFF / 60)) minutes.$plain"

 elif [ "$(($DIFF % 60))" == 1 ]; then
	echo -e "$yellow Build completed in $(($DIFF / 60)) minutes and a second.$plain"

 else 
	echo -e "$yellow Build completed in $(($DIFF / 60)) minutes and $(($DIFF % 60)) seconds.$plain"

 fi
