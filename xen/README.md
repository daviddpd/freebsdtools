Xen+FreeBSD Dom0 boot script
============

This is a 4th loader script to pre-load the Xen microkernel, then function the loader 
will boot Xen + FreeBSD as Dom0 seamlessly, including the menu, beastie, etc.

To use this, two lines are needed in loader.rc.  Add :

	include /boot/xen.4th
	xen-start
	
after "include /boot/beastie.4th", but before "beastie-start". Ideally, this should see
deeper integration into the other 4th scripts, possibly even into beastie-start.

There are two loader.conf options that are also needed.  

	xen_boot="YES"
	xen_kernel="/boot/xen"
	
xen_boot controls if we boot the hypervisor or not. and xen_kernel is the path
to the xen microkernel. 

