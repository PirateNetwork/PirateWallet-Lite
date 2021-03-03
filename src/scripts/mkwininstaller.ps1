param (
    [Parameter(Mandatory=$true)][string]$version
)

$target="zerwallet-lite-v$version"

Remove-Item -Path release/wininstaller -Recurse -ErrorAction Ignore  | Out-Null
New-Item release/wininstaller -itemtype directory                    | Out-Null

Copy-Item release/$target/zerwallet-lite.exe     release/wininstaller/
Copy-Item release/$target/LICENSE                release/wininstaller/

Get-Content src/scripts/zer-qt-wallet.wxs | ForEach-Object { $_ -replace "RELEASE_VERSION", "$version" } | Out-File -Encoding utf8 release/wininstaller/zer-qt-wallet.wxs

candle.exe release/wininstaller/zer-qt-wallet.wxs -o release/wininstaller/zer-qt-wallet.wixobj 
if (!$?) {
    exit 1;
}

light.exe -ext WixUIExtension -cultures:en-us release/wininstaller/zer-qt-wallet.wixobj -out release/wininstaller/zerwallet-lite.msi 
if (!$?) {
    exit 1;
}

New-Item artifacts -itemtype directory -Force | Out-Null
Copy-Item release/wininstaller/zerwallet-lite.msi ./artifacts/Windows-installer-$target.msi