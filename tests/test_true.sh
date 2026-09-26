#!/bin/sh

# Why in the world did I do this
# there's literally nothing that can go wrong

set -u

BIN_DIR=${BIN_DIR:-./build/bin}
TRUE="$BIN_DIR/true"

pass=0
fail=0

trap 'exit 1' 1 2 3 15

#
# Helpers
#

pass() {
  printf 'PASS: %s\n' "$1"
  pass=$((pass + 1))
}

fail() {
  printf 'FAIL: %s\n' "$1"
  fail=$((fail + 1))
}

#
# Exit status
#

"$TRUE" "hello" >/dev/null

if [ "$?" -eq 0 ]; then
  pass "successful exit status"
else
  fail "successful exit status"
fi

#
# Summary
#

printf '\n'
printf '%d passed, %d failed\n' "$pass" "$fail"

[ "$fail" -eq 0 ]
