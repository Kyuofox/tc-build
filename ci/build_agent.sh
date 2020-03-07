#!/usr/bin/env bash

set -eufo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y bison ca-certificates ccache clang cmake curl file flex gcc g++ git make ninja-build python3 texinfo zlib1g-dev libssl-dev libelf-dev patchelf

git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"

git clone --depth 1 "https://github.com/$GH_BUILD_REPO" build
cd build
./build-proton-tc.sh
./upload-build.sh
