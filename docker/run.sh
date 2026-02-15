#!/bin/bash

VERSIONS=("24.04") # Default to testing only the latest LTS version
SKIP_BUILD=false
ALL=false

for arg in "$@"; do
    case "$arg" in
        all)
            # Run tests for the most important versions
            VERSIONS=("22.04" "24.04")
            ALL=true
            # Many packages etc are not working proparly on 25.10 yet
            # VERSIONS=("22.04" "24.04" "25.10")
            ;;
        skip_build)
            SKIP_BUILD=true
            ;;
        *)
            echo "Unknown argument: $arg"
            ;;
    esac
done


ROOT_DIR=$(pwd)

if [ "$SKIP_BUILD" = false ]; then
    for v in "${VERSIONS[@]}"; do
        ver_no=${v//./}
        tag="ubuntu${ver_no}-test"
        name="ubuntu${ver_no}"

        echo "Building ${tag} (FROM ubuntu:${v})..."
        docker rm -f "${name}" >/dev/null 2>&1 || true
        docker build --build-arg UBUNTU_VERSION=${v} -t "${tag}" . || { echo "Build failed for ${v}"; exit 1; }

        # Run on the same port as the version number (e.g., 2204 for 22.04, 2404 for 24.04)
        echo "Running ${name} on port ${ver_no}..."
        docker run -d --name "${name}" -p ${ver_no}:22 "${tag}"
        # docker run -d --privileged --cgroupns=host -v /sys/fs/cgroup:/sys/fs/cgroup:rw --name "${name}" -p ${ver_no}:22 "${tag}"
    done
else
    echo "Skipping Docker image build. Assuming containers are already running."
fi

# Return to project root and run ansible tests
cd "${ROOT_DIR}/.."
if [ "$ALL" = true ]; then
    echo "Running Ansible tests for all versions..."
    ansible-playbook test_run.yml
else
    echo "Running Ansible tests for Ubuntu 24.04..."
    ansible-playbook test_run.yml --limit "ubuntu2404"
fi
