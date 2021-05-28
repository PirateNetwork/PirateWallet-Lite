#!/bin/bash

if [ -d res/qt ]; then
    rm -rf res/qt
fi

mkdir -p res/qt

curl http://mirrors.ocf.berkeley.edu/qt/archive/qt/5.15/5.15.2/single/qt-everywhere-src-5.15.2.tar.xz -o res/qt/qt-everywhere-src-5.15.2.tar.xz
tar -C res/qt -vxf res/qt/qt-everywhere-src-5.15.2.tar.xz
rm -f res/qt/qt-everywhere-src-5.15.2.tar.xz
cd ./res/qt/qt-everywhere-src-5.15.2

QT_CONFIG="-opensource"
QT_CONFIG="$QT_CONFIG -confirm-license"
QT_CONFIG="$QT_CONFIG -static"
QT_CONFIG="$QT_CONFIG -release"
QT_CONFIG="$QT_CONFIG -ltcg"

QT_CONFIG="$QT_CONFIG -no-pch"
QT_CONFIG="$QT_CONFIG -no-egl"
QT_CONFIG="$QT_CONFIG -no-eglfs"
QT_CONFIG="$QT_CONFIG -no-glib"
QT_CONFIG="$QT_CONFIG -no-icu"
QT_CONFIG="$QT_CONFIG -no-iconv"
QT_CONFIG="$QT_CONFIG -no-kms"
QT_CONFIG="$QT_CONFIG -no-linuxfb"
QT_CONFIG="$QT_CONFIG -no-libproxy"
QT_CONFIG="$QT_CONFIG -no-libudev"
QT_CONFIG="$QT_CONFIG -no-mtdev"
QT_CONFIG="$QT_CONFIG -no-openvg"
QT_CONFIG="$QT_CONFIG -no-reduce-relocations"
QT_CONFIG="$QT_CONFIG -no-qml-debug"
QT_CONFIG="$QT_CONFIG -no-sctp"
QT_CONFIG="$QT_CONFIG -no-securetransport"
QT_CONFIG="$QT_CONFIG -no-sql-db2"
QT_CONFIG="$QT_CONFIG -no-sql-ibase"
QT_CONFIG="$QT_CONFIG -no-sql-oci"
QT_CONFIG="$QT_CONFIG -no-sql-tds"
QT_CONFIG="$QT_CONFIG -no-sql-mysql"
QT_CONFIG="$QT_CONFIG -no-sql-odbc"
QT_CONFIG="$QT_CONFIG -no-sql-psql"
QT_CONFIG="$QT_CONFIG -no-sql-sqlite"
QT_CONFIG="$QT_CONFIG -no-sql-sqlite2"
QT_CONFIG="$QT_CONFIG -no-system-proxies"
QT_CONFIG="$QT_CONFIG -no-use-gold-linker"

QT_CONFIG="$QT_CONFIG -qt-libjpeg"
QT_CONFIG="$QT_CONFIG -qt-libpng"
QT_CONFIG="$QT_CONFIG -qt-pcre"
QT_CONFIG="$QT_CONFIG -qt-harfbuzz"
QT_CONFIG="$QT_CONFIG -system-zlib"

QT_CONFIG="$QT_CONFIG -nomake examples"
QT_CONFIG="$QT_CONFIG -nomake tests"
QT_CONFIG="$QT_CONFIG -nomake tools"
QT_CONFIG="$QT_CONFIG -skip webengine"
QT_CONFIG="$QT_CONFIG -v"

./configure -prefix "$PWD/static" $QT_CONFIG

make install
