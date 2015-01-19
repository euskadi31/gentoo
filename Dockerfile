FROM scratch

MAINTAINER Axel Etcheverry <axel@etcheverry.biz>

# This one should be present by running the build.sh script
ADD http://dist.etcheverry.biz/gentoo/stage3/stage3-amd64-20141204.tar.xz /

# Add default config files
ADD ./etc/init.d/detect-cpu /etc/init.d/detect-cpu
ADD ./etc/portage/make.conf /etc/portage/make.conf
ADD ./etc/portage/cpu.conf /etc/portage/cpu.conf
ADD ./etc/eixrc /etc/eixrc
ADD ./etc/eix-sync.conf /etc/eix-sync.conf

# Setup the (virtually) current runlevel
RUN echo "default" > /run/openrc/softlevel

# Setup the rc_sys
RUN sed -e 's/#rc_sys=""/rc_sys="lxc"/g' -i /etc/rc.conf

# Setup the net.lo runlevel
RUN ln -s /etc/init.d/net.lo /run/openrc/started/net.lo

# Setup the net.eth0 runlevel
RUN ln -s /etc/init.d/net.lo /etc/init.d/net.eth0
RUN ln -s /etc/init.d/net.eth0 /run/openrc/started/net.eth0

# By default, UTC system
RUN echo 'UTC' > /etc/timezone

# Remove doc, man and info files
RUN rm -rf /usr/share/doc/*
RUN rm -rf /usr/share/man/*
RUN rm -rf /usr/share/info/*

# Update env
RUN env-update

# Add detect-cpu to boot
RUN rc-update add detect-cpu default

# Start detect-cpu
RUN /etc/init.d/detect-cpu start

# Used when this image is the base of another
#
# Setup the portage directory and permissions
ONBUILD RUN mkdir -p /usr/portage/{distfiles,metadata,packages}
ONBUILD RUN chown -R portage:portage /usr/portage
ONBUILD RUN echo "masters = gentoo" > /usr/portage/metadata/layout.conf

# Sync portage
ONBUILD RUN emerge-webrsync

# Display some news items
ONBUILD RUN eselect news read new

# Update env
ONBUILD RUN env-update

# unmerge unusd packages
# emerge -C sys-devel/libtool sys-devel/gcc
#ONBUILD RUN emerge -C virtual/editor virtual/ssh man sys-apps/man-pages sys-apps/openrc sys-fs/e2fsprogs sys-apps/texinfo virtual/service-manager"
ONBUILD RUN emerge -C virtual/editor virtual/ssh sys-apps/openrc sys-fs/e2fsprogs virtual/service-manager

# install default package
ONBUILD RUN emerge app-portage/eix app-editors/vim dev-vcs/git net-misc/curl

# Update eix
ONBUILD RUN eix-update

# Exec depclean
ONBUILD RUN emerge --depclean
