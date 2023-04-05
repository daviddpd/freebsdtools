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

http_fetch() 
{
    _OBJ=$1
    _DIR=$2
    _REMOTE=$3
    if [ -z "${_DIR}" ]; then
        _DIR="${TMPDIR}"
    fi
    if [ -z "${_REMOTE}" ]; then
        _REMOTE=$REMOTE_RELEASE_HTTP
    fi  
    if [ ! -f "${_DIR}/${_OBJ}" ]; then
        fetch -o ${_DIR}/${_OBJ} ${_REMOTE}/${_OBJ}
    fi
}


get_system_config_worker()
{
    if [ "$1" ]; then
        http_fetch ${1} ${TMPDIR} ${REMOTE_CONFD_HTTP}
        if [ -f "${TMPDIR}/${1}" ]; then
            CONFIGS="${CONFIGS} ${TMPDIR}/${1}"
        fi
    fi
}

# get_system_config
#
# This works like pxelinux.cfg naming conventions
# but only full MACs and UUIDs, not partial. 
#

get_system_config()
{

    SERIAL=`kenv -q smbios.system.serial`
    MACS=`ifconfig -a -f ether:dash | grep ether | awk '{print "00-"$2}' | sort | xargs`    
    UUID=`sysctl -n kern.hostuuid`
    VENDOR=`kenv -q smbios.bios.vendor`
    if [ "${VENDOR}" = 'BHYVE' ]; then
        IS_BHYVE=1
    elif [ "${VENDOR}" = 'Xen' ]; then
        IS_XEN=1
    fi
      
    for c in defaults ${VENDOR} ${SERIAL} ${MACS} ${UUID}; do
        get_system_config_worker $c
    done
}

_SWAP_MIRRORS_NUM=0


get_glabel_vdevs() 
{
    labelstr="$1"
    vdevs=""
    echo "GPTLABELS : ${GPTLABELS}"
    if [ ${GPTLABELS_NOGLOB} -eq 1 ]; then
        for label in ${GPTLABELS}; do
            echo $label | grep ${labelstr}
            if [ $? -eq 0 ]; then
                vdevs="$vdevs $label"
            fi
        done
    else
        vdevs=`/bin/ls -1 /dev/gpt/${labelstr}* | xargs`
    fi

    _vdevs="$vdevs"
    
}

create_swapmirrors()
{
    vdevs=$@
    i=0
    sn=0
    swap_mirror=
    for swapdisk in ${vdevs}; do
        i=$((i+1))
        swap_mirror="${swap_mirror} ${swapdisk}"
        if [ $i -eq 2 ]; then
            gmirror label swap${sn} ${swap_mirror}
            sn=$((sn+1))
            swap_mirror=
            i=0;
        fi
    done            

}

gpart_destroy()
{
    d="$1"
    cmd="gpart destroy -F ${d}"
    if [ -n "${DRYRUN}" ]; then
        echo ${cmd}
    else
        ${cmd}
    fi
}
gpart_create()
{
    d="$1"
    cmd="gpart create -s GPT ${d}"
    if [ -n "${DRYRUN}" ]; then
        echo ${cmd}
    else
        ${cmd}
    fi
}

#gpart_add(dev, partition_type, partition_number, size, zfstype)
gpart_add()
{
    dev=$1
    ptype=$2
    pnum=$3
    psize=$4
    zfstype=$5

    gptlabel=
    lnum=
    snum=`cat /var/run/dmesg.boot | grep ^${dev}: | grep 'Serial Number' | head -1 | awk '{print $4}' | rev | cut -c 1-6 | rev`
    
    case "${ptype}" in
        efi)
            gptlabel="efi"
            lnum=$_EFI_COUNT
            _EFI_COUNT=$((_EFI_COUNT+1))
        ;;
        freebsd-boot)
            gptlabel="gptboot"
            lnum=$_GPTBOOT_COUNT
            _GPTBOOT_COUNT=$((_GPTBOOT_COUNT+1))
        ;;
        freebsd-swap)
            gptlabel="swap"
            lnum=$_SWAP_COUNT
            _SWAP_COUNT=$((_SWAP_COUNT+1))
        ;;
        freebsd-zfs)
            case ${zfstype} in
                root)
                    gptlabel="root"
                    lnum=$_ROOT_COUNT
                    _ROOT_COUNT=$((_ROOT_COUNT+1))
                ;;
                cache)
                    gptlabel="cache"
                    lnum=$_CACHE_COUNT
                    _CACHE_COUNT=$((_CACHE_COUNT+1))
                ;;
                slog)
                    gptlabel="slog"
                    lnum=$_SLOG_COUNT
                    _SLOG_COUNT=$((_SLOG_COUNT+1))
                ;;
                *)
                    gptlabel="data"
                    lnum=$_DATA_COUNT
                    _DATA_COUNT=$((_DATA_COUNT+1))
                ;;
            esac
        ;;
        *)
            echo
            echo "ERROR: I'm not programmed for that partition type. ${ptype}"
            echo
            exit 1
        ;;        
    esac 
    if [ "x${psize}" = "x0" ]; then
        psize=
    else
        psize="-s ${psize}"
    fi
    
    if [ "${GPTLABEL_NUMBERING}" = "serial" ]; then
        num="-${snum}"
        if [ -e "/dev/gpt/${gptlabel}${num}"  ]; then
            snum=`dmesg | grep ^${dev}: | grep 'Serial Number' | head -1 | awk '{print $4}' | rev | cut -c 1-12 | rev`
            num="-${snum}"
        fi
    elif [ "${GPTLABEL_NUMBERING}" = "count" ]; then
        num=${lnum}
    else 
        num=${lnum}
    fi
    
    cmd="gpart add -a ${GPTPART_ALIGNMENT} -t ${ptype} ${psize} -i ${pnum} -l ${gptlabel}${num} ${dev}"
    echo "Set GPTLABELS:  ${gptlabel}${num}"
    GPTLABELS="${GPTLABELS} /dev/gpt/${gptlabel}${num}"
    echo "Set GPTLABELS now: ${GPTLABELS}"
    if [ -n "${DRYRUN}" ]; then
        echo ${cmd}
    else
        ${cmd}
    fi
    
}

zroot_mirror_two()
{

    ZROOT_MIRROR_VDEVS=
    SWAP_MIRROR_VDEVS=
    _DISKS=${SYS_DISK_HDD}
    
    for d in ${_DISKS}; do
        gpart_destroy ${d}
        gpart_create ${d}
        gpart_add ${d} "efi" 1 "${ROOT_PART_SIZE_EFI}"
        gpart_add ${d} "freebsd-boot" 2 "${ROOT_PART_SIZE_BOOT}"
        if [  "${ROOT_PART_SWAP}" -eq 1 -a -n "${ROOT_PART_SIZE_SWAP}" ]; then
            gpart_add ${d} "freebsd-swap" 3 "${ROOT_PART_SIZE_SWAP}"
            SWAP_MIRROR_VDEVS="${SWAP_MIRROR_VDEVS} ${ROOT_DISK_TYPE}${d}p3"
        fi

        gpart_add ${d} "freebsd-zfs" 4 "${ROOT_PART_SIZE_ZFS}" "root" 
        ZROOT_MIRROR_VDEVS="${ZROOT_MIRROR_VDEVS} ${ROOT_DISK_TYPE}${d}p4"

		if [ -n "${ROOT_PART_SIZE_SLOG_STANDALONE}" ]; then 
        	gpart_add ${d} "freebsd-zfs" 5 "${ROOT_PART_SIZE_SLOG_STANDALONE}" "slog" 
        fi
        
		if [ -n "${ROOT_PART_SIZE_CACHE_STANDALONE}" ]; then 
	        gpart_add ${d} "freebsd-zfs" 6 "${ROOT_PART_SIZE_CACHE_STANDALONE}" "cache" 
	    fi

        
    done

    #zroot dataset, which will be inherited by its children:
    #zpool_create "${ROOT_DISK_ZPOOL_NAME} mirror ${ZROOT_MIRROR_VDEVS}"
    create_swapmirrors ${SWAP_MIRROR_VDEVS}

}

ROOT_PART_SIZE_ZFS="62G"
ROOT_PART_SIZE_SWAP="64G" 
ROOT_PART_SIZE_SLOG_STANDALONE="64G"
ROOT_PART_SIZE_CACHE_STANDALONE="256G"
SYS_DISK_HDD="da1 da2 da3 da4 da5"
GPTLABEL_NUMBERING="count"
zroot_mirror_two

