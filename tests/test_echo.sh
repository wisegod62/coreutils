#!/bin/sh

set -u

BIN_DIR=${BIN_DIR:-./build/bin}
ECHO="$BIN_DIR/echo"

pass=0
fail=0

TMPDIR=${TMPDIR:-/tmp}
TEST_DIR="$TMPDIR/coreutils-echo-test.$$"

cleanup() {
  rm -rf "$TEST_DIR"
}

trap cleanup 0
trap 'exit 1' 1 2 3 15

mkdir "$TEST_DIR"

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
# Run echo and compare exact output.
#
# Usage:
#   check_output "test name" "expected" arguments...
#
check_output() {
  name=$1
  expected=$2
  shift 2

  "$ECHO" "$@" >"$TEST_DIR/output"

  if printf '%s\n' "$expected" | cmp -s - "$TEST_DIR/output"; then
    pass "$name"
  else
    fail "$name"
    printf '  expected:\n'
    printf '%s\n' "$expected" | od -An -tx1
    printf '  actual:\n'
    od -An -tx1 "$TEST_DIR/output"
  fi
}

#
# Run echo and compare its exact output bytes.
#
# Useful when testing newlines.
#

check_bytes() {
  name=$1
  expected=$2
  shift 2

  "$ECHO" "$@" >"$TEST_DIR/output"

  printf '%b' "$expected" >"$TEST_DIR/expected"

  if cmp -s "$TEST_DIR/expected" "$TEST_DIR/output"; then
    pass "$name"
  else
    fail "$name"
    printf '  expected bytes:\n'
    od -An -tx1 "$TEST_DIR/expected"
    printf '  actual bytes:\n'
    od -An -tx1 "$TEST_DIR/output"
  fi
}

#
# Basic output
#

check_bytes \
  "no arguments" \
  "\n"

check_bytes \
  "single argument" \
  "hello\n" \
  "hello"

check_bytes \
  "two arguments" \
  "hello world\n" \
  "hello" "world"

check_bytes \
  "three arguments" \
  "one two three\n" \
  "one" "two" "three"

#
# Empty arguments
#

check_bytes \
  "empty argument" \
  "\n" \
  ""

check_bytes \
  "two empty arguments" \
  " \n" \
  "" ""

check_bytes \
  "three empty arguments" \
  "  \n" \
  "" "" ""

#
# Whitespace
#

check_bytes \
  "argument containing spaces" \
  "hello world\n" \
  "hello world"

check_bytes \
  "leading spaces" \
  "  hello\n" \
  "  hello"

check_bytes \
  "trailing spaces" \
  "hello  \n" \
  "hello  "

check_bytes \
  "multiple internal spaces" \
  "hello   world\n" \
  "hello   world"

check_bytes \
  "tab in argument" \
  "hello	world\n" \
  "hello	world"

#
# Special characters
#

check_bytes \
  "punctuation" \
  '!@#$%^&*()_+-=[]{};:,.?\n' \
  '!@#$%^&*()_+-=[]{};:,.?'

check_bytes \
  "quotes" \
  "'single' \"double\"\n" \
  "'single' \"double\""

check_bytes \
  "backslash" \
  'hello\world\n' \
  'hello\world'

check_bytes \
  "dollar sign" \
  '$HOME\n' \
  '$HOME'

check_bytes \
  "asterisk" \
  '*.c\n' \
  '*.c'

#
# Multiple arguments with unusual content
#

check_bytes \
  "mixed arguments" \
  "hello world 123 !@#\n" \
  "hello" "world" "123" "!@#"

#
# Numeric arguments
#

check_bytes \
  "zero" \
  "0\n" \
  "0"

check_bytes \
  "positive integer" \
  "12345\n" \
  "12345"

check_bytes \
  "negative integer" \
  "-12345\n" \
  "-12345"

#
# Long argument
#

long_string='aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'

check_bytes \
  "long argument" \
  "$long_string\n" \
  "$long_string"

#
# Newline in an argument
#

check_bytes \
  "embedded newline" \
  "hello
world
" \
  "hello
world"

#
# Exit status
#

"$ECHO" "hello" >/dev/null

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
