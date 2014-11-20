freebsdtools/vimage
============

vnet
An RC script, based generally on a post from "Joe", as 
posted over on freebsd-jails@ mailing list in April 2013.

 http://lists.freebsd.org/pipermail/freebsd-jail/2013-April/002212.html
 
Email attempts to contact Joe bounced.

Use at your own risk
=====

The start seems to work ok.  The stopping still needs some working
on.  Modified with static "jid"s, thinking that using a static epair number
the jails rc.conf could bring up the interfance. But the interface gets added
to the jail AFTER RC has run.

