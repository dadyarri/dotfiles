#!/bin/bash

_ex_help () {
    echo "Little wrapper to extract archives correctly."
    echo
    echo "Supports .tar.bz2, .tar.gz, .bz2, .rar, .gz, .tar, .tbz2, .tbz2, .tgz, .zip, .Z, .7z, .xz."
    echo "Syntax: ex [options] archive"
    echo
    echo "Options:"
    echo "-h, --help Prints this help and exits."
    echo "Arguments:"
    echo "archive    Archive to extract."
}


function ex () {
  local param
    while [[ "$#" -gt 0 ]]; do
      param="$1"
        case "$param" in
          -h|--help)
            _ex_help
            shift
            ;;
          *)
            echo_red "Invalid parameter was provided: $param"
            return 1
        esac
    done
    if [ -f "$1" ] ; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1" ;;
            *.tar.gz)    tar xzf "$1" ;;
            *.bz2)       bunzip2 "$1" ;;
            *.rar)       rar x "$1" ;;
            *.gz)        gunzip "$1" ;;
            *.tar)       tar xvf "$1" ;;
            *.tbz2)      tar xjf "$1" ;;
            *.tgz)       tar xzf "$1" ;;
            *.zip)       unzip "$1" ;;
            *.Z)         uncompress "$1" ;;
            *.7z)        7za x "$1" ;;
            *.xz)        xz -d "$1" ;;
            *)           echo "'$1' cannot be extracted via $0"; exit 1 ;;
        esac
    else
        echo "'$1' is not a valid file"
        exit 1
    fi
}

