#!/bin/sh
set -eu
if [ "${DEBUG:=}" = true ]; then set -x; fi

START="${PWD}"
CODE="$HOME/code/github.com"
cd "${CODE}"
DIRS=$(find cddc39 dmikalova e91e63 screeptorio -name ".git" -type d ! -path '*/.terragrunt-cache/*')

for DIR in ${DIRS}; do
    cd "${CODE}/${DIR}/../"
    pwd
    git add .

    STATUS=$(git status | grep "nothing to commit" | cat)
    if [ -n "${STATUS}" ]; then
        continue
    fi

    git commit --verbose
    git pull
    git push
done

cd "${START}"
