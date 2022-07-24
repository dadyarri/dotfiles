#!/bin/bash

_upd() {
  echo_blue "Updating system started...\n"
  if [[ (-n ${sysupd-}) || (-n ${autoremove-}) ]]; then
    echo_red "Password required\n"
    echo
    echo_red "Enter sudo password: "
    read -r -s password
    echo
  fi

  if [[ -n ${sysupd-} ]]; then
    echo_blue "Updating packages...\n"
    echo "$password" | sudo -S dnf update -y
    echo_green "Packages updated."
    echo
  fi

  if [[ -n ${autoremove-} ]]; then
    echo_blue "Removing orphans...\n"
    echo "$password" | sudo -S dnf autoremove -y
    echo_green "Orphans removed."
    echo
  fi

  if [[ -n ${flatpak-} ]]; then
    echo_blue "Updating flatpak apps...\n"
    flatpak update -y
    echo_green "Flatpak apps updated."
    echo
  fi
  echo_green "System updated."
}


_upd_help() {
    echo "Little wrapper to update entire system."
    echo
    echo "Syntax: upd [-h | --help | -s | -ar | -f | --all | -v]"
    echo
    echo "Options:"
    echo "-h | --help: Prints this help and exits."
    echo "-s:          Updates system. Requires sudo password."
    echo "-ar:         Removes orphans. Requires sudo password."
    echo "-f:          Updates flatpak applications."
    echo "--all:       Executes -s -ar -f altogether."
    echo "-v:          Adds verbose output."
    echo
}

verbose_print() {
  if [[ -n ${verbose-} ]]; then
    echo "$@"
  fi
}

function upd() {
  local param
  while [[ $# -gt 0 ]]; do
    param="$1"
    shift
    case "$param" in
      -h|--help)
        _upd_help
        return 0
        ;;
      -s)
        sysupd=true
        ;;
      -ar)
        autoremove=true
        ;;
      -f)
        flatpak=true
        ;;
      --all)
        echo all
        sysupd=true
        autoremove=true
        flatpak=true
        ;;
      -v)
        verbose=true
        ;;
      *)
        echo_red "Invalid parameter was provided: $param"
        return 1
        ;;
    esac
  done

  verbose_print "System update: ${sysupd:-false}"
  verbose_print "Remove orphans: ${autoremove:-false}"
  verbose_print "Update flatpak apps: ${flatpak:-false}"


  _upd
}

