#!/bin/bash
# Original : https://raw.githubusercontent.com/Microsoft/linux-vm-tools/master/arch/install-config.sh
# taken from kali-tweaks
###############################################################################

# are you ROOT?
if [ "$(id -u)" -ne 0 ]; then
    echo 'This script must be run with root privileges' >&2
    exit 1
fi

# Update our machine to the latest code if we need to.
apt update && apt upgrade -y

# is reboot needed after update
if [ -f /var/run/reboot-required ]; then
    echo "A reboot is required in order to proceed with the install." >&2
    echo "Please reboot and re-run this script to finish the install." >&2
    exit 1
fi

###############################################################################
# Install XRDP
#
apt install -y xrdp

###############################################################################
# Configure XRDP
#
systemctl enable xrdp
systemctl enable xrdp-sesman

### Configure the ini and config files.
## /etc/xrdp/xrdp.ini
# use vsock transport.
sed -i_orig -e 's/use_vsock=false/use_vsock=true/g' /etc/xrdp/xrdp.ini
sed -i_orig -e 's/port=3389/port=vsock:\/\/-1:3389/g' /etc/xrdp/xrdp.ini
# use rdp security.
sed -i_orig -e 's/security_layer=negotiate/security_layer=rdp/g' /etc/xrdp/xrdp.ini
# remove encryption validation.
sed -i_orig -e 's/crypt_level=high/crypt_level=none/g' /etc/xrdp/xrdp.ini
# disable bitmap compression since its local its much faster
sed -i_orig -e 's/bitmap_compression=true/bitmap_compression=false/g' /etc/xrdp/xrdp.ini
sed -n -e 's/max_bpp=32/max_bpp=24/g' /etc/xrdp/xrdp.ini

## /etc/xrdp/sesman.ini
sed -i_orig -e 's/X11DisplayOffset=10/X11DisplayOffset=0/g' /etc/xrdp/sesman.ini
# rename the redirected drives to 'shared-drives'
sed -i_orig -e 's/FuseMountName=thinclient_drives/FuseMountName=shared-drives/g' /etc/xrdp/sesman.ini

# Change the allowed_users
echo "allowed_users=anybody" > /etc/X11/Xwrapper.config


#Ensure hv_sock gets loaded
if [ ! -e /etc/modules-load.d/hv_sock.conf ]; then
	echo "hv_sock" > /etc/modules-load.d/hv_sock.conf
fi

# Configure the policy xrdp session
cat > /etc/polkit-1/localauthority/50-local.d/45-allow-colord.pkla <<EOF
[Allow Colord all Users]
Identity=unix-user:*
Action=org.freedesktop.color-manager.create-device;org.freedesktop.color-manager.create-profile;org.freedesktop.color-manager.delete-device;org.freedesktop.color-manager.delete-profile;org.freedesktop.color-manager.modify-device;org.freedesktop.color-manager.modify-profile
ResultAny=no
ResultInactive=no
ResultActive=yes
EOF

# gdm3 support (experiment)
#if [ -e /etc/gdm3/daemon.conf ]; then
#	sed -i_orig -e 's/#WaylandEnable=false/WaylandEnable=false/g' /etc/gdm3/daemon.conf
#fi

###############################################################################
# .xinitrc has to be modified manually.
#
#echo "exec gnome-session" > ~/.xinitrc
#echo "exec startxfce4" > ~/.xinitrc
echo "exec mate-session" > ~/.xinitrc exec mate-session
#echo "You will have to configure .xinitrc to start your windows manager, see https://wiki.archlinux.org/index.php/Xinit"
echo "Reboot your machine to begin using XRDP."

#####
# if you get cannot get name of dbus session add this to... and are using mate...
# /etc/X11/Xsession.d/99mate-environment (number might not be diff)
# may have to do it manually, since you will not have cut/paste w/o enhanced session
# unset DBUS_SESSION_BUS_ADDRESS