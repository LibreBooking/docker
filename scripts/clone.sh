#!/bin/sh
set -eu

GIT_TREE="$(basename "${APP_GH_REF}")"
git clone "${UPSTREAM_URL}" .
git checkout "${GIT_TREE}"
if [ "${APP_GH_ADD_SHA}" = "true" ]; then
  git describe --tags --long >config/custom-version.txt
fi
rm -rf .git
