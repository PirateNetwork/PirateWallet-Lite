#!/bin/bash
if [ -z $QT_STATIC ]; then
    echo "QT_STATIC is not set. Please set it to the base directory of a statically compiled Qt";
    exit 1;
fi

if [ -z $APP_VERSION ]; then echo "APP_VERSION is not set"; exit 1; fi
if [ -z $PREV_VERSION ]; then echo "PREV_VERSION is not set"; exit 1; fi

echo -n "Version files.........."
# Replace the version number in the .pro file so it gets picked up everywhere
sed -i "s/${PREV_VERSION}/${APP_VERSION}/g" piratewallet-lite.pro > /dev/null

# Also update it in the README.md
sed -i "s/${PREV_VERSION}/${APP_VERSION}/g" README.md > /dev/null
echo "[OK]"

echo -n "Cleaning..............."
rm -rf bin/*
rm -rf artifacts/*
make distclean >/dev/null 2>&1
echo "[OK]"

echo ""
echo "[Building on" `lsb_release -r`"]"

echo -n "Configuring............"
QT_STATIC=$QT_STATIC bash src/scripts/dotranslations.sh >/dev/null
$QT_STATIC/bin/qmake piratewallet-lite.pro -spec linux-clang CONFIG+=release > /dev/null
echo "[OK]"


printf "Building Sodium Library...............\n"
printf "\n"
./res/libsodium/build.sh > /dev/null

printf "Building Rust Library...............\n"
printf "\n"
./res/libzecwalletlite/build.sh > /dev/null

printf "Building QT Wallet..............."
rm -rf bin/piratewallet* > /dev/null
rm -rf release/ > /dev/null
make -j$(nproc) > /dev/null
printf "[OK]\n"



# Test for Qt
echo -n "Static link............"
if [[ $(ldd piratewallet-lite | grep -i "Qt") ]]; then
    echo "FOUND QT; ABORT";
    exit 1
fi
echo "[OK]"


echo -n "Packaging.............."
mkdir bin/piratewallet-lite-v$APP_VERSION > /dev/null
strip piratewallet-lite

cp piratewallet-lite                 bin/piratewallet-lite-v$APP_VERSION > /dev/null
cp README.md                      bin/piratewallet-lite-v$APP_VERSION > /dev/null
cp LICENSE                        bin/piratewallet-lite-v$APP_VERSION > /dev/null

cd bin && tar czf linux-piratewallet-lite-v$APP_VERSION.tar.gz piratewallet-lite-v$APP_VERSION/ > /dev/null
cd ..

mkdir artifacts >/dev/null 2>&1
cp bin/linux-piratewallet-lite-v$APP_VERSION.tar.gz ./artifacts/linux-binaries-piratewallet-lite-v$APP_VERSION.tar.gz
echo "[OK]"


if [ -f artifacts/linux-binaries-piratewallet-lite-v$APP_VERSION.tar.gz ] ; then
    echo -n "Package contents......."
    # Test if the package is built OK
    if tar tf "artifacts/linux-binaries-piratewallet-lite-v$APP_VERSION.tar.gz" | wc -l | grep -q "4"; then
        echo "[OK]"
    else
        echo "[ERROR]"
        exit 1
    fi
else
    echo "[ERROR]"
    exit 1
fi

echo -n "Building deb..........."
debdir=bin/deb/piratewallet-lite-v$APP_VERSION
mkdir -p $debdir > /dev/null
mkdir    $debdir/DEBIAN
mkdir -p $debdir/usr/local/bin

cat src/scripts/control | sed "s/RELEASE_VERSION/$APP_VERSION/g" > $debdir/DEBIAN/control

cp piratewallet-lite                   $debdir/usr/local/bin/

mkdir -p $debdir/usr/share/pixmaps/
cp res/piratewallet-lite.xpm           $debdir/usr/share/pixmaps/

mkdir -p $debdir/usr/share/applications
cp src/scripts/desktopentry    $debdir/usr/share/applications/piratewallet-lite.desktop

dpkg-deb --build $debdir >/dev/null
cp $debdir.deb                 artifacts/linux-deb-piratewallet-lite-v$APP_VERSION.deb
echo "[OK]"



echo ""
echo "[Windows]"

if [ -z $MXE_PATH ]; then
    echo "MXE_PATH is not set. Set it to ~/github/mxe/usr/bin if you want to build Windows"
    echo "Not building Windows"
    exit 0;
fi

export PATH=$MXE_PATH:$PATH

echo -n "Configuring............"
make clean  > /dev/null
#rm -f pirate-qt-wallet-mingw.pro
rm -rf bin/piratewallet* > /dev/null
rm -rf release/ > /dev/null

#Mingw seems to have trouble with precompiled headers, so strip that option from the .pro file
#cat pirate-qt-wallet.pro | sed "s/precompile_header/release/g" | sed "s/PRECOMPILED_HEADER.*//g" > pirate-qt-wallet-mingw.pro
echo "[OK]"

printf "Building Sodium Library...............\n"
./res/libsodium/build-win.sh > /dev/null
printf "[OK]\n"

printf "Building Rust Library...............\n"
./res/libzecwalletlite/build-win.sh > /dev/null
printf "[OK]\n"


printf "Building QT Wallet..............."
# Build the lib first
# cd lib && make winrelease && cd ..
x86_64-w64-mingw32.static-qmake-qt5 piratewallet-lite-mingw.pro CONFIG+=release > /dev/null
make -j32 -Winvalid-pch > /dev/null
echo "[OK]"


echo -n "Packaging.............."
mkdir release/piratewallet-lite-v$APP_VERSION
cp release/piratewallet-lite.exe          release/piratewallet-lite-v$APP_VERSION
cp README.md                          release/piratewallet-lite-v$APP_VERSION
cp LICENSE                            release/piratewallet-lite-v$APP_VERSION
cd release && zip -r Windows-binaries-piratewallet-lite-v$APP_VERSION.zip piratewallet-lite-v$APP_VERSION/ > /dev/null
cd ..

mkdir artifacts >/dev/null 2>&1
cp release/Windows-binaries-piratewallet-lite-v$APP_VERSION.zip ./artifacts/
echo "[OK]"

if [ -f artifacts/Windows-binaries-piratewallet-lite-v$APP_VERSION.zip ] ; then
    echo -n "Package contents......."
    if unzip -l "artifacts/Windows-binaries-piratewallet-lite-v$APP_VERSION.zip" | wc -l | grep -q "9"; then
        echo "[OK]"
    else
        echo "[ERROR]"
        exit 1
    fi
else
    echo "[ERROR]"
    exit 1
fi
