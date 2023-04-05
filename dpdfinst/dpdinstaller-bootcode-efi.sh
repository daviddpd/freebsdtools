#!/bin/sh
set -x
### DNS /etc/resolv.conf 

: ${dpdfinst_config_paths:="/etc /usr/local/etc /boot / ."}
: ${dpdfinst_config_file:="dpdfinst.conf"}

for p in ${dpdfinst_config_paths}; do
    if [ -f "${p}/${dpdfinst_config_file}" ]; then
        . ${p}/${dpdfinst_config_file}
    fi
done

if [ -n "${_CLI_CONFIG_FILE}" -a  -f "${_CLI_CONFIG_FILE}" ]; then
    . "${_CLI_CONFIG_FILE}"
fi


# ROOT_DISK_ZPOOL:  Type of zpool for the Root Disk.  Implemented types are:
#     zroot_stripe_rawdev
#     zroot_stripe_single
#     zroot_stripe_two_ssd_hd
#     zroot_mirror_two
#     zroot_raid10
#     zroot_raid50
#     usbboot_zroot_hwraid

: ${DRYRUN:=}
: ${ROOT_DISK_ZPOOL_NAME:="z"}
: ${DISK_ZPOOL_PROTECT_NAMES:=}
: ${ROOT_DISK_ZPOOL:="zroot_mirror_two"}

: ${ROOT_DISK_TYPE:=""}             # GEOM disk path
: ${ROOT_DISK_UNITS:=""}            # Gpart partition units/parts

: ${SKIP_DISKS:=""}                 # disks to skip/protect
: ${SYS_DISK_SSD:=""}               # detected SSD Disks
: ${SYS_DISK_HDD:=""}               # detected hard disk drives, spinning
: ${SYS_DISK_UMASS:=""}             # USB mass storage
: ${SYS_DISK_OTHER:=""}             # other storage devices

: ${GPTLABEL_NUMBERING:="serial"}   # count or serial : Simple incrementing count, rel to zero; 
                                    #   or the last 6 chars of the disks serial number.

: ${GPTLABELS:=""}                  # created gpt labels of new partitions or overrides, instead of globbing /dev/gpt/*
: ${GPTLABELS_NOGLOB:=1}            # created gpt labels of new partitions or overrides, instead of globbing /dev/gpt/*


: ${GPTPART_ALIGNMENT:="4K"}        # gpart alignment "-a " value.

: ${ROOT_PART_SIZE_EFI:="1024M"}    # EFI Partition Size
: ${ROOT_PART_SIZE_BOOT:="512k"}    # freebsd-boot partition size
: ${ROOT_PART_SIZE_SWAP:="8G"}      # partition for swap on root block devices
: ${ROOT_PART_SIZE_DATA:="-1"}
: ${ROOT_PART_SIZE_SLOG:=}
: ${ROOT_PART_SIZE_CACHE:=}
: ${ROOT_PART_SIZE_SLOG_STANDALONE:=}
: ${ROOT_PART_SIZE_CACHE_STANDALONE:=}

: ${ROOT_ON_USB:=0}
# : ${BOOTONLY_ON_USB:=0}


: ${ROOT_PART_SWAP:=1}              # create swap partition
: ${SWAP_ON_ZROOT:=0}               # boolean, create swap on the root zpool
: ${NO_SWAP_ON_SPINNING:=1}         # by default, don't create swap partitions on spinning disks, it's 2020 after all.

: ${ROOT_PART_SIZE_ZFS:=0}          # size of zroot vdev.  0=auto, use remaning space.
: ${DATA_PART_SIZE_ZFS:=0}          # unused, add a partition for "data" beyond the VDEV part for zroot
: ${BOOTCODE_SKIP:=}                # IFDEFNED,  do not install bootcode, pmbr and gptzfsboot 
: ${BOOTCODE_CONSOLE:="vidconsole"}             
                                    # IFDEFNED,  set the freebsd bootloader console.
                                    # console="comconsole,vidconsole"


: ${ZPOOL_RAIDZ:="1"}               # 1 OR 2 : RAIDZ 1 (RAID-5) or RAIDZ 2 (RAID-6)
: ${ZPOOL_RAIDZ1_NVEDS:="4"}        # NUMBER OF VDEVS NEEDS FOR RAIDZ 1
: ${ZPOOL_RAIDZ2_NVEDS:="5"}        # NUMBER OF VDEVS NEEDS FOR RAIDZ 2
: ${ZPOOL_VDEVS_RAW:=0}
: ${ZPOOL_VDEVS_ALLSSD:=0}
: ${ZPOOL_ASHIFT:=13}               # ashift is actually the binary exponent which represents sector size
                                    #    for example, setting ashift=9 means your sector size will be 2^9, or 512 bytes. 

                                    # vfs.zfs.max_auto_ashift: Max ashift used when optimizing for logical -> physical sector size on new top-level vdevs. (LEGACY)
                                    # vfs.zfs.min_auto_ashift: Min ashift used when creating new top-level vdev. (LEGACY)
                                    
                                    # vfs.zfs.vdev.max_auto_ashift: Maximum ashift used when optimizing for logical -> physical sector size on new top-level vdevs
                                    # vfs.zfs.vdev.min_auto_ashift: Minimum ashift used when creating new top-level vdevs

                                    # vfs.zfs.max_auto_ashift: 16
                                    # vfs.zfs.min_auto_ashift: 9
                                    # vfs.zfs.vdev.max_auto_ashift: 16
                                    # vfs.zfs.vdev.min_auto_ashift: 9

                                    # ashift=12, 4k 
                                    # ashift=13, 8k 
                                    # ashift=14, 16k 

: ${REMOTE_RELEASE_HTTP:=}
: ${REMOTE_SCRIPTS_HTTP:=}
: ${REMOTE_CONFD_HTTP:=}
: ${REMOTE_PKG_URL:=}       # Obsolete 
: ${REMOTE_CUSTOM_REPOS:=}  # space delimited of repo files 



: ${NO_INSTALL:=}       # IFDEFNED, don't do any os install
: ${INSTALL_DEBUG:=}        # IFDEFNED, install the dbg.txz packages 
: ${INSTALL_PORTS:=}        # IFDEFNED, install /usr/ports 
: ${INSTALL_SRC:=1}         # IFDEFNED, install /usr/src



: ${DESTDIR:="/mnt/${ROOT_DISK_ZPOOL_NAME}"}        # DESTDIR, -R/altroot=
: ${DESTDIR2:="/mnt/${ROOT_DISK_ZPOOL_NAME}2"}  # DESTDIR, -R/altroot=
: ${TMPDIR:="/tmp/finsttmp"}    # tmp directory.


# Networking 

: ${NIC:=}
: ${IP:=}
: ${NETMASK:=}
: ${ROUTE_DEFAULT:=}
: ${HOSTNAME:=}
: ${SERIAL:=}
: ${MACS:=}
: ${NICS:=`ifconfig -l ether`}

: ${UUID:=}
: ${VENDOR:=}
: ${IS_BHYVE:=0}
: ${IS_XEN:=0}

: ${PKG_SET:=}
: ${PKG_INSTALLER:=}
: ${ADMIN_CONFIG:=}
: ${USER_PROVISION:=}
: ${ROOT_PASSWORD_HASH:='$6$OmI7uzlMns./sU22$AoVrDLcwzmetPzI1wi8/19j/3U6gl5iJImc6SfjRB4wS1NCISXmgon4AwObzbbP1aMfycGdLOW2Ne7EdDKHRi/'} # abcd1234
: ${RCD_ENABLES:=""}

: ${CONFIGS:=}

_EFI_COUNT=0
_GPTBOOT_COUNT=0
_DATA_COUNT=0
_SWAP_COUNT=0
_ROOT_COUNT=0
_CACHE_COUNT=0
_SLOG_COUNT=0
_vdevs=


ROOT_PART_SIZE_ZFS="62G"
ROOT_PART_SIZE_SWAP="64G" 
ROOT_PART_SIZE_SLOG_STANDALONE="64G"
ROOT_PART_SIZE_CACHE_STANDALONE="256G"
SYS_DISK_HDD="da1 da2 da3 da4 da5"
GPTLABEL_NUMBERING="count"
DESTDIR=""



if [ -n "${BOOTCODE_SKIP}" ]; then
    for d in ${SYS_DISK_SSD} ${SYS_DISK_HDD} ${SYS_DISK_UMASS}; do
        if [ -e "/dev/${d}p2" ]; then 
            cmd="gpart bootcode -b ${DESTDIR}/boot/pmbr -p ${DESTDIR}/boot/gptzfsboot -i 2 ${d}"
            if [ -z "${DRYRUN}" ]; then
                ${cmd}
            else
                echo "${cmd}"
            fi
        fi
        _cur_efipart="/dev/${d}p1"
        if [ -e "${_cur_efipart}" ]; then       

            _tmpfile=`mktemp`
            chmod 755 ${_tmpfile}
            
            echo "#!/bin/sh" >> ${_tmpfile}
            echo "set -x" >> ${_tmpfile}
            echo "newfs_msdos -F 32 -c 1 ${_cur_efipart}" >> ${_tmpfile}
            echo "mkdir -p /mnt/efimnt " >> ${_tmpfile}
            echo "mount -t msdosfs ${_cur_efipart} /mnt/efimnt" >> ${_tmpfile}
            echo "mkdir -p /mnt/efimnt/EFI/BOOT" >> ${_tmpfile}
            echo "cp -v ${DESTDIR}/boot/loader.efi /mnt/efimnt/EFI/BOOT/BOOTX64.efi" >> ${_tmpfile}
            if [ ${DRYRUN} ]; then
                cat ${_tmpfile}
            else
                ${_tmpfile}
            fi
            rm -f ${_tmpfile}
            umount -f /mnt/efimnt
        fi
    done
fi


