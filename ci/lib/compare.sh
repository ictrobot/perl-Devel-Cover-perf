#!/usr/bin/env bash
# Sourceable library — compare coverage output across runner modes.

# Summary output is compared to baseline for every mode. Detailed output is
# compared within the matching runner family because forkprove preload changes
# raw execution counts.

summary_reference() {
    local run_dir="$1"
    echo "$run_dir/baseline/summary.txt"
}

detail_reference_mode() {
    local mode="$1"
    case "$mode" in
        fork-*) echo "fork" ;;
        *)      echo "baseline" ;;
    esac
}

detail_reference() {
    local run_dir="$1" mode="$2"
    echo "$run_dir/$(detail_reference_mode "$mode")/detailed.txt"
}

# compare_mode_coverage RUN_DIR MODE
# Prints PASS or a FAIL(...) status. Does not inspect test exit codes.
compare_mode_coverage() {
    local run_dir="$1" mode="$2"
    local mode_dir="$run_dir/$mode"
    local baseline_summary
    baseline_summary=$(summary_reference "$run_dir")

    if [[ "$mode" == "baseline" ]]; then
        echo "PASS"
    elif [[ ! -f "$baseline_summary" ]]; then
        echo "FAIL(no baseline)"
    elif [[ ! -f "$mode_dir/summary.txt" ]]; then
        echo "FAIL(no summary)"
    elif ! diff -q "$baseline_summary" "$mode_dir/summary.txt" &>/dev/null; then
        echo "FAIL(summary)"
    elif [[ "$mode" == "fork" ]]; then
        echo "PASS"
    else
        local baseline_detailed
        baseline_detailed=$(detail_reference "$run_dir" "$mode")
        if [[ ! -f "$baseline_detailed" ]]; then
            echo "FAIL(no detail baseline)"
        elif [[ ! -f "$mode_dir/detailed.txt" ]]; then
            echo "FAIL(no detail)"
        elif ! diff -q "$baseline_detailed" "$mode_dir/detailed.txt" &>/dev/null; then
            echo "FAIL(detail)"
        else
            echo "PASS"
        fi
    fi
}

is_coverage_failure() {
    case "$1" in
        FAIL\(summary\)|FAIL\(detail\)|FAIL\(no\ baseline\)|\
        FAIL\(no\ summary\)|FAIL\(no\ detail\ baseline\)|FAIL\(no\ detail\))
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# compare_coverage RUN_DIR
# RUN_DIR contains per-mode subdirectories, each with summary.txt and detailed.txt.
# Returns 0 if all matching artifacts are equivalent, 1 otherwise.
# Writes comparison.diff and comparison.status to RUN_DIR.
compare_coverage() {
    local run_dir="$1"
    local failed=0
    local diff_output=""

    for mode_dir in "$run_dir"/*/; do
        local mode
        mode=$(basename "$mode_dir")

        local status
        status=$(compare_mode_coverage "$run_dir" "$mode")
        [[ "$status" == "PASS" ]] && continue

        failed=1
        diff_output+="--- $mode: $status ---\n"
        case "$status" in
            "FAIL(summary)")
                diff_output+="$(diff -u "$(summary_reference "$run_dir")" "$mode_dir/summary.txt" 2>&1 || true)\n\n"
                ;;
            "FAIL(detail)")
                diff_output+="$(diff -u "$(detail_reference "$run_dir" "$mode")" "$mode_dir/detailed.txt" 2>&1 || true)\n\n"
                ;;
        esac
    done

    if (( failed )); then
        echo -e "$diff_output" > "$run_dir/comparison.diff"
        echo "FAIL" > "$run_dir/comparison.status"
        return 1
    fi

    : > "$run_dir/comparison.diff"
    echo "PASS" > "$run_dir/comparison.status"
    return 0
}
