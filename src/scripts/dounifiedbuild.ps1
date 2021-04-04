# Unified build script for Windows, Linux and Mac builder. Run on a Windows machine inside powershell.
param (
    [Parameter(Mandatory=$true)][string]$version,
    [Parameter(Mandatory=$true)][string]$prev,
    [Parameter(Mandatory=$true)][string]$certificate,
    [Parameter(Mandatory=$true)][string]$username,
    [Parameter(Mandatory=$true)][string]$password,
    [Parameter(Mandatory=$true)][string]$server,
    [Parameter(Mandatory=$true)][string]$winserver
)


Write-Host "[Initializing]"
Remove-Item -Force -ErrorAction Ignore ./artifacts/linux-binaries-piratewallet-v$version.tar.gz
Remove-Item -Force -ErrorAction Ignore ./artifacts/linux-deb-piratewallet-v$version.deb
Remove-Item -Force -ErrorAction Ignore ./artifacts/Windows-binaries-piratewallet-v$version.zip
Remove-Item -Force -ErrorAction Ignore ./artifacts/Windows-installer-piratewallet-v$version.msi
Remove-Item -Force -ErrorAction Ignore ./artifacts/macOS-piratewallet-v$version.dmg
Remove-Item -Force -ErrorAction Ignore ./artifacts/signatures-v$version.tar.gz


Remove-Item -Recurse -Force -ErrorAction Ignore ./bin
Remove-Item -Recurse -Force -ErrorAction Ignore ./debug
Remove-Item -Recurse -Force -ErrorAction Ignore ./release

# Create the version.h file and update README version number
Write-Output "#define APP_VERSION `"$version`"" > src/version.h
Get-Content README.md | Foreach-Object { $_ -replace "$prev", "$version" } | Out-File README-new.md
Move-Item -Force README-new.md README.md
Write-Host ""


Write-Host "[Building on Mac]"
bash src/scripts/mkmacdmg.sh --qt_path ~/Qt/5.11.1/clang_64/ --version $version --certificate "$certificate" --username "$username" --password "$password"
if (! $?) {
    Write-Output "[Error]"
    exit 1;
}
Write-Host ""


Write-Host "[Building Linux + Windows]"
Write-Host -NoNewline "Copying files.........."
ssh $server "rm -rf /tmp/pqwbuild"
ssh $server "mkdir /tmp/pqwbuild"
scp -r src/ singleapplication/ res/ ./pirate-qt-wallet.pro ./application.qrc ./LICENSE ./README.md ${server}:/tmp/pqwbuild/ | Out-Null
ssh $server "dos2unix -q /tmp/pqwbuild/src/scripts/mkrelease.sh" | Out-Null
ssh $server "dos2unix -q /tmp/pqwbuild/src/version.h"
Write-Host "[OK]"

ssh $server "cd /tmp/pqwbuild && APP_VERSION=$version PREV_VERSION=$prev bash src/scripts/mkrelease.sh"
if (!$?) {
    Write-Output "[Error]"
    exit 1;
}

New-Item artifacts -itemtype directory -Force         | Out-Null
scp    ${server}:/tmp/pqwbuild/artifacts/* artifacts/ | Out-Null
scp -r ${server}:/tmp/pqwbuild/release .              | Out-Null

Write-Host -NoNewline "Building Installer....."
ssh $winserver "Remove-Item -Path pqwbuild -Recurse"   | Out-Null
ssh $winserver "New-Item pqwbuild -itemtype directory" | Out-Null

# Note: For some mysterious reason, we can't seem to do a scp from here to windows machine.
# So, we'll ssh to windows, and execute an scp command to pull files from here to there.
# Same while copying the built msi. A straight scp pull from windows to here doesn't work,
# so we ssh to windows, and then scp push the file to here.
$myhostname = (ipconfig getifaddr en0) | Out-String -NoNewline
# Powershell seems not to be able to remove this directory for some reason!
# Remove-Item -Path /tmp/pqwbuild -Recurse -ErrorAction Ignore | Out-Null
bash "rm -rf /tmp/pqwbuild" 2>&1 | Out-Null
New-Item    -Path /tmp/pqwbuild -itemtype directory -Force | Out-Null
Copy-Item src     /tmp/pqwbuild/ -Recurse -Force
Copy-Item res     /tmp/pqwbuild/ -Recurse -Force
Copy-Item release /tmp/pqwbuild/ -Recurse -Force

# Remove some unnecessary stuff from the tmp directory to speed up copying
Remove-Item -Recurse -ErrorAction Ignore /tmp/pqwbuild/res/libsodium

ssh $winserver "scp -r ${myhostname}:/tmp/pqwbuild/* pqwbuild/"
ssh $winserver "cd pqwbuild ; src/scripts/mkwininstaller.ps1 -version $version" >/dev/null
if (!$?) {
    Write-Output "[Error]"
    exit 1;
}
ssh $winserver "scp pqwbuild/artifacts/* ${myhostname}:/tmp/pqwbuild/"
Copy-Item /tmp/pqwbuild/*.msi artifacts/
Write-Host "[OK]"

# Finally, test to make sure all files exist
Write-Host -NoNewline "Checking Build........."
if (! (Test-Path ./artifacts/linux-binaries-piratewallet-v$version.tar.gz) -or
    ! (Test-Path ./artifacts/linux-deb-piratewallet-v$version.deb) -or
    ! (Test-Path ./artifacts/Windows-binaries-piratewallet-v$version.zip) -or
    ! (Test-Path ./artifacts/macOS-piratewallet-v$version.dmg) -or
    ! (Test-Path ./artifacts/Windows-installer-piratewallet-v$version.msi) ) {
        Write-Host "[Error]"
        exit 1;
    }
Write-Host "[OK]"

Write-Host -NoNewline "Signing Binaries......."
bash src/scripts/signbinaries.sh --version $version
Write-Host "[OK]"
