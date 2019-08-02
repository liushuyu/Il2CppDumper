#!/bin/bash -e
# $1 agent os
# $2 configuration (release/debug)
case $1 in
Linux)
    DOTNET_OS='linux';;
Windows_NT)
    DOTNET_OS='win';;
Darwin)
    DOTNET_OS='osx';;
*)
    echo '##vso[task.logissue type=error]Unsupported agent OS!'
    exit 1;;
esac
if [[ "x$DOTNET_OS" != 'xwin' ]]; then
    echo '##vso[task.logissue type=warning]Workaround for ILC applied.'
    CC_PATH="$(command -v clang)" || exit 1
    ln -sv "${CC_PATH}" 'clang-3.9'
    export PATH="$PATH":"$(pwd)"
fi
# assuming x64 here, as other architectures are not considered atm
mkdir dist
dotnet publish -r "${DOTNET_OS}-x64" -f 'netcoreapp3.1' --configuration "$2" -o "$(pwd)/dist/"

echo '##vso[task.setprogress]Packing artifacts'
rm -fv "$(pwd)/dist/"*.{pdb,json}
cp -v Il2CppDumper/config.json dist/
cd dist || exit 1
if [[ "x$DOTNET_OS" != 'xwin' ]]; then
    strip Il2CppDumper
    tar czf "${BUILD_ARTIFACTSTAGINGDIRECTORY}/Il2CppDumper-${DOTNET_OS}-x64.tar.gz" *
else
    7z a "${BUILD_ARTIFACTSTAGINGDIRECTORY}/Il2CppDumper-${DOTNET_OS}-x64.7z"
fi
cd .. || exit 1
