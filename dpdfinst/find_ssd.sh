#!/bin/sh
set -x
# Fixed URL part
apiurl="${dpdfinst_host_api1_protocol}://${dpdfinst_host_api1}/${dpdfinst_api1_path}/${dpdfinst_api1_version}"


# ROOT_DISK_ZPOOL:  Type of zpool for the Root Disk.  Implemented types are:
#     zroot_stripe_rawdev
#     zroot_stripe_single
#     zroot_stripe_two_ssd_hd
#     zroot_mirror_two
#     zroot_raid10
#     zroot_raid50
#     usbboot_zroot_hwraid


: ${ROOT_DISK_ZPOOL_NAME:="z"}
: ${ROOT_DISK_ZPOOL:="zroot_mirror_two"}

: ${ROOT_DISK_TYPE:=""}             # GEOM disk path
: ${ROOT_DISK_UNITS:=""}            # Gpart partition units/parts

: ${SYS_DISK_SSD:=""}               # detected SSD Disks
: ${SYS_DISK_HDD:=""}               # detected hard disk drives, spinning
: ${SYS_DISK_UMASS:=""}             # USB mass storage
: ${SYS_DISK_OTHER:=""}             # other storage devices

: ${GPTLABEL_NUMBERING:="serial"}   # count or serial : Simple incrementing count, rel to zero; 
                                    #   or the last 6 chars of the disks serial number.


: ${ROOT_PART_SIZE_EFI:="800k"}     # EFI Partition Size
: ${ROOT_PART_SIZE_BOOT:="512k"}    # freebsd-boot partition size
: ${ROOT_PART_SIZE_SWAP:="8G"}      # partition for swap on root block devices
: ${ROOT_PART_SWAP:=1}              # create partition swap partition
: ${SWAP_ON_ZROOT:=0}               # boolean, create swap on the root zpool
: ${ROOT_PART_SIZE_ZFS:=0}          # size of zroot vdev.  0=auto, use remaning space.
: ${DATA_PART_SIZE_ZFS:=0}          # unused, add a partition for "data" beyond the VDEV part for zroot
: ${BOOTCODE_SKIP:=}                # IFDEFNED,  do not install bootcode, pmbr and gptzfsboot 

: ${ZPOOL_RAIDZ:="1"}               # 1 OR 2 : RAIDZ 1 (RAID-5) or RAIDZ 2 (RAID-6)
: ${ZPOOL_RAIDZ1_NVEDS:="4"}        # NUMBER OF VDEVS NEEDS FOR RAIDZ 1
: ${ZPOOL_RAIDZ2_NVEDS:="5"}        # NUMBER OF VDEVS NEEDS FOR RAIDZ 2


: ${REMOTE_RELEASE_HTTP:="${dpdfinst_host_api1_protocol}://${dpdfinst_host_api1}/${dpdfinst_api1_path}/amd64.amd64/12.1-STABLE/current/ftp"}
: ${REMOTE_SCRIPTS_HTTP:="${dpdfinst_host_api1_protocol}://${dpdfinst_host_api1}/${dpdfinst_api1_path}/${dpdfinst_api1_version}"}
: ${REMOTE_CONFD_HTTP:="${dpdfinst_host_api1_protocol}://${dpdfinst_host_api1}/${dpdfinst_api1_path}/${dpdfinst_api1_version}"}
: ${REMOTE_PKG_URL:="${dpdfinst_host_api2_protocol}://${dpdfinst_host_api2}/${dpdfinst_api2_path}/packages/12-stable-default/"}

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
: ${NICS:=`ifconfig -l`}

: ${UUID:=}
: ${VENDOR:=}
: ${IS_BHYVE:=0}

: ${PKG_SET:="finst.packages"}
: ${ADMIN_CONFIG:="finst-admins.conf"}
: ${USER_PROVISION:="unixuser_provision.sh"}

: ${CONFIGS:=}

_EFI_COUNT=0
_GPTBOOT_COUNT=0
_DATA_COUNT=0
_SWAP_COUNT=0
_ROOT_COUNT=0
_CACHE_COUNT=0
_SLOG_COUNT=0

. /etc/dpdfinst.conf



find_ssds() 
{

    for disk_sysctl in `sysctl kern.cam | grep rotating | awk -F : '{print $1}' | xargs`; do
        rotating=`sysctl -n ${disk_sysctl}`
        disk=`echo ${disk_sysctl} | awk -F . '{print $3$4}'`
        devat=`dmesg | grep -E "^${disk} at" | awk '{print $3}' | head -1 | cut -c 1-5`
        
        if [ "${devat}" = "umass" ]; then         
            SYS_DISK_UMASS="${SYS_DISK_UMASS} ${disk}";
        elif [ $rotating -eq 1 ]; then
            SYS_DISK_HDD="${SYS_DISK_HDD} ${disk}";
        else 
            SYS_DISK_SSD="${SYS_DISK_SSD} ${disk}";        
        fi
    done
    
    

}
burnin()
{
    for d in ${SYS_DISK_HDD}; do
        echo "==> $d "
        dd if=/dev/zero of=/dev/$d bs=64k
        sleep 10
    done


}

nas_ssd_gpart_only()
{
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
        if [  "${ROOT_PART_SWAP}" -eq 1 ]; then
            gpart_add ${d} "freebsd-swap" 3 ${ROOT_PART_SIZE_SWAP}
        fi
        gpart_add ${d} "freebsd-zfs" 4 ${ROOT_PART_SIZE_SLOG} "slog" 
        gpart_add ${d} "freebsd-zfs" 5 ${ROOT_PART_SIZE_CACHE} "cache" 
        gpart_add ${d} "freebsd-zfs" 6 ${ROOT_PART_SIZE_DATA} "data" 
    done

    SWAP_MIRROR_VDEVS=`/bin/ls -1 /dev/gpt/swap* | xargs`
    create_swapmirrors ${SWAP_MIRROR_VDEVS}

}

get_system_config()
{

    SERIAL=`kenv -q smbios.system.serial`
    MACS=`ifconfig -a -f ether:dash | grep ether | awk '{print "00-"$2}' | sort | xargs`    
    UUID=`sysctl -n kern.hostuuid`
    VENDOR=`kenv -q smbios.bios.vendor`
    if [ "${VENDOR}" != 'BHYVE' ]; then
        VENDOR=
    else 
        IS_BHYVE=1
    fi
        
    for c in defaults ${VENDOR} ${SERIAL} ${MACS} ${UUID}; do
        get_system_config_worker $c
    done
}

_SWAP_MIRRORS_NUM=0

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
    d=$1
    gpart destroy -F ${d}
}
gpart_create()
{
    d=$1
    gpart create -s GPT ${d}
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
    snum=`dmesg | grep ^${dev}: | grep 'Serial Number' | head -1 | awk '{print $4}' | rev | cut -c 1-6 | rev`
    
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
    elif [ "${GPTLABEL_NUMBERING}" = "count" ]; then
        num=${lnum}
    else 
        num=${lnum}
    fi
    
    gpart add -t ${ptype} ${psize} -i ${pnum} -l ${gptlabel}${num} ${dev}
}


find_ssds
#nas_ssd_gpart_only
burnin
