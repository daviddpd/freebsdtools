#!/bin/sh

RCD_ENABLES="care2_firstboot:care2_firstboot_enable=YES"

if [ -n "${RCD_ENABLES}" ]; then
    for rcd in "${RCD_ENABLES}"; do
        rcdfile=`echo "${rcd}" | awk -F: '{print $1}'`
        rcdvar=`echo "${rcd}" | awk -F: '{print $2}'`
        if [ ! -f "${rcdfile}" ]; then
            touch ${rcdfile}
        fi
        echo  ${rcdvar} >> ${rcdfile}
    done
fi