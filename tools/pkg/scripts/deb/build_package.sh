#!/usr/bin/env bash
set -e

git_ref=$1
revision=$2
min_erl_vsn=$3

arch="amd64"

cd ~/mongooseim

version=$(cat VERSION)
commit_sha=$(git rev-parse --short HEAD)

# Adjust package revision to requirements:
# https://twiki.cern.ch/twiki/bin/view/Main/RPMAndDebVersioning
if [ "$version" == "$git_ref" ] && [ "$(git describe --exact-match --tags HEAD)" == "$git_ref" ]; then
    :
elif [ "$(git rev-parse --abbrev-ref HEAD)" == "$git_ref" ]; then
    revision="${revision}+${git_ref}+${commit_sha}"
elif [ "${commit_sha:0:6}" == "${git_ref:0:6}" ]; then
    revision="${revision}+${commit_sha}"
else
    echo "Passed git reference: ${gitref} and check outed source code do not match." && exit 1
fi

deluser --remove-home mongooseim --quiet || true
adduser --quiet --system --shell /bin/sh --group mongooseim

apt-get update

apt-get install libexpat1-dev libz-dev -y
rm -rf /usr/lib/erlang/man/man3/cerff.3.gz /usr/lib/erlang/man/man3/cerfl.3.gz /usr/lib/erlang/man/man3/cerfcl.3.gz /usr/lib/erlang/man/man3/cerfcf.3.gz /usr/lib/erlang/man/man3/cerfcf.3.gz /usr/lib/erlang/man/man1/x86_64-linux-gnu-gcov-tool.1.gz  /usr/lib/erlang/man/man1/ocamlbuild.native.1.gz  /usr/lib/erlang/man/man1/gcov-tool.1.gz /usr/lib/erlang/man/man1/ocamlbuild.byte.1.gz

sed -i '1 s/^.*$/\#\!\/bin\/bash/' tools/install
./tools/configure with-all user=mongooseim prefix="" system=yes
sed -i 's#PREFIX=""#PREFIX="mongooseim"#' configure.out
source configure.out
export GIT_SSL_NO_VERIFY=1
make install
cp -r ../deb/debian mongooseim/DEBIAN
mkdir -p mongooseim/etc/systemd/system/
cp -r ../deb/mongooseim.service mongooseim/etc/systemd/system/


sed -i "s#@ARCH@#${arch}#" mongooseim/DEBIAN/control
sed -i "s#@MIN_ERL_VSN@#${min_erl_vsn}#" mongooseim/DEBIAN/control
sed -i "s#@VER@#${version}#" mongooseim/DEBIAN/control
sed -i "s#@VER@#${version}#" mongooseim/DEBIAN/changelog

# set date in the dummy changelog
date=$(date -R)
sed -i "s#@DATE@#${date}#g" mongooseim/DEBIAN/changelog

chown $USER:$USER -R mongooseim
dpkg --build mongooseim ./

source /etc/os-release
os=$ID
os_version=$VERSION_ID
package_os_file_name=${os}~${os_version}
mv mongooseim_*.deb ~/mongooseim_${version}-${revision}~${package_os_file_name}_${arch}.deb

