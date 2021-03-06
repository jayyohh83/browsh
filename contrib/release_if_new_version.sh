#!/bin/bash

set -e

PROJECT_ROOT=$(git rev-parse --show-toplevel)
manifest=$PROJECT_ROOT/webext/manifest.json
line=$(cat $manifest | grep '"version"')
manifest_version=$(echo $line | grep -o '".*"' | cut -d " " -f 2 | sed 's/"//g')

latest_tagged_version=$(git tag --sort=v:refname --list 'v*.*.*' | tail -n1 | sed -e "s/^v//")

echo "manifest.json version: $manifest_version"
echo "Latest tag: $latest_tagged_version"

if [[ "$manifest_version" == "$latest_tagged_version" ]]; then
  echo "Not running release as there's no new version."
  exit 0
fi

git tag v$manifest_version
git show v$manifest_version --quiet
git config --global user.email "builds@travis-ci.com"
git config --global user.name "Travis CI"
# `/dev/null` needed to prevent Github token appearing in logs
git push --tags --quiet https://$GITHUB_TOKEN@github.com/browsh-org/browsh > /dev/null 2>&1

git reset --hard v$manifest_version

cd $PROJECT_ROOT/webext
BROWSH_ENV=RELEASE npm run build

cd $PROJECT_ROOT/interfacer/src
curl -sL http://git.io/goreleaser | bash

cd $HOME
git clone https://github.com/browsh-org/www.brow.sh.git
cd www.brow.sh
echo "latest_version: $manifest_version" > _data/browsh.yml
git add _data/browsh.yml
git commit -m "(Travis CI) Updated Browsh version to $manifest_version"
# `/dev/null` needed to prevent Github token appearing in logs
git push --quiet https://$GITHUB_TOKEN@github.com/browsh-org/www.brow.sh > /dev/null 2>&1
