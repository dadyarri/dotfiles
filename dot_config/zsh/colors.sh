#!/bin/bash

function echo_red() {
  echo -en "\033[0;31m$1\033[0m"
}

function echo_green() {
  echo -en "\033[0;32m$1\033[0m"
}

function echo_yellow() {
  echo -en "\033[0;33m$1\033[0m"
}

function echo_blue() {
  echo -en "\033[0;34m$1\033[0m"
}

function echo_purple() {
  echo -en "\033[0;35m$1\033[0m"
}
function echo_cyan() {
  echo -en "\033[0;36m$1\033[0m"
}
function echo_white() {
  echo -en "\033[0;37m$1\033[0m"
}
