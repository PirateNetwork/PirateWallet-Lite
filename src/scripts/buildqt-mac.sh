#!/bin/bash
QT_FOLDER="5.15"
QT_VERSION="5.15.2"


if [ -d res/qt ]; then
    rm -rf res/qt
fi

mkdir -p res/qt
mkdir -p res/qt/shadowbuild

curl http://mirrors.ocf.berkeley.edu/qt/archive/qt/$QT_FOLDER/$QT_VERSION/single/qt-everywhere-src-$QT_VERSION.tar.xz -o res/qt/qt-everywhere-src-$QT_VERSION.tar.xz
tar -C res/qt -vxf res/qt/qt-everywhere-src-$QT_VERSION.tar.xz
rm -f res/qt/qt-everywhere-src-$QT_VERSION.tar.xz
cd ./res/qt/
QT_INSTALL="$PWD/static"

cd shadowbuild

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
QT_CONFIG="$QT_CONFIG -no-sctp"
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

QT_CONFIG="$QT_CONFIG -skip qtactiveqt"
QT_CONFIG="$QT_CONFIG -skip qtconnectivity"
QT_CONFIG="$QT_CONFIG -skip qt3d"
QT_CONFIG="$QT_CONFIG -skip qtcanvas3d"
QT_CONFIG="$QT_CONFIG -skip qtdatavis3d"
QT_CONFIG="$QT_CONFIG -skip qtcharts"
QT_CONFIG="$QT_CONFIG -skip qtlocation"
QT_CONFIG="$QT_CONFIG -skip qtsensors"
QT_CONFIG="$QT_CONFIG -skip qtdeclarative"
QT_CONFIG="$QT_CONFIG -skip qtdoc"
QT_CONFIG="$QT_CONFIG -skip qtgraphicaleffects"
QT_CONFIG="$QT_CONFIG -skip qtmultimedia"
QT_CONFIG="$QT_CONFIG -skip qtquickcontrols"
QT_CONFIG="$QT_CONFIG -skip qtquickcontrols2"
QT_CONFIG="$QT_CONFIG -skip qtpurchasing"
QT_CONFIG="$QT_CONFIG -skip qtremoteobjects"
QT_CONFIG="$QT_CONFIG -skip qtsensors"
QT_CONFIG="$QT_CONFIG -skip qtserialport"
QT_CONFIG="$QT_CONFIG -skip qtwebchannel"
QT_CONFIG="$QT_CONFIG -skip qtgamepad"
QT_CONFIG="$QT_CONFIG -skip qtscript"
QT_CONFIG="$QT_CONFIG -skip qtserialbus"
QT_CONFIG="$QT_CONFIG -skip qtvirtualkeyboard"
QT_CONFIG="$QT_CONFIG -skip qtwayland"
QT_CONFIG="$QT_CONFIG -skip qtwebview"
QT_CONFIG="$QT_CONFIG -skip qtwebglplugin"
QT_CONFIG="$QT_CONFIG -skip qtxmlpatterns"
QT_CONFIG="$QT_CONFIG -skip qtwebengine"

QT_CONFIG="$QT_CONFIG -v"

../qt-everywhere-src-$QT_VERSION/configure -prefix $QT_INSTALL $QT_CONFIG >> config.log

make install
