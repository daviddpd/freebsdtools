# dpd's FreeBSD (Networking/PXE) Installer 

## Background

Over the years, I've written at least two, if not three or four wrapper scripts for doing automated FreeBSD Installations - I've always regretted not formalizing it some many years ago, so finally doing so now. 

## Usage

### config 

#### Mandatory config items

 - `REMOTE_RELEASE_HTTP`
   - This is the path of "[...]/amd64.amd64/12.1-STABLE/current/ftp/" created by "make release"
 - `REMOTE_PKG_URL`
   - remote pkg dist repo.  output dir from poudriere `/usr/local/poudriere/data/packages/{NAME}`
 - `REMOTE_CONFD_HTTP`
   - this `dpdfinst.cfg` diretory, similar to pxelinux.cfg structure 
 - `REMOTE_SCRIPTS_HTTP`
   - auxiliary scripts used, these are optionally defined as :
     - PKG_SET
     - PKG_INSTALLER
     - ADMIN_CONFIG
     - USER_PROVISION
 - `ROOT_DISK_ZPOOL`
 	-  disk layout to use

#### Default things to customize 

  - `ROOT_DISK_ZPOOL_NAME:="z"`
    - default zpool name
  - `DISK_ZPOOL_PROTECT_NAMES:=`
    - names of zpool to not destroy
  - `GPTLABEL_NUMBERING:="serial"`
    - The name used for /dev/gpt/* "glabel" - a simple count or disk serial : Simple incrementing count, rel to zero; or the last 6 chars of the disks serial number.
  - `ROOT_PART_SIZE_EFI:="800k"`
    - EFI Partition Size, always index 1
  - `ROOT_PART_SIZE_BOOT:="512k`
    - freebsd-boot partition size, always index 2
  - `ROOT_PART_SIZE_SWAP:="8G"`		
    - partition for swap on root block devices, always index 3
  - `ROOT_PART_SWAP:=1`
    - create swap partition, 
  - `SWAP_ON_ZROOT:=0`
    - boolean, create swap on the root zpool instead of as a gpt partition
  - `ROOT_PART_SIZE_ZFS:=0`
    - size of zroot gpart partition (vdev), 0=auto, use remaning space.
  - `DATA_PART_SIZE_ZFS:=0`
    - unused space per disk, add a partition for "data".
  - `BOOTCODE_SKIP`
    - IFDEFNED,  do not install bootcode, pmbr and gptzfsboot
  - `ZPOOL_RAIDZ:="1"`
    - 1 OR 2 : RAIDZ 1 (RAID-5) or RAIDZ 2 (RAID-6)
      - `ZPOOL_RAIDZ1_NVEDS:="4"`
        - NUMBER OF VDEVS NEEDS FOR RAIDZ 1
      - `ZPOOL_RAIDZ2_NVEDS:="5"`
        - NUMBER OF VDEVS NEEDS FOR RAIDZ 2        
  - `INSTALL_DEBUG`
    - IFDEFNED, install the dbg.txz packages 
  - `INSTALL_PORTS`
    - IFDEFNED, install /usr/ports
  - `INSTALL_SRC`
    - IFDEFNED, install /usr/src
  - `TMPDIR:="/tmp/finsttmp"`
  	- tmp directory.
  - networking, ideally these are defined, dynamically per host with config files in REMOTE_CONFD_HTTP
	- NIC:=
	- IP:=
	- NETMASK:=
	- ROUTE_DEFAULT:=
	- HOSTNAME:=
	- SERIAL:=
	- MACS:=
	- NICS:=`ifconfig -l`
