#!/usr/bin/env bash

set -u
set -o pipefail

rm -rf   .direnv/bin
mkdir -p .direnv/bin

export K0S_VERSION=$(yq '.package.create.set.k0s_version' zarf-config.yaml)
declare -a ARCH=("amd64" "arm64")

for arch in "${ARCH[@]}"; do
  echo "::debug::message='downloading k0s-$arch for $K0S_VERSION'"
  curl ${GITHUB_TOKEN:+" -u \":$GITHUB_TOKEN\""} -s -L -o .direnv/bin/k0s-$arch https://github.com/k0sproject/k0s/releases/download/$K0S_VERSION/k0s-$K0S_VERSION-$arch

  chmod +x .direnv/bin/k0s-$arch

  export sha=$(sha256sum .direnv/bin/k0s-$arch | awk '{ print $1 }')
  echo "::debug::sha='$sha'"

  export yq_sha=$(printf '.package.create.set.k0s_sha_%s = "%s"' "$arch" "$sha")
  echo "::debug::yq_sha='$yq_sha'"

  yq -i "$yq_sha" zarf-config.yaml
done

rm -rf   files
mkdir -p files

echo "::debug::pulling air-gap image list"
curl ${GITHUB_TOKEN:+" -u \":$GITHUB_TOKEN\""} -s -L -o files/airgap-images-list.txt https://github.com/k0sproject/k0s/releases/download/$K0S_VERSION/airgap-images-list.txt
