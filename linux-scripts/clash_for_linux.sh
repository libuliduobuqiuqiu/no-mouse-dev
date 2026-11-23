#!/bin/sh
# Source this script to change proxy variables in the current shell.
# Linux / WSL: set CLASH_HOST and CLASH_PORT for your proxy endpoint.

if [ "$#" -ne 1 ]; then
    echo "usage: source clash_for_linux.sh <set|unset>" >&2
    return 1 2>/dev/null || exit 1
fi

case "$1" in
    set)
        export ALL_PROXY="http://${CLASH_HOST:-127.0.0.1}:${CLASH_PORT:-7890}"
        export https_proxy="$ALL_PROXY"
        export http_proxy="$ALL_PROXY"
        echo "Proxy enabled: $ALL_PROXY"
        ;;
    unset)
        unset ALL_PROXY http_proxy https_proxy
        echo "Proxy disabled"
        ;;
    *)
        echo "argument must be set or unset" >&2
        return 1 2>/dev/null || exit 1
        ;;
esac
