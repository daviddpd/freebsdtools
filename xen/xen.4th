\ Copyright (c) 2014 David P. Discher <dpd@dpdtech.com>
\ All rights reserved.
\
\ Redistribution and use in source and binary forms, with or without
\ modification, are permitted provided that the following conditions
\ are met:
\ 1. Redistributions of source code must retain the above copyright
\    notice, this list of conditions and the following disclaimer.
\ 2. Redistributions in binary form must reproduce the above copyright
\    notice, this list of conditions and the following disclaimer in the
\    documentation and/or other materials provided with the distribution.
\
\ THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
\ ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
\ IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
\ ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
\ FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
\ DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
\ OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
\ HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
\ LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
\ OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
\ SUCH DAMAGE.
\
\ $FreeBSD$


\ This is a 4th loader script to pre-load the Xen microkernel, then function the loader 
\ will boot Xen + FreeBSD as Dom0 seamlessly, including the menu, beastie, etc.
\ 
\ To use this, two lines are needed in loader.rc.  Add :
\ 
\ 	include /boot/xen.4th
\ 	xen-start
\ 	
\ after "include /boot/beastie.4th", but before "beastie-start". Ideally, this should see
\ deeper integration into the other 4th scripts, possibly even into beastie-start.
\ 
\ There are two loader.conf options that are also needed.  
\ 
\ 	xen_boot="YES"
\ 	xen_kernel="/boot/xen"
\ 	
\ xen_boot controls if we boot the hypervisor or not. and xen_kernel is the path
\ to the xen microkernel. 


: xen-start ( -- ) \ checks if we are Xen
	." Checking xen_boot ... " cr
	s" xen_boot" getenv
	s" YES" compare-insensitive 0= if
		." xen_boot = yes, loading xen kernel ... " cr	
		s" load ${xen_kernel}"  evaluate \ tell the boot loader to load it.
	then
;


