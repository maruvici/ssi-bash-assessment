#! /usr/bin/env bats
# Assumes all dependencies alredy installed
chmod +x ./src/memory_check.sh

setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'

    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd)"
    PATH="$DIR/../src: $PATH"
}

# INPUT VALIDATION TESTS
@test "Params Are Position-agnostic" {
    run memory_check.sh -e mvtevangelista0820@gmail.com -c 100 -w 90
    assert_equal "$status" 0
}

@test "Handles Missing Flags" {
    # Missing all flags
    run memory_check.sh
    assert_output --partial "Usage:"
    assert_equal "$status" 4

    # Missing -c
    run memory_check.sh -w 90 -e mvtevangelista0820@gmail.com
    assert_output --partial "Usage:"
    assert_equal "$status" 4

    # Missing -w
    run memory_check.sh -c 100 -e mvtevangelista0820@gmail.com
    assert_output --partial "Usage:"
    assert_equal "$status" 4

    # Mssing -e
    run memory_check.sh -c 100 -w 90
    assert_output --partial "Usage:"
    assert_equal "$status" 4
}

@test "Handles Missing Flag Arguments" {
    # Missing -c arg
    run memory_check.sh -c -w 90 -e mvtevangelista0820@gmail.com
    assert_output --partial "Error: -c"
    assert_equal "$status" 4

    # Missing -w arg
    run memory_check.sh -c 100 -w -e mvtevangelista0820@gmail.com
    assert_output --partial "Error: -w"
    assert_equal "$status" 4

    # Missing -e arg
    run memory_check.sh -c 100 -w 90 -e
    assert_output --partial "Error: -e"
    assert_equal "$status" 4
}

@test "Handles Invalid Flag Arguments" {
    # Invalid -c args
    run memory_check.sh -c 0 -w 90 -e mvtevangelista0820@gmail.com
    assert_output --partial "Enter valid critical"
    assert_equal "$status" 4

    run memory_check.sh -c 101 -w 90 -e mvtevangelista0820@gmail.com
    assert_output --partial "Enter valid critical"
    assert_equal "$status" 4

    run memory_check.sh -c onehundred -w 90 -e mvtevangelista0820@gmail.com
    assert_output --partial "Enter valid critical"
    assert_equal "$status" 4

    # Invalid -w args
    run memory_check.sh -c 100 -w 100 -e mvtevangelista0820@gmail.com
    assert_output --partial "Enter valid warning"
    assert_equal "$status" 4

    run memory_check.sh -c 100 -w negativeone -e mvtevangelista0820@gmail.com
    assert_output --partial "Enter valid warning"
    assert_equal "$status" 4

    # Invalid -e args
    run memory_check.sh -c 100 -w 90 -e mvtevangelista0820
    assert_output --partial "Enter a valid email"
    assert_equal "$status" 4

    run memory_check.sh -c 100 -w 90 -e @gmail.com
    assert_output --partial "Enter a valid email"
    assert_equal "$status" 4

    run memory_check.sh -c 100 -w 90 -e @gmail
    assert_output --partial "Enter a valid email"
    assert_equal "$status" 4
}

@test "Handles Warning >= Critical Threshold Case" {
    # Critical = Warning
    run memory_check.sh -c 50 -w 50 -e mvtevangelista0820@gmail.com
    assert_output --partial "Requirement:"
    assert_equal "$status" 4

    # Critical < Warning
    run memory_check.sh -c 98 -w 99 -e mvtevangelista0820@gmail.com
    assert_output --partial "Requirement:"
    assert_equal "$status" 4
}


