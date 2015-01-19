#!/bin/bash
# Copyright 2015 Axel Etcheverry
# Distributed under the terms of the MIT

GENTOO_FUNC=${PORTAGE_BIN_PATH:-/usr/lib/portage/bin}/isolated-functions.sh

if [ ! -f $GENTOO_FUNC ]; then
    source eapi.sh
else
    source "${GENTOO_FUNC}"
fi
DATA_DIR=$(pwd)/data
LAST_STAGE3_LOCK="$HOME/.stage3"
LAST_STAGE3="0"

ebegin "Fetch latest stage3"
STAGE3=$(wget -O - http://distfiles.gentoo.org/releases/amd64/autobuilds/latest-stage3-amd64.txt 2> /dev/null | sed -n 3p | awk -F'/' '{ print $1}')
eend $?

if [ -f $LAST_STAGE3_LOCK ]; then
    LAST_STAGE3=$(cat $LAST_STAGE3_LOCK)
fi

if [ "$STAGE3" == "$LAST_STAGE3" ]; then
    einfo "Stage3 is already the latest version"
    exit 0
fi

if [ ! -d $DATA_DIR ]; then
    mkdir -p $DATA_DIR
fi

einfo "Release: ${STAGE3:0:4}-${STAGE3:4:2}-${STAGE3:6}"

STAGE3_FILE="$DATA_DIR/stage3-amd64-$STAGE3.tar.bz2"

SRC="http://distfiles.gentoo.org/releases/amd64/autobuilds/$STAGE3/stage3-amd64-$STAGE3.tar.bz2"

ebegin "Download stage3-amd64-$STAGE3.tar.bz2"
wget -N "$SRC" -O "$STAGE3_FILE" > /dev/null 1> /dev/null 2> /dev/null
eend $?

ebegin "Transforming bz2 tarball to xz"
bunzip2 -c "$STAGE3_FILE" | xz -z > "$DATA_DIR/stage3-amd64-$STAGE3.tar.xz"
eend $?

ebegin "Deleting stage3-amd64-$STAGE3.tar.bz2"
rm -rf "$STAGE3_FILE"
eend $?

ebegin "Update Dockerfile"
sed -e 's/stage3-amd64-\(.*\).tar.xz/stage3-amd64-$STAGE3.tar.xz/g' -i Dockerfile
eend $?

ebegin "Commit Dockerfile"
git commit -m "chore(dockerfile): Update stage3 to $STAGE3" Dockerfile > /dev/null
eend $?

ebegin "Create git tag"
git tag -a $STAGE3 -m "[release] ${STAGE3:0:4}-${STAGE3:4:2}-${STAGE3:6}"
eend $?

echo "$STAGE3" > $LAST_STAGE3_LOCK


