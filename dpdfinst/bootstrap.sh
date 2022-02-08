#!/bin/sh
# $Id$

# PROVIDE: bootstrap
# REQUIRE: mdinit tmp var dhclient LOGIN
# KEYWORD: FreeBSD

. /etc/rc.subr

name="bootstrap"
start_cmd="bootstrap_start"
stop_cmd=":"

bootstrap_start()
{

    export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/root/bin

    cat /etc/motd

    _interfaces=`ifconfig -l ether`
    pgrep dhclient > /dev/null
    if [ $? -ne 0 ]; then
        if [ ! -f "/var/db/dhclient.leases" ]; then
            echo "================================================================"
            echo " ==> Attempting to DHCP via the $0 for ${_interfaces} <==== "
            echo "================================================================"
            /usr/local/sbin/dhclient -v -cf /etc/dhclient-dpdfinstpxe.conf ${_interfaces}
        fi
    fi
    echo "================================================================"
    echo " ==> System Boot Strap system for installation/burnin <==== "
    echo "================================================================"

    loop=5
    while [ ${loop} -ne 0 ]; do
        _route=`route -n get default | grep gateway | awk '{print $2}'`
        if [ -n "${_route}" ]; then
            echo -n "Waiting for ${_route} to respond to ICMP ping ... "
            /sbin/ping -W 1000 -t 3 -c 3 -o ${_route} >/dev/null 2>&1
            rc=$?
            if [ $rc -eq 0 ]; then
                echo " ok."
                echo -n " Setting time ...  "
                /usr/sbin/ntpdate ${_route}
            else
                echo " failed"
            fi
        fi
        if [ -f "/var/db/dhclient.leases" ]; then
            grep 'option dpdfinst.' /var/db/dhclient.leases | sed -e 's/^  option //' | sed -e 's/dpdfinst\./dpdfinst_/' | sed -e 's/ /=/' > /etc/dpdfinstd.conf
            serial=`/bin/kenv -q smbios.system.serial | sed -e 's/\./-/g' `
            if [ -f "/etc/dpdfinstd.conf" ]; then
                . /etc/dpdfinstd.conf
                if [ -z "${dpdfinst_bootstrap}" ]; then
                    echo "$0: dpdfinst.bootstrap dhcp option is undefined, so bootstrap is disabled."
                    echo -n "$0: Failed to bootstrap."
                    loop=$((loop-1))
                    sleep 5
                else
                    loop=0
                fi
            fi
        else
            echo "$0: Can't find DHCP Client Lease File"
            sleep 5
        fi
    done

    if [ -f "/etc/dpdfinstd.conf" ]; then
        . /etc/dpdfinstd.conf
        if [ -z "$dpdfinst_bootstrap" ]; then
            echo "$0: dpdfinst.bootstrap dhcp option is undefined, so bootstrap is disabled."
            echo "$0: Failed to bootstrap."
            exit
        fi
    else
        echo "Can't find /etc/dpdfinstd.conf."
        echo  "$0: Failed to bootstrap."
        exit
    fi


    if [ -f "/tmp/${dpdfinst_bootstrap}" ]; then
        rm -f /tmp/${dpdfinst_bootstrap}
    fi

    if [ -z ${dpdfinst_host_api1_protocol} ]; then
        apiurl="http://${dpdfinst_host_api1}${dpdfinst_api1_path}/${dpdfinst_api1_version}/${dpdfinst_bootstrap}"
    else
        apiurl="${dpdfinst_host_api1_protocol}://${dpdfinst_host_api1}${dpdfinst_api1_path}/${dpdfinst_api1_version}/${dpdfinst_bootstrap}"
    fi

    curlopt="--connect-timeout 10 --retry 20 --retry-connrefused  --retry-delay 10 "
    fetchopt="--timeout 10  --retry --retry-delay 10 "
    while [ ! -f "/tmp/${dpdfinst_bootstrap}" ]; do
        echo " ==> dpdfinst system Boot : Attempting to fetch ${apiurl} <==== "
        sleep 1
        if [ -f "/usr/local/bin/curl" ]; then
            /usr/local/bin/curl ${curlopt} -o /tmp/${dpdfinst_bootstrap} ${apiurl}
        else
            /usr/bin/fetch ${fetchopt} -o /tmp/${dpdfinst_bootstrap} ${apiurl}
        fi
        if [ -f "/tmp/${dpdfinst_bootstrap}" ]; then
            chmod 755 /tmp/${dpdfinst_bootstrap}
            /tmp/${dpdfinst_bootstrap}
        fi
    done


}

load_rc_config $name
run_rc_command "$1"
