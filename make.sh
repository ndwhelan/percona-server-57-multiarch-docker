#!/usr/bin/env bash
set -e -o pipefail

printf "Getting \`buildx\`\n"
if [ ! -d ".buildx" ]; then
  git clone https://github.com/docker/buildx.git .buildx
  cd .buildx
  make install
  cd ../
fi



printf "\u001b[36mBuilding the following image:\n\t" | tee >(sed -e $'s/\x1b\[[0-9;]*m//g' >> make.log)
printf "\u001b[35mghcr.io//ndwhelan/percona-server-57-multiarch-docker\n\n\u001b[0m" | tee >(sed -e $'s/\x1b\[[0-9;]*m//g' >> make.log)

docker buildx build --platform linux/amd64,linux/arm64 \
    --push \
    -t "ghcr.io/ndwhelan/percona-server-57-multiarch-docker" \
    .

printf "\u001b[36mDONE BUILDING:\n\t\u001b[35mghcr.io/ndwhelan/percona-server-57-multiarch-docker\n\n\u001b[0m" | tee >(sed -e $'s/\x1b\[[0-9;]*m//g' >> make.log)