#!/bin/bash

if [ -z $QT_STATIC ]; then
    echo "QT_STATIC is not set. Please set it to the base directory of a statically compiled Qt";
    exit 1;
fi

rm -f res/*.qm
$QT_STATIC/bin/lrelease piratewallet-lite-mingw.pro

# Then update the qt base translations. First, get all languages
ls res/*.qm | awk -F '[_.]' '{print $4}' | while read -r language ; do
    if [ -f $QT_STATIC/translations/qtbase_$language.qm ]; then
        $QT_STATIC/bin/lconvert -o res/arrr_$language.qm $QT_STATIC/translations/qtbase_$language.qm res/arrr_qt_wallet_$language.qm
        mv res/arrr_$language.qm res/arrr_qt_wallet_$language.qm
    fi
done
