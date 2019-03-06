#!/bin/bash
R="\e[31m"
G="\e[32m"
N="\e[0m"
Y="\e[93m"
isopath=$1

### Function ###
check_SUDO () {
if [[ $(id -u) != 0 ]]; then 
		echo -e "${R}Please use the script as root${N}"
		exit 1 
fi
}
check_OPTION () {
case $1 in
	-h)
		echo -e "${Y}You can put the path of the ISO at 1st argument of the script${N}"
		echo ""
		echo "Option            Meaning"
		echo "-h                Show this help"
		echo "-clean            Delete folder isoorig and isonew"
		exit
		;;
	-clean)
		echo -e "${Y}Deleting isoorig and isonew${N}"
		umount isoorig
		rm -r isoorig
		rm -r isonew
		exit
		;;
	*)
		:
esac
}
check_PACKAGES () {
if [[ ! -z $(which apt-get) ]]; then
                INSTALLER="apt-get"
                PKG_CHECK="dpkg-query -s"
		echo "Packages installer is APT-GET"
fi
}
check_packages () {
for i in rsync xorriso isolinux sed; do
	if [[ $($PKG_CHECK $i) ]] 2>&-; then
		echo -e "${G}OK${N} $i";
	else
		echo -e "${R}Not OK${N} $i"
		echo -e "${Y}Installing $i${N}"
		$INSTALLER install $i
	fi
done
}
check_file () {
until [[ -f $isopath ]] && [[ $isopath != "" ]]; do
	echo "Your iso could not be found"
	read -p "ISO path:" isopath
done
}
create_folder () {
# Create folder isoorig and isonew
echo -e "${G}Creating folder for mounting ISO${N}"
mkdir isoorig
mount -o loop -t iso9660 $isopath isoorig
echo -e "${G}Copying ISO in isonew to allow write permission${N}"
mkdir isonew
rsync -a -H -exclude=TRANS.TBL --chmod=u+rwx isoorig/ isonew
}
edit_path_select () {
echo -e "${G}Entering isonew to edit ISO${N}" 
# Output architecture
ARCHITECT2=$(echo isoorig/install.*)
ARCHITECT=${ARCHITECT2##*.}
cd ./isonew # Enter folder isonew

if [[ -f isolinux/txt.cfg ]]; then
sed -i "1ilabel netinstall \
\n	menu label ^Install Over SSH \
\n	menu default \
\n	kernel /install.$ARCHITECT/vmlinuz \
\n	append auto=true vga=788 file=/cdrom/preseed.cfg initrd=/install.$ARCHITECT/initrd.gz locale=en_US console-keymaps-at/keymap=us" \
isolinux/txt.cfg
else
	echo -e "${R}isolinux/txt.cfg not found${N}"
	exit 1
fi
}
edit_auto_select () {
for a in isolinux.cfg  prompt.cfg; do
	if  [[ -f ./isolinux/$a ]]; then
		sed -i "s/timeout 0/timeout 4/" isolinux/isolinux.cfg
		sed -i "s/timeout 0/timeout 4/" isolinux/prompt.cfg
	else
		echo -e "${R}$a not found${N}"
		exit 1
	fi
done
}
check_LANG1 () {
	until [[ $LANG1 != "" ]]; do
		echo -e "${R}Can't be empty${N}"
		read -p "Choose installation language (en_US, fr_FR,...):" LANG1
	done
}
check_KEYMAP2 () {
	until [[ $KEYMAP2 != "" ]]; do
		echo -e "${R}Can't be empty${N}"
		read -p "Choose keymap:" KEYMAP2
	done
}
check_YOURHOSTNAME () {
	until [[ $YOURHOSTNAME != "" ]]; do
		echo -e "${R}Can't be empty${N}"
		read -p "Choose Hostname:" YOURHOSTNAME
	done
}
check_YOURIP () {
	until [[ $YOURIP != "" ]]; do
		echo -e "${R}Can't be empty${N}"
		read -p "Choose IP for SSH (usually 192.168.1.XX):" YOURIP
	done
}
check_GATEWAY () {
	until [[ $GATEWAY != "" ]]; do
		echo -e "${R}Can't be empty${N}"
		read -p "Choose IP for GATEWAY (usallly 192.168.1.1):" GATEWAY
	done
}
check_DNS () {
	until [[ $DNS != "" ]]; do
		echo -e "${R}Can't be empty${N}"
		read -p "Choose IP for NAMESERVER (usally 192.168.1.1):" DNS
	done
}
check_YOURPASS () {
	until [[ $YOURPASS != "" ]]; do
		echo -e "${R}Can't be empty${N}"
		read -p "Choose PASSWORD for SSH installation:" YOURPASS
	done
}
check_EVERYTHING () {
	printf "%-12s %s\n" Language $LANG1 Keymap $KEYMAP2 Hostname $YOURHOSTNAME Ip $YOURIP Gateway $GATEWAY DNS $DNS Pass $YOURPASS
	echo -e "${R}Is that correct ?${N} (Choose a number)"
	select ANSWER1 in "Yes" "No"; do
		case $ANSWER1 in
			Yes ) :; break;;
			No ) echo "Exiting script"; exit;;

		esac
	done
}
create_preseed () {
printf "#### Contents of the preconfiguration file  \
\n#### Contents of the preconfiguration file  \
\n### Localization  \
\n# Locale sets language and country.  \
\nd-i debian-installer/locale select $LANG1  \
\n# Keyboard selection. \
\nd-i console-keymaps-at/keymap select $KEYMAP2 \
\nd-i keyboard-configuration/xkb-keymap select $KEYMAP2 \
\n### Network configuration \
\n# netcfg will choose an interface that has link if possible. This makes it skip displaying a list if there is more than one interface. \
\nd-i netcfg/choose_interface select auto \
\n# Any hostname and domain names assigned from dhcp take precedence over values set here. However, setting the values still prevents the questions from being shown \
\n# even if values come from dhcp. \
\nd-i netcfg/get_hostname string useless \
\nd-i netcfg/get_domain string local \
\n#Force hostname to DHCP \
\nd-i netcfg/hostname string $YOURHOSTNAME \
\n# If you prefer to configure the network manually, uncomment this line and the static network configuration below. \
\nd-i netcfg/disable_autoconfig boolean true \
\n## IPv4 example \
\nd-i netcfg/get_ipaddress string $YOURIP \
\nd-i netcfg/get_netmask string 255.255.255.0 \
\nd-i netcfg/get_gateway string $GATEWAY \
\nd-i netcfg/get_nameservers string $DNS \
\nd-i netcfg/confirm_static booleaan true \
\n# If non-free firmware is needed for the network or other hardware, you can \
\n# configure the installer to always try to load it, without prompting. Or \
\n# change to false to disable asking. \
\nd-i hw-detect/load_firmware boolean true \
\n# The wacky dhcp hostname that some ISPs use as a password of sorts. \
\n#d-i netcfg/dhcp_hostname string radish \
\nd-i preseed/early_command string anna-install network-console \
\n# Setup ssh password, login=installer \
\nd-i network-console/password password $YOURPASS \
\nd-i network-console/password-again password $YOURPASS" \
> preseed.cfg
}
create_iso () {
	until [[ $YOURISO != "" ]]; do
		echo -e "${R}Can't be empty${N}"
		read -p "Choose your ISO name:" YOURISO
	done
xorriso	-as mkisofs -o $YOURISO.iso \
	-isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
	-c isolinux/boot.cat -b isolinux/isolinux.bin -no-emul-boot \
	-boot-load-size 4 -boot-info-table isonew
}
### End function ###

### Start script ###
echo ""
echo "Preseed script for making a custom ISO of Debian. Installing it through SSH "
check_SUDO
check_OPTION $1
check_PACKAGES
check_packages
check_file
create_folder
edit_path_select
edit_auto_select
check_LANG1
check_KEYMAP2
check_YOURHOSTNAME
check_YOURIP
check_GATEWAY
check_DNS
check_YOURPASS
check_EVERYTHING
create_preseed
md5sum $(find -follow -type f) > md5sum.txt
cd -
create_iso
umount isoorig
rm -r isoorig
rm -r isonew
echo "Custom ISO created"
