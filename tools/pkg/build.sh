#!/bin/bash
set -euo pipefail

args=("$@")
len="${#args[@]}"

is_flag_or_empty() {
    [[ "$1" =~ ^-- ]] || [ -z "$1" ]
}

param_error() {
    echo "Flag '${1}' lacks parameter value."
}

flag_error() {
    echo "Flag '${1}' not supported."
}

usage() {
    echo "Usage: $0
	  --platform <platform>
	  --revision <revision>
	  --erlang_version <erlang_version>
	  --minimal_erlang_version <minimal_erlang_version>
	  --dockerfile_path <dockerfile_path>
	  --context_path <context_path>
	  --built_packages_directory <built_packages_directory>"
}

# Require valid number of parameters
if [ $len -ne 14 ]; then
    usage && exit 1
fi

for (( i = 0; i < $len - 1; i++ )); do
    arg=${args[i]}
    next_arg=${args[i+1]}
    case "$arg" in
        --platform)
            is_flag_or_empty "$next_arg" && param_error "$arg" && exit 1
            platform="$next_arg"
            ;;
        --revision)
            is_flag_or_empty "$next_arg" && param_error "$arg" && exit 1
            revision="${next_arg}"
            ;;
        --erlang_version)
            is_flag_or_empty "$next_arg" && param_error "$arg" && exit 1
            erlang_version="${next_arg}"
            ;;
        --minimal_erlang_version)
            is_flag_or_empty "$next_arg" && param_error "$arg" && exit 1
            minimal_erlang_version="${next_arg}"
            ;;
        --dockerfile_path)
            is_flag_or_empty "$next_arg" && param_error "$arg" && exit 1
            dockerfile_path="${next_arg}"
            ;;
        --context_path)
            is_flag_or_empty "$next_arg" && param_error "$arg" && exit 1
            context_path="${next_arg}"
            ;;
        --built_packages_directory)
            is_flag_or_empty "$next_arg" && param_error "$arg" && exit 1
            built_packages_directory="${next_arg}"
            ;;
        *)
            flag_error $arg
            exit 1
            ;;
    esac
    i=$((i+1))
done

version=$(cat "$(git rev-parse --show-toplevel)/VERSION")
revision="${revision}.$(git rev-parse --short HEAD)"

dockerfile_platform=${platform/_/:}
docker build -t mongooseim-${platform}:${version}-${revision} \
    --build-arg version=${version} \
    --build-arg dockerfile_platform=${dockerfile_platform} \
    --build-arg revision=${revision} \
    --build-arg erlang_version=${erlang_version} \
    --build-arg min_erl_vsn=${minimal_erlang_version} \
    -f ${dockerfile_path} \
    $context_path

# Run ready docker image with tested mongooseim package and move it to
# built packages directory
docker run --rm -v "${built_packages_directory}:/built_packages" \
    "mongooseim-${platform}:${version}-${revision}"
    
