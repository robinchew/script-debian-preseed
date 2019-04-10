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
create_folder () {
# Create folder isoorig and isonew
echo -e "${G}Creating folder for mounting ISO${N}"
mkdir isoorig
mount -o loop -t iso9660 /home/robin/debian-9.8.0-i386-xfce-CD-1.iso isoorig
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
create_preseed () {
printf "#### Contents of the preconfiguration file  \
\nd-i debian-installer/locale select en_AU \
\nd-i console-keymaps-at/keymap select us \
\nd-i keyboard-configuration/xkb-keymap select us \
\nd-i netcfg/choose_interface select auto \
\nd-i netcfg/get_hostname string useless \
\nd-i netcfg/get_domain string local \
\nd-i netcfg/hostname string myhostanme \
\nd-i netcfg/disable_autoconfig boolean true \
\nd-i netcfg/get_ipaddress string 192.168.1.9 \
\nd-i netcfg/get_netmask string 255.255.255.0 \
\nd-i netcfg/get_gateway string 192.168.1.1 \
\nd-i netcfg/get_nameservers string 192.168.1.1 \
\nd-i netcfg/confirm_static booleaan true \

\n# Any hostname and domain names assigned from dhcp take precedence over values set here. However, setting the values still prevents the questions from being shown \
\n# even if values come from dhcp. \
\n#Force hostname to DHCP \
\n## IPv4 example \
\n# If non-free firmware is needed for the network or other hardware, you can \
\n# configure the installer to always try to load it, without prompting. Or \
\n# change to false to disable asking. \
\nd-i hw-detect/load_firmware boolean true \
\n# The wacky dhcp hostname that some ISPs use as a password of sorts. \
\n#d-i netcfg/dhcp_hostname string radish \
\nd-i time/zone string Australia/Perth \

\nd-i clock-setup/ntp boolean false \

\nd-i partman-auto/init_automatically_partition select biggest_free \
\nd-i partman-auto/disk string /dev/sda \
\nd-i partman-auto/method string regular \
\nd-i partman-auto/choose_recipe select atomic \
\nd-i partman/choose_partition select finish \
\nd-i partman/confirm boolean true \
\nd-i partman/confirm_nooverwrite boolean true \
\nd-i partman-partitioning/confirm_write_new_label boolean true \

\nd-i apt-setup/use_mirror boolean false \
\npopularity-contest popularity-contest/participate boolean false \
\ntasksel tasksel/first multiselect standard \

\nd-i grub-installer/only_debian boolean true \
\nd-i grub-installer/bootdev  string default \

\nd-i finish-install/reboot_in_progress note \

\nd-i passwd/user-fullname string Pos Admin \
\nd-i passwd/username string user1 \
\nd-i passwd/user-password password userp \
\nd-i passwd/user-password-again password userp \
\nd-i passwd/root-password password r00tme \
\nd-i passwd/root-password-again password r00tme" \
> preseed.cfg
ls -alh
}
create_iso () {
xorriso	-as mkisofs -o isoname.iso \
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
create_folder
edit_path_select
edit_auto_select
create_preseed
md5sum $(find -follow -type f) > md5sum.txt
cd -
create_iso
umount isoorig
rm -r isoorig
rm -r isonew
echo "Custom ISO created"
