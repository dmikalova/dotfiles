# run commands on multiple piped lines
# ... | each command1 command2 "command3 has spaces"
each() {
    while read line; do
        for f in "$@"; do
            "$f" "$line"
        done
    done
}

# Determine size of a file or total size of a directory
fs() {
    if du -b /dev/null >/dev/null 2>&1; then
        local arg=-sbh
    else
        local arg=-sh
    fi
    # shellcheck disable=SC2199
    if [[ -n "$@" ]]; then
        du $arg -- "$@"
    else
        du $arg -- .[^.]* *
    fi
}

# colorize man pages
man() {
    env \
        LESS_TERMCAP_mb="$(printf '\e[1;31m')" \
        LESS_TERMCAP_md="$(printf '\e[1;31m')" \
        LESS_TERMCAP_me="$(printf '\e[0m')" \
        LESS_TERMCAP_se="$(printf '\e[0m')" \
        LESS_TERMCAP_so="$(printf '\e[1;44;33m')" \
        LESS_TERMCAP_ue="$(printf '\e[0m')" \
        LESS_TERMCAP_us="$(printf '\e[1;32m')" \
        man "$@"
}

# Create a new directory and enter it
mkd() {
    mkdir --parent --verbose "$@"
    cd "$@" || exit
}

# `open` with no arguments opens the current directory, otherwise opens the given
# location
open() {
    if [ $# -eq 0 ]; then
        xdg-open . >/dev/null 2>&1
    else
        xdg-open "$@" >/dev/null 2>&1
    fi
}
