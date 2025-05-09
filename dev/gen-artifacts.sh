#!/bin/bash
set -euo pipefail

#
# Available environment variables
#
# BUILD_TAG: The tag of the build. If not provided, 
# the tag will be the git tag of the current commit.
#

script_dir=$(dirname "$(realpath "$0")")
repo_root=$(realpath "${script_dir}/../")
cd "${repo_root}"

source "${script_dir}/lib/common"

mkdir -p "${build_dir}" "${artifacts_dir}" "${bytecode_dir}" "${abi_dir}"

export forge_version=$(forge --version | grep "Version" | awk '{print $3}')

function generate_artifacts() {
    local filename="$1"
    local package="$(echo "${filename}" | tr '[:upper:]' '[:lower:]')"
    local source_artifact="${source_dir}/${filename}.sol"
    local bytecode_artifact="${bytecode_dir}/${filename}.bin.json"
    local abi_artifact="${abi_dir}/${filename}.abi.json"

    rm -f "${bytecode_artifact}" "${abi_artifact}"

    # Generate ABI and bytecode
    if ! forge inspect "${source_artifact}:${filename}" abi --json > "${abi_artifact}"; then
        echo "ERROR: Failed to generate ABI for ${filename}" >&2
        exit 1
    fi

    if ! forge inspect "${source_artifact}:${filename}" bytecode > "${bytecode_artifact}"; then
        echo "ERROR: Failed to generate bytecode for ${filename}" >&2
        exit 1
    fi
}

function build_info() {
    echo "⧖ Dumping build info to ${build_info_file}"
    local build_date=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local build_tag=$(git describe HEAD --tags --long)

    jq -n \
      --arg forge_version "$forge_version" \
      --arg build_date "$build_date" \
      --arg build_tag "${BUILD_TAG:-${build_tag}}" \
      '{
        forge_version: $forge_version,
        build_date: $build_date,
        build_tag: $build_tag
      }' > "${build_info_file}"
}

function main() {
    echo "Generating artifacts with forge version ${forge_version}"

    # Define contracts (pass as arguments or use a default list)
    local contracts=("$@")
    if [ "${#contracts[@]}" -eq 0 ]; then
        contracts=("GroupMessageBroadcaster" "IdentityUpdateBroadcaster" "NodeRegistry" "RateRegistry")
    fi

    for contract in "${contracts[@]}"; do
        echo "⧖ Generating artifacts for contract: ${contract}"
        generate_artifacts "${contract}"
    done

    build_info

    echo -e "\033[32m✔\033[0m Artifacts generated successfully!\n"
}

if [ "${forge_version}" != "1.0.0-v1.0.0" ]; then
    echo "ERROR: Forge version must be v1.0.0" >&2
    exit 1
fi

main "$@"
