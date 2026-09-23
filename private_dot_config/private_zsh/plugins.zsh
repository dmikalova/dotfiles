#!/bin/zsh

for PLUGIN in ${DIR}/plugins/*; do
    source "${PLUGIN}"
done
