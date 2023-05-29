#!/bin/sh
set -x
### DNS /etc/resolv.conf 

if [ -f "$1" ]; then
    _CLI_CONFIG_FILE="$1"
fi



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
: ${ZPOOL_ASHIFT:=12}               # ashift is actually the binary exponent which represents sector size
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
    if [ ${DRYRUN} ]; then
        echo ${cmd}
    else
        ${cmd}
    fi
}
gpart_create()
{
    d="$1"
    cmd="gpart create -s GPT ${d}"
    if [ ${DRYRUN} ]; then
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
    if [ ${DRYRUN} ]; then
        echo ${cmd}
    else
        ${cmd}
    fi
    
}

zpool_create()
{
    # this should be all the whole vdev line "mirror da0 da1 mirror da2 da3 ..." etc
    # aka   zpool_create "${ROOT_DISK_ZPOOL_NAME} ${SYS_DISK_HDD} ${SYS_DISK_SSD}"

    POOL_VDEVS=$@

    # options here should be pulled out.
    zpool create -f -R /mnt/${ROOT_DISK_ZPOOL_NAME} -o ashift=${ZPOOL_ASHIFT} -O canmount=off -O mountpoint=none -O atime=off -O compression=on $POOL_VDEVS
    if [ $? -ne 0 -a -z ${DRYRUN} ]; then
        echo ""
        echo " Error Creating zpool."
        echo ""
        exit 1
    fi
    if [ "${SWAP_ON_ZROOT}" -eq 1 ]; then
        zfs create -s -V ${ROOT_PART_SIZE_SWAP} -o org.freebsd:swap=on -o checksum=off -o compression=off -o sync=disabled -o primarycache=none ${ROOT_DISK_ZPOOL_NAME}/swap
        if [ $? -ne 0 -a -z ${DRYRUN} ]; then
            echo ""
            echo " Error Creating swap on zroot"
            echo ""
            exit 1
        fi
    fi
    if [ "${ROOT_PART_SIZE_ZFS}" = "SLOG" ]; then
        get_glabel_vdevs "slog"
        vdevs="${_vdevs}" # _vdevs is populated by get_glabel_vdevs()
            
        _slog="log "
        for slogdisk in ${vdevs}; do
            if [ $i -eq 0 ]; then
                _slog="${_slog} mirror "
                i=0;
            fi
            i=$((i+1))
            _slog="${_slog} ${slogdisk}"
            if [ $i -ge 2 ]; then
                i=0
            fi
        done
        zpool add ${ROOT_DISK_ZPOOL_NAME} ${_slog}
        if [ $? -ne 0 -a -z ${DRYRUN} ]; then
            echo ""
            echo " Error Creating slog on ${ROOT_DISK_ZPOOL_NAME}"
            echo ""
            exit 1
        fi
    fi
    if [ -n "${ROOT_PART_SIZE_CACHE}" ]; then
        get_glabel_vdevs "cache"
        vdevs="${_vdevs}"
        zpool add ${ROOT_DISK_ZPOOL_NAME} cache ${vdevs}
        if [ $? -ne 0 -a -z ${DRYRUN} ]; then
            echo ""
            echo " Error Creating cache on ${ROOT_DISK_ZPOOL_NAME}"
            echo ""
            exit 1
        fi
    fi


}


find_ssds() 
{

    for disk_sysctl in `sysctl kern.cam | grep rotating | awk -F : '{print $1}' | xargs`; do
        rotating=`sysctl -n ${disk_sysctl}`
        disk=`echo ${disk_sysctl} | awk -F . '{print $3$4}'`
        devat=`dmesg | grep -E "^${disk} at" | awk '{print $3}' | head -1 | cut -c 1-5`
        
        _CONT=0
        if [ -n "${SKIP_DISKS}" ]; then
            for d in ${SKIP_DISKS}; do
                if [ "${d}" = "${disk}" ]; then
                    _CONT=1
                fi
            done        
        fi
        if [ $_CONT -eq 1 ]; then
            continue
        fi
        
        if [ "${devat}" = "umass" ]; then         
            SYS_DISK_UMASS="${SYS_DISK_UMASS} ${disk}";
        elif [ $rotating -eq 1 ]; then
            SYS_DISK_HDD="${SYS_DISK_HDD} ${disk}";
        else 
            SYS_DISK_SSD="${SYS_DISK_SSD} ${disk}";        
        fi
    done


    if [ -z "${SYS_DISK_SSD}" -a -z "${SYS_DISK_HDD}" ]; then
       if [ ${IS_BHYVE} -eq 1 ]; then
            SYS_DISK_HDD=`sysctl -n kern.disks`
       fi
       if [ ${IS_XEN} -eq 1 ]; then
            SYS_DISK_HDD=`sysctl -n kern.disks`
       fi
    fi    


}

zroot_stripe_rawdev()
{
    for d in ${SYS_DISK_HDD} ${SYS_DISK_SSD}; do
        gpart_destroy ${d}
    done

    zpool create -f -R /mnt/${ROOT_DISK_ZPOOL_NAME} -o ashift=${ZPOOL_ASHIFT} -O canmount=off -O mountpoint=none -O atime=off -O compression=on ${ROOT_DISK_ZPOOL_NAME} ${SYS_DISK_HDD} ${SYS_DISK_SSD}
    if [ $? -ne 0 ]; then
        echo ""
        echo " Error Creating zpool."
        echo ""
        exit 1
    fi
    if [ "${SWAP_ON_ZROOT}" -eq 1 ]; then
        zfs create -s -V ${ROOT_PART_SIZE_SWAP} -o org.freebsd:swap=on -o checksum=off -o compression=off -o sync=disabled -o primarycache=none ${ROOT_DISK_ZPOOL_NAME}/swap
    fi

}

zroot_stripe_single()
{

    for d in ${SYS_DISK_HDD} ${SYS_DISK_SSD}; do
        gpart_destroy ${d}
        gpart_create ${d}
        gpart_add ${d} "efi" 1 ${ROOT_PART_SIZE_EFI}
        gpart_add ${d} "freebsd-boot" 2 ${ROOT_PART_SIZE_BOOT}
        if [ "${ROOT_PART_SWAP}" -eq 1 -a -n "${ROOT_PART_SIZE_SWAP}" ]; then
            gpart_add ${d} "freebsd-swap" 3 ${ROOT_PART_SIZE_SWAP}
        fi
        gpart_add ${d} "freebsd-zfs" 4 ${ROOT_PART_SIZE_ZFS} "root" 
    done
    
    get_glabel_vdevs root
    vdevs="${_vdevs}"

    zpool_create "${ROOT_DISK_ZPOOL_NAME} ${vdevs}"

}

zpool_raid50()
{

    spinning=""
    ssd=""
    
    ZROOT_VDEVS=
    SWAP_MIRROR_VDEVS=
    labelnum=0

    i=0
    for d in ${SYS_DISK_HDD}; do
        ZROOT_VDEVS="${ZROOT_VDEVS} ${d}"
        gpart_destroy ${d}
        i=$((i+1))
        if [ ${ZROOT_TOTAL_VDEVS} -eq ${i} ]; then
            break
        fi
    done

    vdevs=3
    raidz="raidz"
    if [ ${ZPOOL_RAIDZ} -eq 1 ]; then
        vdevs=${ZPOOL_RAIDZ1_NVEDS};
        raidz="raidz"
    fi
    if [ ${ZPOOL_RAIDZ} -eq 2 ]; then
        vdevs=${ZPOOL_RAIDZ2_NVEDS};
        raidz="raidz2"
    fi
    if [ ${ZPOOL_RAIDZ} -eq 3 ]; then
        vdevs=${ZPOOL_RAIDZ3_NVEDS};
        raidz="raidz3"
    fi

    i=0
    zroot="${ROOT_DISK_ZPOOL_NAME} ${raidz} "
    for rootdisk in ${ZROOT_VDEVS}; do
        if [ $i -eq ${vdevs} ]; then
            i=0;
            zroot="${zroot} ${raidz} "
        fi
        i=$((i+1))
        zroot="${zroot} ${rootdisk} "
    done    
    
    zpool_create "${zroot}"

    i=0

}


xcpnas_2020()
{
    # Originally for Care2 "Olympus" Edition 
    # Supermicro X9DR3-F, E5-2630L v2, 24 CPUs, 2 package(s) x 6 core(s) x 2 hardware threads
    # 5x SAMSUNG MZILS480HCGR/003 SSDs 480GB
    # 15x SEAGATE SMKR6000S5xeN7.2 6TB
    # BOOT blocks & kernel on 2x 16GB SSDs
    # ROOT on zpool 
    # Assumes usbboot created in separate function.
    #
    ZROOT_MIRROR_VDEVS=
    SWAP_MIRROR_VDEVS=
    _DISKS=
    
    if [ -n "${SYS_DISK_SSD}" ]; then
        _DISKS=${SYS_DISK_SSD}
    else 
        echo "ERROR: didn't find any SSDs !"
        echo "   --> (this is probably a scripting/logic error on how I'm selecting disks)"
        exit 1
    fi
        
    for d in ${_DISKS}; do
        gpart_destroy ${d}
        gpart_create ${d}
        gpart_add ${d} "efi" 1 ${ROOT_PART_SIZE_EFI}
        gpart_add ${d} "freebsd-boot" 2 ${ROOT_PART_SIZE_BOOT}
        if [  "${ROOT_PART_SWAP}" -eq 1 -a -n "${ROOT_PART_SIZE_SWAP}" ]; then
            gpart_add ${d} "freebsd-swap" 3 ${ROOT_PART_SIZE_SWAP}
        fi      
        if [ "${ROOT_PART_SIZE_ZFS}" = "SLOG" ]; then
            gpart_add ${d} "freebsd-zfs" 4 ${ROOT_PART_SIZE_SLOG} "slog"
        else 
            gpart_add ${d} "freebsd-zfs" 4 ${ROOT_PART_SIZE_ZFS} "root"
        fi
        if [ -n "${ROOT_PART_SIZE_CACHE}" ]; then
            gpart_add ${d} "freebsd-zfs" 5 ${ROOT_PART_SIZE_CACHE} "cache"
        fi
        if [ "x${ROOT_PART_SIZE_DATA}" != "-1" ]; then
            gpart_add ${d} "freebsd-zfs" 6 ${ROOT_PART_SIZE_DATA} "data"
        fi      
    done

    get_glabel_vdevs "swap"
    vdevs="${_vdevs}"

    SWAP_MIRROR_VDEVS="$vdevs"  
    create_swapmirrors ${SWAP_MIRROR_VDEVS}
    zpool_raid50
    
}

usb()
{
    ZROOT_MIRROR_VDEVS=
    SWAP_MIRROR_VDEVS=
    _DISKS=
    PREVIOUS_ROOT_DISK_ZPOOL_NAME=${ROOT_DISK_ZPOOL_NAME}
    ROOT_DISK_ZPOOL_NAME="usbboot"
    
    if [ -n "${SYS_DISK_UMASS}" ]; then
        _DISKS=${SYS_DISK_UMASS}
    else 
        echo "ERROR: didn't find any USB Disks !"
        echo "   --> (this is probably a scripting/logic error on how I'm selecting disks)"
        exit 1
    fi
        
    for d in ${_DISKS}; do
        gpart_destroy ${d}
        gpart_create ${d}
        gpart_add ${d} "efi" 1 ${ROOT_PART_SIZE_EFI}
        gpart_add ${d} "freebsd-boot" 2 ${ROOT_PART_SIZE_BOOT}
        # ! DO NOT PUT SWAP ON USB DISKS ! Major performance issues.
        #if [  "${ROOT_PART_SWAP}" -eq 1 -a -n "${ROOT_PART_SIZE_SWAP}" ]; then
        #    gpart_add ${d} "freebsd-swap" 3 ${ROOT_PART_SIZE_SWAP}
        #fi
        gpart_add ${d} "freebsd-zfs" 4 ${ROOT_PART_SIZE_ZFS} "root"
    done

    vdevs=""
    get_glabel_vdevs "root"
    vdevs="${_vdevs}"
    ZROOT_MIRROR_VDEVS="$vdevs"
    zpool_create "${ROOT_DISK_ZPOOL_NAME} mirror ${ZROOT_MIRROR_VDEVS}"

#    if [  "${ROOT_PART_SWAP}" -eq 1 ]; then
#       get_glabel_vdevs "swap"
#       vdevs="${_vdevs}"
#       create_swapmirrors ${SWAP_MIRROR_VDEVS}
#   fi

    zfs create -o canmount=off -o mountpoint=none ${ROOT_DISK_ZPOOL_NAME}/ROOT
    if [ ${ROOT_ON_USB} -eq 1 ]; then
        _mountpoint="-o mountpoint=/"
        echo 'vfs.root.mountfrom="zfs:' . ${ROOT_DISK_ZPOOL_NAME} . '/ROOT/default"' >> /mnt/usbboot/boot/loader.conf
        DESTDIR="/mnt/${ROOT_DISK_ZPOOL_NAME}"            # DESTDIR, -R/altroot=
        DESTDIR2="/mnt/${ROOT_DISK_ZPOOL_NAME}2"  # DESTDIR, -R/altroot=    
    else 
        _mountpoint="-o mountpoint=/usbboot"
    fi
    zfs create ${_mountpoint} ${ROOT_DISK_ZPOOL_NAME}/ROOT/default
    zfs create -o mountpoint=none ${ROOT_DISK_ZPOOL_NAME}/ROOT/secondary    
    ROOT_DISK_ZPOOL_NAME=${PREVIOUS_ROOT_DISK_ZPOOL_NAME}

}

zroot_mirror_two()
{

    ZROOT_MIRROR_VDEVS=
    SWAP_MIRROR_VDEVS=
    _DISKS=
    
    if [ -z "${SYS_DISK_HDD}" ]; then
        if [ ! -z "${SYS_DISK_SSD}" ]; then
            _DISKS=${SYS_DISK_SSD}
        else 
            echo "ERROR: didn't find any disks !"
            echo "   --> (this is probably a scripting/logic error on how I'm selecting disks"
            exit 1
        fi
    else 
        _DISKS=${SYS_DISK_HDD}
    fi
    for d in ${_DISKS}; do
        gpart_destroy ${d}
        gpart_create ${d}
        gpart_add ${d} "efi" 1 ${ROOT_PART_SIZE_EFI}
        gpart_add ${d} "freebsd-boot" 2 ${ROOT_PART_SIZE_BOOT}
        if [  "${ROOT_PART_SWAP}" -eq 1 -a -n "${ROOT_PART_SIZE_SWAP}" ]; then
            gpart_add ${d} "freebsd-swap" 3 ${ROOT_PART_SIZE_SWAP}
            SWAP_MIRROR_VDEVS="${SWAP_MIRROR_VDEVS} ${ROOT_DISK_TYPE}${d}p3"
        fi
        gpart_add ${d} "freebsd-zfs" 4 ${ROOT_PART_SIZE_ZFS} "root" 
        ZROOT_MIRROR_VDEVS="${ZROOT_MIRROR_VDEVS} ${ROOT_DISK_TYPE}${d}p4"
        
        
    done

    #zroot dataset, which will be inherited by its children:
    zpool_create "${ROOT_DISK_ZPOOL_NAME} mirror ${ZROOT_MIRROR_VDEVS}"
    create_swapmirrors ${SWAP_MIRROR_VDEVS}

}

zroot_stripe_two_ssd_hd()
{

    spinning=""
    ssd=""    
    i=0    
    for d in ${SYS_DISK_HDD}; do
        gpart_destroy ${d}
        gpart_create ${d}
        gpart_add ${d} "efi" 1, ${ROOT_PART_SIZE_EFI}
        gpart_add ${d} "freebsd-boot" 2 ${ROOT_PART_SIZE_BOOT}
        # no swap on spinning.
        if [ "${NO_SWAP_ON_SPINNING}" -eq 0 -a "${ROOT_PART_SWAP}" -eq 1 -a -n "${ROOT_PART_SIZE_SWAP}" ]; then
            gpart_add ${d}, "freebsd-swap", 3, ${ROOT_PART_SIZE_SWAP}
        fi
        gpart_add ${d} "freebsd-zfs" 4 ${ROOT_PART_SIZE_ZFS} "root"
    done
    get_glabel_vdevs "root"
    vdevs="${_vdevs}"

    for d in ${SYS_DISK_SSD}; do
        ssd=${d}
        gpart_destroy ${d}
        gpart_create ${d}
        gpart_add ${d} "efi" 1 ${ROOT_PART_SIZE_EFI}
        gpart_add ${d} "freebsd-boot" 2 ${ROOT_PART_SIZE_BOOT}
        if [ "${ROOT_PART_SWAP}" -eq 1 -a -n "${ROOT_PART_SIZE_SWAP}" ]; then        
            gpart_add ${d} "freebsd-swap" 3 ${ROOT_PART_SIZE_SWAP}
        fi
        gpart_add ${d} "freebsd-zfs" 5 ${ROOT_PART_SIZE_ZFS} "cache"
    done    
    get_glabel_vdevs "cache"
    vdevs="${_vdevs}"
}

zroot_raid10()
{

    spinning=""
    ssd=""
    
    i=0
    ZROOT_MIRROR_VDEVS=
    SWAP_MIRROR_VDEVS=
    
    for d in ${SYS_DISK_HDD}; do
        gpart_destroy ${d}
        gpart_create ${d}
        gpart_add ${d} "efi" 1 ${ROOT_PART_SIZE_EFI}
        gpart_add ${d} "freebsd-boot" 2 ${ROOT_PART_SIZE_BOOT}
        if [ "${NO_SWAP_ON_SPINNING}" -eq 0 -a "${ROOT_PART_SWAP}" -eq 1 -a -n "${ROOT_PART_SIZE_SWAP}" ]; then
            gpart_add ${d} "freebsd-swap" 3 ${ROOT_PART_SIZE_SWAP}
        fi
        gpart_add ${d} "freebsd-zfs"  4 ${ROOT_PART_SIZE_ZFS} "root"

        ZROOT_MIRROR_VDEVS="${ZROOT_MIRROR_VDEVS} ${ROOT_DISK_TYPE}${d}p4"
        SWAP_MIRROR_VDEVS="${SWAP_MIRROR_VDEVS} ${ROOT_DISK_TYPE}${d}p3"
    done

    i=0
    zroot="${ROOT_DISK_ZPOOL_NAME} mirror "
    get_glabel_vdevs "root"
    vdevs="${_vdevs}"

    # for rootdisk in `/bin/ls -1 /dev/gpt/root[0-9]* |xargs `; do
    for rootdisk in `${vdevs}`; do
        if [ $i -eq 2 ]; then
            i=0;
            zroot="${zroot} mirror "
        fi
        i=$((i+1))
        zroot="${zroot} ${rootdisk} "
    done    
    zpool_create "${zroot}"
    create_swapmirrors ${SWAP_MIRROR_VDEVS}

}
zroot_raid50()
{
    zroot_raidZ
}

zroot_raidZ()
{

    spinning=""
    ssd=""
    
    i=0
    # ZPOOL_RAIDZ
    # ZPOOL_RAIDZ1_NVEDS=4
    # ZPOOL_RAIDZ2_NVEDS=5
    ZROOT_VDEVS=
    SWAP_MIRROR_VDEVS=
    labelnum=0
    
    for d in ${SYS_DISK_HDD}; do
        gpart_destroy ${d}

        if [ ${ZPOOL_VDEVS_RAW} -eq 0 ]; then
            gpart_create ${d}
            gpart_add ${d} "efi" 1 ${ROOT_PART_SIZE_EFI}
            gpart_add ${d} "freebsd-boot" 2 ${ROOT_PART_SIZE_BOOT}
            if [ "${NO_SWAP_ON_SPINNING}" -eq 0 -a "${ROOT_PART_SWAP}" -eq 1 -a -n "${ROOT_PART_SIZE_SWAP}" ]; then
                gpart_add ${d} "freebsd-swap" 3 ${ROOT_PART_SIZE_SWAP}
                SWAP_MIRROR_VDEVS="${SWAP_MIRROR_VDEVS} ${d}p3"
            fi
            gpart_add ${d} "freebsd-zfs" 4 ${ROOT_PART_SIZE_ZFS} "root"
            ZROOT_VDEVS="${ZROOT_VDEVS} ${d}p4"
        else
            ZROOT_VDEVS="${ZROOT_VDEVS} ${d}"           
        fi
    done

    for d in ${SYS_DISK_SSD}; do
        gpart_destroy ${d}
        if [ ${ZPOOL_VDEVS_RAW} -eq 0 ]; then
            gpart_create ${d}
            gpart_add ${d} "efi" 1 ${ROOT_PART_SIZE_EFI}
            gpart_add ${d} "freebsd-boot" 2 ${ROOT_PART_SIZE_BOOT}
            if [ "${ROOT_PART_SWAP}" -eq 1 -a -n "${ROOT_PART_SIZE_SWAP}" ]; then
                gpart_add ${d} "freebsd-swap" 3 ${ROOT_PART_SIZE_SWAP}
                SWAP_MIRROR_VDEVS="${SWAP_MIRROR_VDEVS} ${d}p3"
            fi
            if [ ${ZPOOL_VDEVS_ALLSSD} -eq 1 ]; then
                gpart_add ${d} "freebsd-zfs" 4 ${ROOT_PART_SIZE_ZFS} "root"
                ZROOT_VDEVS="${ZROOT_VDEVS} ${d}p4"
            fi
        else 
            ZROOT_VDEVS="${ZROOT_VDEVS} ${d}"
        fi
    done

    vdevs=3
    raidz="raidz"
    if [ ${ZPOOL_RAIDZ} -eq 1 ]; then
        vdevs=${ZPOOL_RAIDZ1_NVEDS};
        raidz="raidz"
    fi
    if [ ${ZPOOL_RAIDZ} -eq 2 ]; then
        vdevs=${ZPOOL_RAIDZ2_NVEDS};
        raidz="raidz2"
    fi
    

    i=0
    zroot="${ROOT_DISK_ZPOOL_NAME} ${raidz} "
    for rootdisk in ${ZROOT_VDEVS}; do
        if [ $i -eq ${vdevs} ]; then
            i=0;
            zroot="${zroot} ${raidz} "
        fi
        i=$((i+1))
        zroot="${zroot} ${rootdisk} "
    done    
    zpool_create "${zroot}"

    if [ -n "${SWAP_MIRROR_VDEVS}" ]; then
        create_swapmirrors ${SWAP_MIRROR_VDEVS}
    fi

}

kldload /boot/modules/geom_mirror.ko

mkdir -p ${TMPDIR}
if [ ! -f "${TMPDIR}/.tmpfs" ]; then
    umount ${TMPDIR}
    mount -t tmpfs tmpfs ${TMPDIR}
    touch ${TMPDIR}/.tmpfs
fi
if [ ! -f "/mnt/.tmpfs" ]; then
    umount /mnt
    mount -t tmpfs tmpfs /mnt
    touch /mnt/.tmpfs
fi

get_system_config

for c in ${CONFIGS}; do
    . ${c}
done
for p in ${dpdfinst_config_paths}; do
    if [ -f "${p}/${dpdfinst_config_file}" ]; then
        . ${p}/${dpdfinst_config_file}
    fi
done
if [ -n "${_CLI_CONFIG_FILE}" -a  -f "${_CLI_CONFIG_FILE}" ]; then
    . "${_CLI_CONFIG_FILE}"
fi

find_ssds


if [ ! -z "${ROOT_DISK_TYPE}" -a ! -z "${ROOT_DISK_UNITS}" ]; then
    SYS_DISK_HDD=
    SYS_DISK_SSD=
    for d in ${ROOT_DISK_TYPE}; do
        for u in ${ROOT_DISK_UNITS}; do
            SYS_DISK_SSD="${SYS_DISK_SSD} ${d}${u}"
        done
    done
fi
            
# Note:  -N      Import the pool without mounting any file systems.
zpool import -a -F -N -f 
zpool_list=
if [ -n "${DISK_ZPOOL_PROTECT_NAMES}" ]; then
    zpool_list=`zpool list | grep -v '^no pools available' | grep -v ^NAME | grep -v -E ^${DISK_ZPOOL_PROTECT_NAMES} | awk '{print $1}' | xargs`
else 
    zpool_list=`zpool list | grep -v '^no pools available' | grep -v ^NAME | awk '{print $1}' | xargs`
fi

for pool in ${zpool_list}; do
    zpool destroy -f ${pool}
done
for mirror in `gmirror status | grep ^mirror | awk '{print $1}' | awk -F \/ '{print $2}'`; do
    gmirror destroy -f ${mirror}
done

mkdir -p ${DESTDIR}
mkdir -p ${DESTDIR2}


# if [ ${ROOT_ON_USB} -eq 1 -o ${BOOTONLY_ON_USB} -eq 1 ]; then
#     usb
# fi

case ${ROOT_DISK_ZPOOL} in
    xcpnas_2020)
        xcpnas_2020
    ;;
    usbboot_zroot_hwraid)
        usbboot_zroot_hwraid
    ;;
    zroot_stripe_rawdev)
        zroot_stripe_rawdev
    ;;
    zroot_stripe_single)
        zroot_stripe_single
    ;;
    zroot_stripe_two_ssd_hd)
        zroot_stripe_two_ssd_hd
    ;;
    zroot_mirror_two)
        zroot_mirror_two
    ;;
    zroot_raid10)
        zroot_raid10
    ;;
    zroot_raid50)
        zroot_raid50
    ;;
    zroot_raidZ)
        zroot_raidZ
    ;;
    usb)
        ROOT_DISK_ZPOOL_NAME=usbboot
        usb
esac


#Container for boot environments beadm(1M) compatible setup
zfs create -o canmount=off -o mountpoint=none ${ROOT_DISK_ZPOOL_NAME}/ROOT
zfs create -o mountpoint=/ ${ROOT_DISK_ZPOOL_NAME}/ROOT/default
zfs create -o mountpoint=/${ROOT_DISK_ZPOOL_NAME}2 ${ROOT_DISK_ZPOOL_NAME}/ROOT/secondary

#Things we want to be common across boot environments:
zfs create -o mountpoint=/var/log -o compression=gzip-9 ${ROOT_DISK_ZPOOL_NAME}/log
zfs create -o mountpoint=/usr/home ${ROOT_DISK_ZPOOL_NAME}/home
zfs create -o mountpoint=/tmp ${ROOT_DISK_ZPOOL_NAME}/tmp
zfs create -o mountpoint=/var/tmp ${ROOT_DISK_ZPOOL_NAME}/vartmp

if [ -z "${NO_INSTALL}" ]; then
    for i in kernel.txz base.txz doc.txz lib32.txz; do
        http_fetch $i "${TMPDIR}" ${REMOTE_RELEASE_HTTP}
        if [ -z "${DRYRUN}" ]; then 
            tar -xf "${TMPDIR}/${i}" -C ${DESTDIR}
        fi
    done

    if [ "${INSTALL_DEBUG}" ]; then
        for i in base-dbg.txz kernel-dbg.txz lib32-dbg.txz; do
            http_fetch $i "${TMPDIR}" ${REMOTE_RELEASE_HTTP}
            if [ -z "${DRYRUN}" ]; then 
                tar -xf "${TMPDIR}/${i}" -C ${DESTDIR}
            fi
        done
    fi
    if [ "${INSTALL_SRC}" ]; then
        for i in src.txz; do
            http_fetch $i "${TMPDIR}" ${REMOTE_RELEASE_HTTP}
            if [ -z "${DRYRUN}" ]; then 
                tar -xf "${TMPDIR}/${i}" -C ${DESTDIR}
            fi
        done
    fi
    if [ "${INSTALL_PORTS}" ]; then
        for i in ports.txz; do
            http_fetch $i "${TMPDIR}" ${REMOTE_RELEASE_HTTP}
            if [ -z "${DRYRUN}" ]; then 
                tar -xf "${TMPDIR}/${i}" -C ${DESTDIR}
            fi
        done
    fi
fi 
if [ -z "${BOOTCODE_SKIP}" ]; then
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

if [ -z "${NO_INSTALL}" ]; then

mount -t devfs devfs ${DESTDIR}/dev

cat > ${DESTDIR}/boot/loader.conf << EOF

console="${BOOTCODE_CONSOLE}"
comconsole_speed="115200"
comconsole_port="0x2f8"
boot_multicons="yes"

# Needed for iSCSI
kern.cam.boot_delay="10000"

beastie_disable="YES"

geom_mirror_load="YES"
if_bridge_load="YES"
if_tap_load="YES"
ipmi_load="YES"
zfs_load="YES"

EOF

cat > ${DESTDIR}/etc/fstab << EOF1
# Device                       Mountpoint              FStype   Options         Dump    Pass#
EOF1

if [ "${SWAP_ON_ZROOT}" -eq 1 ]; then
    echo "/dev/zvol/${ROOT_DISK_ZPOOL_NAME}/swap             none                    swap     sw              0       0" >> ${DESTDIR}/etc/fstab
else 
    SWAPPARTS=`/bin/ls -1 /dev/mirror/swap* | xargs`
    if [ -z "${SWAPPARTS}" ]; then
        get_glabel_vdevs "swap"
        SWAPPARTS="${_vdevs}"
    fi

    for swap in ${SWAPPARTS}; do
        echo "${swap}                 none                    swap     sw              0       0" >> ${DESTDIR}/etc/fstab
    done
fi

if [ ! -z "${HOSTNAME}" ]; then
    echo "hostname=\"${HOSTNAME}\"" >> ${DESTDIR}/etc/rc.conf.local
else 
    m="${MACS%% *}"
    if [ ${IS_BHYVE} -eq 1 ]; then
        # Get the first mac, separated by space
        echo "hostname=\"vm-${m}\"" >> ${DESTDIR}/etc/rc.conf.local
    else 
        if [ -n "${SERIAL}" ]; then
            echo "hostname=\"${SERIAL}\"" >> ${DESTDIR}/etc/rc.conf.local
        elif [ -n "${VENDOR}" ]; then
            echo "hostname=\"${VENDOR}-$m\"" >> ${DESTDIR}/etc/rc.conf.local
        elif [ -n "${UUID}" ]; then
            echo "hostname=\"${UUID}\"" >> ${DESTDIR}/etc/rc.conf.local
        else 
            echo "hostname=\"${sys-$m}\"" >> ${DESTDIR}/etc/rc.conf.local
        fi            
    fi
fi

if [ ! -z "${ROUTE_DEFAULT}" ]; then
    echo "defaultrouter=\"${ROUTE_DEFAULT}\"" >> ${DESTDIR}/etc/rc.conf.local
fi

if [ -n "${USE_DHCP}" ]; then
    if [ -z "${NIC}" ]; then
        # get the first nic
        n="${NICS%% *}"
        echo "ifconfig_${n}=\"DHCP\"" >> ${DESTDIR}/etc/rc.conf.local
    else
        echo "ifconfig_${NIC}=\"DHCP\"" >> ${DESTDIR}/etc/rc.conf.local
    fi
else
    if [ -n "${IP}" -a  -n "${NETMASK}" ]; then
        echo "ifconfig_${NIC}=\"inet ${IP} netmask ${NETMASK} up\"" >> ${DESTDIR}/etc/rc.conf.local
    elif [ -n "${IP}" ]; then
        # ip might be in cidr notation
        echo "ifconfig_${NIC}=\"inet ${IP} up\"" >> ${DESTDIR}/etc/rc.conf.local
    fi
fi

cat >> ${DESTDIR}/etc/rc.conf << EOF2
sshd_enable="YES"
sendmail_enable="NONE"
cron_enable="YES"
local_enable="YES"
netwait_enable="YES"
syslogd_enable="YES"

ntpdate_enable="YES"        # Run ntpdate to sync time on boot (or NO).
ntpdate_flags="-b"      # Flags to ntpdate (if enabled).
ntpdate_config="/etc/ntp.conf"  # ntpdate(8) configuration file
ntpd_enable="YES"       # Run ntpd Network Time Protocol (or NO).
zfs_enable="YES"

EOF2

if [ -n "${RCD_ENABLES}" ]; then
    for rcd in "${RCD_ENABLES}"; do
        rcdfile=`echo "${rcd}" | awk -F: '{print $1}'`
        rcdvar=`echo "${rcd}" | awk -F: '{print $2}'`
        if [ ! -f "${DESTDIR}/${rcdfile}" ]; then
            touch ${DESTDIR}/${rcdfile}
        fi
        echo  ${rcdvar} >> ${DESTDIR}/${rcdfile}
    done
fi

cp -v /etc/resolv.conf  ${DESTDIR}/etc/resolv.conf

if [ -n "${USER_PROVISION}" ]; then
    http_fetch ${USER_PROVISION} ${DESTDIR}/root ${REMOTE_SCRIPTS_HTTP} 
    chmod 755 ${DESTDIR}/root/${USER_PROVISION}
fi

if [ -n "${ADMIN_CONFIG}" ]; then
    http_fetch ${ADMIN_CONFIG} ${DESTDIR}/etc/ ${REMOTE_CONFD_HTTP}
    USERS=`cat ${DESTDIR}/etc/${ADMIN_CONFIG} | awk -F : '{print $1}' | xargs `
    for u in ${USERS}; do
      chroot ${DESTDIR} /root/${USER_PROVISION} ${u} wheel
    done    
fi

if [ -n "${REMOTE_CUSTOM_REPOS}" ]; then 
    mkdir -p ${DESTDIR}/usr/local/etc/pkg/repos/
    echo "FreeBSD { enabled: no }" > ${DESTDIR}/usr/local/etc/pkg/repos/FreeBSD.conf
    for repo in "${REMOTE_CUSTOM_REPOS}"; do
        http_fetch ${repo} ${DESTDIR}/usr/local/etc/pkg/repos/ ${REMOTE_CONFD_HTTP}
        reponame=`echo ${repo} | sed -e 's/\.repo$/.conf/g'`
        mv ${DESTDIR}/usr/local/etc/pkg/repos/${repo} ${DESTDIR}/usr/local/etc/pkg/repos/${reponame}
    done
fi

mv /mnt/${ROOT_DISK_ZPOOL_NAME}/etc/hosts /mnt/${ROOT_DISK_ZPOOL_NAME}/etc/hosts.orig
cp /etc/hosts /mnt/${ROOT_DISK_ZPOOL_NAME}/etc/
if [ -n "${PKG_SET}" -a -n "${PKG_INSTALLER}" ]; then 
    http_fetch ${PKG_SET} ${DESTDIR} ${REMOTE_CONFD_HTTP}
    http_fetch ${PKG_INSTALLER} ${DESTDIR} ${REMOTE_SCRIPTS_HTTP}
    chroot ${DESTDIR} sh /${PKG_INSTALLER} /${PKG_SET}
    if [ -x "${DESTDIR}/usr/local/bin/sudo"  ]; then 
        echo "%wheel ALL=(ALL) ALL" > ${DESTDIR}/usr/local/etc/sudoers.d/wheel
    fi
    rm ${DESTDIR}/${PKG_SET} ${DESTDIR}/${PKG_INSTALLER}
fi

mv /mnt/${ROOT_DISK_ZPOOL_NAME}/etc/hosts.orig /mnt/${ROOT_DISK_ZPOOL_NAME}/etc/hosts


AESNI_CIPHERS1=`chroot ${DESTDIR} sh -c "/usr/bin/ssh -Q cipher | grep gcm | sort -r | xargs | sed -E 's/ /,/g'"`
AESNI_CIPHERS2=`chroot ${DESTDIR} sh -c "/usr/bin/ssh -Q cipher | grep aes | grep -v gcm | sort -r | xargs | sed -E 's/ /,/g'"`
AESNI_CIPHERS="Ciphers ${AESNI_CIPHERS1},${AESNI_CIPHERS2}"
grep -i AESNI /var/run/dmesg.boot > /dev/null
if [ $? -eq 0 ]; then
    if [ $? -eq 0 ]; then
        echo " " >>  ${DESTDIR}/etc/ssh/sshd_config 
        echo "# dpdfinst detected AESNI, setting AES accelerated ciphers as preference. " >>  ${DESTDIR}/etc/ssh/sshd_config 
        echo ${AESNI_CIPHERS} >>  ${DESTDIR}/etc/ssh/sshd_config 
        echo " " >>  ${DESTDIR}/etc/ssh/sshd_config 
    
        echo " " >>  ${DESTDIR}/etc/ssh/ssh_config 
        echo "# dpdfinst detected AESNI, setting AES accelerated ciphers as preference." >>  ${DESTDIR}/etc/ssh/ssh_config 
        echo "Host * " >>  ${DESTDIR}/etc/ssh/ssh_config 
        echo "   ${AESNI_CIPHERS} " >>  ${DESTDIR}/etc/ssh/ssh_config 
        echo " " >>  ${DESTDIR}/etc/ssh/ssh_config 
    fi
fi

fi  ## if [ -z "${NO_INSTALL}" ]; then
if [ -n "${ROOT_PASSWORD_HASH}" ]; then 
cat > ${DESTDIR}/root/rootpw.sh << EOFPW
    #!/bin/sh
    echo '${ROOT_PASSWORD_HASH}' | /usr/bin/sed -e 's,%,$,g' | /usr/sbin/pw usermod root -H 0
    
EOFPW
chmod 755 ${DESTDIR}/root/rootpw.sh
cat ${DESTDIR}/root/rootpw.sh
chroot ${DESTDIR} /root/rootpw.sh
rm ${DESTDIR}/root/rootpw.sh
fi

umount -f ${DESTDIR}/dev || true 
zfs umount -a
zfs set mountpoint=/ ${ROOT_DISK_ZPOOL_NAME}/ROOT/default
zfs snap ${ROOT_DISK_ZPOOL_NAME}/ROOT/default@installed
#zfs destroy ${ROOT_DISK_ZPOOL_NAME}/ROOT/secondary
#zfs clone ${ROOT_DISK_ZPOOL_NAME}/ROOT/default@installed ${ROOT_DISK_ZPOOL_NAME}/ROOT/secondary
zfs set mountpoint=none ${ROOT_DISK_ZPOOL_NAME}/ROOT/secondary

#Things we want to be common across boot environments:
zfs set mountpoint=/var/log ${ROOT_DISK_ZPOOL_NAME}/log
zfs set mountpoint=/usr/home ${ROOT_DISK_ZPOOL_NAME}/home
zfs set mountpoint=/tmp ${ROOT_DISK_ZPOOL_NAME}/tmp
zfs set mountpoint=/var/tmp ${ROOT_DISK_ZPOOL_NAME}/vartmp

zpool set bootfs=${ROOT_DISK_ZPOOL_NAME}/ROOT/default ${ROOT_DISK_ZPOOL_NAME}

