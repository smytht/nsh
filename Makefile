#
PROG= nsh

SUBDIR += bgpnsh nshdoas

.PHONY: release dist

.include "nsh-version.mk"

.if ${NSH_RELEASE} != Yes
DEBUG?=-O0 -g
.endif


.if make(install)
PREFIX?=/usr/local
BINDIR?=${PREFIX}/bin
MANDIR?=${PREFIX}/man/man
.endif

# For use with flashrd:
#CFLAGS=-O -DDHCPLEASES=\"/flash/dhcpd.leases\" -Wmissing-prototypes -Wformat -Wall -Wpointer-arith -Wbad-function-cast #-W
CFLAGS?=-O
CFLAGS+=-Wmissing-prototypes -Wformat -Wall -Wbad-function-cast -I/usr/local/include #-W -Wpointer-arith
CPPFLAGS+=-DNSH_VERSION=${NSH_VERSION}

SRCS=arp.c compile.c main.c genget.c commands.c bgpcommands.c stats.c kroute.c
SRCS+=ctl.c show.c if.c version.c route.c conf.c complete.c ieee80211.c
SRCS+=bridge.c tunnel.c media.c sysctl.c passwd.c pfsync.c carp.c
SRCS+=trunk.c who.c more.c stringlist.c utils.c sqlite3.c ppp.c prompt.c
SRCS+=nopt.c pflow.c wg.c nameserver.c ndp.c umb.c utf8.c cmdargs.c ctlargs.c
SRCS+=helpcommands.c makeargv.c hashtable.c mantab.c
CLEANFILES+=compile.c mantab.c

LDADD=-lutil -ledit -ltermcap

.if make(static)
NSH_SQLITE_LIBS!=/usr/bin/pkg-config --libs --static sqlite3
.else
NSH_SQLITE_LIBS!=/usr/bin/pkg-config --libs sqlite3
.endif
LDADD+=${NSH_SQLITE_LIBS}

.if make(static)
LDADD+=-static
.endif

MAN=nsh.8

# convenience target for producing statically linked binaries
static: $(PROG)
	${MAKE} -C ${.CURDIR}/bgpnsh static
	${MAKE} -C ${.CURDIR}/nshdoas static

compile.c: compile.sh *.c *.h
	sh ${.CURDIR}/compile.sh

mantab.c: mantab.sh nsh.8
	sh ${.CURDIR}/mantab.sh ${.CURDIR}/nsh.8 > mantab.c

afterinstall:
	test -e ${DESTDIR}${PREFIX}/bin/save.sh || install -m 755 -o root -g bin \
		${.CURDIR}/save-rw.sh ${DESTDIR}${PREFIX}/bin/save.sh

release: clean
	sed -i -e "s/_RELEASE=No/_RELEASE=Yes/" ${.CURDIR}/nsh-version.mk
	${MAKE} -C ${.CURDIR} dist
	sed -i -e "s/_RELEASE=Yes/_RELEASE=No/" ${.CURDIR}/nsh-version.mk

dist: clean
	mkdir /tmp/nsh-${NSH_VERSION}
	(cd ${.CURDIR} && pax -rw * /tmp/nsh-${NSH_VERSION})
	find /tmp/nsh-${NSH_VERSION} -name obj -type d -delete
	rm /tmp/nsh-${NSH_VERSION}/nsh-dist.txt
	tar -C /tmp -zcf ${.CURDIR}/nsh-${NSH_VERSION}.tar.gz nsh-${NSH_VERSION}
	rm -rf /tmp/nsh-${NSH_VERSION}
	tar -ztf ${.CURDIR}/nsh-${NSH_VERSION}.tar.gz | \
		sed -e 's/^nsh-${NSH_VERSION}//' | \
		sort > ${.CURDIR}/nsh-dist.txt.new
	diff -u ${.CURDIR}/nsh-dist.txt ${.CURDIR}/nsh-dist.txt.new
	rm ${.CURDIR}/nsh-dist.txt.new

.include <bsd.prog.mk>
.include <bsd.subdir.mk>
