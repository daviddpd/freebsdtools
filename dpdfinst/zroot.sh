ROOT_DISK_ZPOOL_NAME="z"
#Container for boot environments beadm(1M) compatible setup
zfs create -o canmount=off -o mountpoint=none ${ROOT_DISK_ZPOOL_NAME}/ROOT
zfs create -o canmount=off -o mountpoint=none ${ROOT_DISK_ZPOOL_NAME}/COMMON
zfs create -o mountpoint=/ ${ROOT_DISK_ZPOOL_NAME}/ROOT/default
zfs create -o mountpoint=/${ROOT_DISK_ZPOOL_NAME}2 ${ROOT_DISK_ZPOOL_NAME}/ROOT/secondary

#Things we want to be common across boot environments:
zfs create -o mountpoint=/var/log -o compression=gzip-9 ${ROOT_DISK_ZPOOL_NAME}/COMMON/log
zfs create -o mountpoint=/z/home ${ROOT_DISK_ZPOOL_NAME}/home
zfs create -o mountpoint=/tmp ${ROOT_DISK_ZPOOL_NAME}/COMMON/tmp
zfs create -o mountpoint=/var/tmp ${ROOT_DISK_ZPOOL_NAME}/COMMON/vartmp

