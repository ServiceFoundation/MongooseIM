#!/usr/bin/env bash
set -e

git_ref=$1
revision=$2
specfile_min_erl_vsn=$3

arch="x86_64"
package_name_arch="amd64"

cd ~/rpmbuild/BUILD/mongooseim

version=$(cat VERSION)
commit_sha=$(git rev-parse --short HEAD)

# Adjust package revision to requirements:
# https://twiki.cern.ch/twiki/bin/view/Main/RPMAndDebVersioning
if [ "$version" == "$git_ref" ] && [ "$(git describe --exact-match --tags HEAD)" == "$git_ref" ]; then
    :
elif [ "$(git rev-parse --abbrev-ref HEAD)" == "$git_ref" ]; then
    revision="${revision}.${git_ref}.${commit_sha}"
elif [ "${commit_sha:0:6}" == "${git_ref:0:6}" ]; then
    revision="${revision}.${commit_sha}"
else
    echo "Passed git reference: ${gitref} and check outed source code do not match." && exit 1
fi

rpmbuild -bb \
    --define "version ${version}" \
    --define "release ${revision}" \
    --define "architecture ${arch}" \
    --define "erlang_min_vsn ${specfile_min_erl_vsn}" \
    ~/rpmbuild/SPECS/mongooseim.spec

source /etc/os-release
os=$ID
os_version=$VERSION_ID
package_os_file_name=${os}~${os_version}

mv ~/rpmbuild/RPMS/${arch}/mongooseim-${version}-${revision}.${arch}.rpm \
    ~/mongooseim_${version}-${revision}~${package_os_file_name}_${package_name_arch}.rpm
