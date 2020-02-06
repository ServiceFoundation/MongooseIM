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
          --os <os>
	  --os_version <os_version>
	  --git_ref <git_ref>
	  --revision <revision>
	  --erlang_version <erlang_version>
	  --minimal_erlang_version <minimal_erlang_version>
	  --dockerfile_path <dockerfile_path>
	  --context_path <context_path>
	  --built_packages_directory <built_packages_directory>"
}

# Require valid number of parameters
if [ $len -ne 18 ]; then
    usage && exit 1
fi

for (( i = 0; i < $len - 1; i++ )); do
    arg=${args[i]}
    next_arg=${args[i+1]}
    case "$arg" in
        --os)
            is_flag_or_empty "$next_arg" && param_error "$arg" && exit 1
            os="$next_arg"
            ;;
        --os_version)
            is_flag_or_empty "$next_arg" && param_error "$arg" && exit 1
            os_version="${next_arg}"
            ;;
        --git_ref)
            is_flag_or_empty "$next_arg" && param_error "$arg" && exit 1
            git_ref="${next_arg}"
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

docker build -t mongooseim-${os}-${os_version}:${git_ref}-${revision} \
    --build-arg os=${os} \
    --build-arg os_version=${os_version} \
    --build-arg git_ref=${git_ref} \
    --build-arg revision=${revision} \
    --build-arg erlang_version=${erlang_version} \
    --build-arg min_erl_vsn=${minimal_erlang_version} \
    -f ${dockerfile_path} \
    $context_path

# Run ready docker image with tested mongooseim package and move it to
# built packages directory
docker run --rm -v "${built_packages_directory}:/built_packages" \
    "mongooseim-${os}-${os_version}:${git_ref}-${revision}"
    
