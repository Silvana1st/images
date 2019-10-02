#!/bin/bash

CENTOS_BOOT_ISO=http/boot.iso
CENTOS_URL=http://mirrors.ukfast.co.uk/sites/ftp.centos.org/7/os/x86_64/images/boot.iso

echo -e "\nPlease select which image to create...\n"
echo -e "\n1) Juan (Code Aster & Code Saturn)"
echo -e "\n2) MAD (Mongo DB, Apache Spark and Django)"
echo -e "\n3) R"
echo -e "\n4) VNC (TigerVNC)"
echo -e "\n5) Base"
echo -e ""
read -p "Selection: " selection

case "$selection" in
	1)
		MAIN_NAME="centos7-juan"
		PACKAGES="base-nogui.sh vagrant.sh juan.sh cleanup.sh"
		;;
	2)
		MAIN_NAME="centos7-mad"
		PACKAGES="base-nogui.sh vagrant.sh MAD.sh cleanup.sh"
		;;
	3)
		MAIN_NAME="centos7-r"
		PACKAGES="base-nogui.sh vagrant.sh cleanup.sh R.sh"
		;;
	4)
		MAIN_NAME="centos7-vnc"
		PACKAGES="base-nogui.sh vagrant.sh tigervnc.sh"
		;;
	5)
		MAIN_NAME="centos7-base"
		PACKAGES="base-nogui.sh vagrant.sh"
		;;
	esac

echo -e "\n\nMain name is $MAIN_NAME"

#exec >> docker-master.log
#exec 2>&1

MAIN_KS=$MAIN_NAME.ks
MAIN_ISO=$MAIN_NAME.iso
MAIN_ISO_FQ=/var/tmp/$MAIN_ISO
MAIN_LOG=$MAIN_NAME.log
MAIN_TAR=$MAIN_NAME.tar
INPUT_KS=http/centos7.ks
SCRIPT_DIR=scripts
SAVED_IMAGES=../saved_images/docker

echo -e "\n\nDownloading Centos Boot ISO, if required...\n"
CENTOS_ISO=$CENTOS_BOOT_ISO
CENTOS_HTTP=$CENTOS_URL

if [ ! -f $CENTOS_ISO ]; then
	wget $CENTOS_HTTP -P ./http
fi

echo -e "\n\nCreating Kickstart File $MAIN_KS"

sed '/\@core$/d' $INPUT_KS > $MAIN_KS
sed -i 's/\%packages.*/& --nocore/g' $MAIN_KS

sed -i '0,/\%end/s//bind-utils\nbash\nyum\nvim-minimal\ncentos-release\nless\n\-kernel\*\n\-\*firmware\n\-os\-prober\n\-gettext\*\n\-bind\-license\n\-freetype\niputils\niproute\nsystemd\nrootfiles\n\-libteam\n\-teamd\ntar\npasswd\n\%end/' $MAIN_KS

sed -i '$ d' $MAIN_KS

for i in $PACKAGES;
do
	echo -e "\n\n###  Script $i  ###" >> $MAIN_KS
	tail -n +2 $SCRIPT_DIR/$i >> $MAIN_KS
done

echo "%end" >> $MAIN_KS

echo -e "\nRemove old version of ISO ($MAIN_ISO) due to be created?"
rm -i $MAIN_ISO_FQ

echo -e "\nStarting ISO creation"
livemedia-creator --make-iso --iso=$CENTOS_BOOT_ISO --ks=$MAIN_KS --image-name=$MAIN_ISO --logfile=$MAIN_LOG --keep-image

echo -e "\nCreating TAR file required for Docker import"
echo -e "/bin/virt-tar-out -a $MAIN_ISO_FQ / $MAIN_TAR"
/bin/virt-tar-out -a $MAIN_ISO_FQ / $MAIN_TAR

echo -e "\nDealing with Docker!"
docker rm `docker ps -a | grep $MAIN_NAME | cut -c1-12`
docker rmi $MAIN_NAME
cat $MAIN_TAR | docker import - $MAIN_NAME

echo -e "\nCleaning Up"
rm -f $MAIN_ISO_FQ
mkdir -p $SAVED_IMAGES
mv $MAIN_TAR $SAVED_IMAGES/.
