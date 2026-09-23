#!/bin/sh
set -eu

NL="
"
OWNERS="cddc39 dmikalova e91e63 screeptorio"
ROOT_DIR="$HOME/code/github.com/"

REPOS=""
for OWNER in $OWNERS; do
    R=$(gh repo list "${OWNER}" --json nameWithOwner --template '{{range .}}{{printf "%s\n" .nameWithOwner}}{{end}}')
    REPOS="${REPOS}${R}${NL}"
done
echo "$REPOS"

for REPO in $REPOS; do
    OWNER="$(echo "${REPO}" | cut -d '/' -f 1)"
    REPO_NAME="$(echo "${REPO}" | cut -d '/' -f 2)"
    OWNER_DIR="${ROOT_DIR}/${OWNER}"

    mkdir -p "${OWNER_DIR}"
    cd "${OWNER_DIR}"
    if [ ! -d "${REPO_NAME}" ]; then
        gh repo clone "${REPO}"
    fi
done
