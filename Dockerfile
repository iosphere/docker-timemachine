FROM ubuntu:14.04
MAINTAINER Óscar de Arriba <odarriba@gmail.com>

##################
##   BUILDING   ##
##################

# Prerequisites
RUN apt-get --quiet --yes update
ENV DEBIAN_FRONTEND noninteractive
RUN ln -s -f /bin/true /usr/bin/chfn

# Versions to use
ENV libevent_version 2.0.22-stable
ENV netatalk_version 3.1.8
ENV dev_libraries libcrack2-dev libwrap0-dev autotools-dev libdb-dev libacl1-dev libdb5.3-dev libgcrypt11-dev libtdb-dev libkrb5-dev

# Install prerequisites:
RUN apt-get --quiet --yes install build-essential nano htop wget pkg-config checkinstall automake libtool db-util db5.3-util libgcrypt11 ${dev_libraries}

# Compiling netatalk
WORKDIR /usr/local/src
RUN wget http://prdownloads.sourceforge.net/netatalk/netatalk-${netatalk_version}.tar.gz \
	&& tar xvf netatalk-${netatalk_version}.tar.gz \
	&& cd netatalk-${netatalk_version} \
	&& ./configure \
		--enable-debian \
		--enable-krbV-uam \
		--disable-zeroconf \
		--enable-krbV-uam \
		--enable-tcp-wrappers \
		--with-cracklib \
		--with-acls \
		--with-dbus-sysconf-dir=/etc/dbus-1/system.d \
		--with-init-style=debian-sysv \
		--with-pam-confdir=/etc/pam.d \
	&& make \
	&& checkinstall \
		--pkgname=netatalk \
		--pkgversion=$netatalk_version \
		--backup=no \
		--deldoc=yes \
		--default \
		--fstrans=no

# grab gosu for easy step-down from root
ENV GOSU_VERSION 1.7
RUN set -x \
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
	&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
	&& gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
	&& rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu \
	&& gosu nobody true

# Add default user and group
RUN  mkdir -p /timemachine

# Create the log file
RUN touch /var/log/afpd.log

ADD start_services.sh /start_services.sh
RUN update-rc.d netatalk defaults

EXPOSE 548 636

VOLUME ["/timemachine"]

CMD [ "/bin/bash", "/start_services.sh" ]
