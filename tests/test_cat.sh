#!/bin/sh

set -u

BIN_DIR=${BIN_DIR:-./build/bin}
CAT="$BIN_DIR/cat"

pass=0
fail=0

TMPDIR=${TMPDIR:-/tmp}
TEST_DIR="$TMPDIR/coreutils-cat-test.$$"

cleanup() {
  rm -rf "$TEST_DIR"
}

trap cleanup 0
trap 'exit 1' 1 2 3 15

mkdir "$TEST_DIR"

echo "Hello World" >"$TEST_DIR/file1.txt"
printf "Line 2\nLine 3\n" >"$TEST_DIR/file2.txt"
touch "$TEST_DIR/file_empty.txt"

pass() {
  printf 'PASS: %s\n' "$1"
  pass=$((pass + 1))
}

fail() {
  printf 'FAIL: %s\n' "$1"
  fail=$((fail + 1))
}

check_cat() {
  name=$1
  shift

  >"$TEST_DIR/stdin.tmp"

  # Only consume stdin if it is NOT an interactive terminal (i.e. it's a pipe or Here-Doc)
  if [ ! -t 0 ]; then
    cat >"$TEST_DIR/stdin.tmp"
  fi

  # Run custom utility
  eval "$CAT" "$@" <"$TEST_DIR/stdin.tmp" >"$TEST_DIR/my.out" 2>"$TEST_DIR/my.err"
  exit_my=$?

  # Run system reference implementation
  eval "cat" "$@" <"$TEST_DIR/stdin.tmp" >"$TEST_DIR/sys.out" 2>"$TEST_DIR/sys.err"
  exit_sys=$?

  # Check exit code
  if [ "$exit_my" -ne "$exit_sys" ]; then
    fail "$name (exit code mismatch: expected $exit_sys, got $exit_my)"
    return 1
  fi

  # Check standard output bytes
  if ! cmp -s "$TEST_DIR/my.out" "$TEST_DIR/sys.out"; then
    fail "$name (stdout mismatch)"
    printf '  expected stdout bytes:\n'
    od -An -tx1 "$TEST_DIR/sys.out"
    printf '  actual stdout bytes:\n'
    od -An -tx1 "$TEST_DIR/my.out"
    return 1
  fi

  # Check if standard error presence matches
  if [ -s "$TEST_DIR/sys.err" ] && [ ! -s "$TEST_DIR/my.err" ]; then
    fail "$name (expected error on stderr, but got none)"
    return 1
  elif [ ! -s "$TEST_DIR/sys.err" ] && [ -s "$TEST_DIR/my.err" ]; then
    fail "$name (unexpected error on stderr: '$(cat "$TEST_DIR/my.err")')"
    return 1
  fi

  pass "$name"
}

#
# Basic file combinations
#

check_cat "single file" "$TEST_DIR/file1.txt"
check_cat "multiple files" "$TEST_DIR/file1.txt" "$TEST_DIR/file2.txt"
check_cat "empty file" "$TEST_DIR/file_empty.txt"
check_cat "empty and non-empty mix" "$TEST_DIR/file_empty.txt" "$TEST_DIR/file1.txt"

#
# POSIX Flags & Special Targets
#

check_cat "ignored -u flag" "-u" "$TEST_DIR/file1.txt"
check_cat "stdin shortcut using dash" "-" <<EOF
piped input lines
EOF

check_cat "mix of file and dash" "$TEST_DIR/file1.txt" "-" "$TEST_DIR/file2.txt" <<EOF
intermittent stdin text
EOF

#
# Error Boundaries
#

check_cat "non-existent file" "$TEST_DIR/non_existent_file.txt"
check_cat "valid file followed by non-existent file" "$TEST_DIR/file1.txt" "$TEST_DIR/non_existent_file.txt"

#
# Summary
#

printf '\n'
printf '%d passed, %d failed\n' "$pass" "$fail"

[ "$fail" -eq 0 ]
