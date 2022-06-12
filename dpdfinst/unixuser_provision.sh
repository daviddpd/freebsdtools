#!/bin/sh
set -x
### DNS /etc/resolv.conf 

: ${REMOTE_SCRIPTS_HTTP:="http://pkg.ixsystems.com/freebsd/ixconfig"}
: ${REMOTE_CONFD_HTTP:="http://pkg.ixsystems.com/freebsd/ixconfig.d"}
: ${ADMIN_CONFIG:="ix-admins.conf"}
: ${TMPDIR:="/tmp/ixtmp"}
: ${_USER:="$1"}
: ${_GROUP:="$2"} # addition group ?



http_fetch_user()
{

    fetch -o ${TMPDIR} ${REMOTE_CONFD_HTTP}/.SSHKEYS/SSHKEY_${1}
    fetch -o ${TMPDIR} ${REMOTE_CONFD_HTTP}/.USERS/PASSWD_${1}
    
}


if [ -z "${_USER}" ]; then
    echo "please tell me a user to add"
    exit;
fi

if [ ! -d "${TMPDIR}" ]; then
    mkdir -p ${TMPDIR}
fi

http_fetch_user $_USER
# mv ${TMPDIR}/${_USER} 
# convert to adduser format - move pwhash to end;
PWHASH=`awk -F : '{print $2}' ${TMPDIR}/PASSWD_${_USER}`
GID=`awk -F : '{print $4}' ${TMPDIR}/PASSWD_${_USER}`
pw groupadd ${_USER} -g ${GID}

cut -d : -f 1,3,4,5,6,7,8,9,10 ${TMPDIR}/PASSWD_${_USER} > ${TMPDIR}/ADDUSER_${_USER}

if [ -z "${_GROUP}" ]; then
    adduser -f ${TMPDIR}/ADDUSER_${_USER} 
else 
    adduser -f ${TMPDIR}/ADDUSER_${_USER} -G ${_GROUP}
fi

chpass -p ${PWHASH} ${_USER}
su -l ${_USER} -c "mkdir .ssh"
su -l ${_USER} -c "cp -v ${TMPDIR}/SSHKEY_${_USER} .ssh/authorized_keys"

rm -rf ${TMPDIR}

