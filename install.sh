#!/bin/bash
set -e
# Needed because if it is set, cd may print the path it changed to.
unset CDPATH

root=$(pwd)

# Whether to run the command in a verbose mode
[[ "$*" =~ '-v' ]] && v="/dev/stdout" || v="/dev/null"

git clone https://github.com/levenup/tools.git >$v
git clone https://github.com/levenup/frontend.git >$v
git clone https://github.com/levenup/backend.git >$v

cd frontend/mobile

sh ../../tools/setup_environment.sh >$v