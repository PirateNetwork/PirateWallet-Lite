#!/bin/bash

#cd /tmp

FILE=openssl-1.1.1e.tar.gz
if [ -f "$FILE" ]; then
    echo "$FILE exists"
else
    wget https://www.openssl.org/source/old/1.1.1/openssl-1.1.1e.tar.gz
    tar xvf openssl-1.1.1e.tar.gz
fi

cd openssl-1.1.1e/

rm -rf x86_64-pc-windows-gnu
mkdir x86_64-pc-windows-gnu

make clean
make distclean

./Configure --prefix=/$PWD/openssl-1.1.1e/x86_64-pc-windows-gnu  x86_64-pc-windows-gnu
make -j$(nproc)
make -j$(nproc) install

make clean
make distclean
