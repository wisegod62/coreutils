#!/bin/sh

# Default to ./build if BIN_DIR isn't explicitly provided
export BIN_DIR="${BIN_DIR:-$(pwd)/build}"

# Ensure the binary directory actually exists
if [ ! -d "$BIN_DIR" ]; then
    echo "Error: Binary directory '$BIN_DIR' does not exist." >&2
    exit 1
fi

echo "========================================="
echo " Running Coreutils Test Suite"
echo " Testing binaries in: $BIN_DIR"
echo "========================================="

FAILED_SUITES=0
TOTAL_SUITES=0

# Loop through all individual test scripts in the tests directory
for test_script in tests/test_*.sh; do
    # Skip if no files match the pattern
    [ -e "$test_script" ] || continue
    
    TOTAL_SUITES=$((TOTAL_SUITES + 1))
    echo "\n--> Running: $(basename "$test_script")"
    
    # Execute the individual utility test script
    sh "$test_script"
    
    if [ $? -ne 0 ]; then
        FAILED_SUITES=$((FAILED_SUITES + 1))
    fi
done

echo "\n========================================="
echo "Test Summary: $FAILED_SUITES / $TOTAL_SUITES suites failed."
echo "========================================="

if [ "$FAILED_SUITES" -gt 0 ]; then
    exit 1
fi
exit 0

