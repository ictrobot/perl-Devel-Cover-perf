#!/usr/bin/env bash
# Sourceable library — compare coverage summaries across modes.

# compare_coverage RUN_DIR
# RUN_DIR contains per-mode subdirectories, each with summary.txt.
# Uses baseline/summary.txt as reference.
# Returns 0 if all match, 1 if any mismatch.
# Writes comparison.diff and comparison.status to RUN_DIR.
compare_coverage() {
    local run_dir="$1"
    local baseline="$run_dir/baseline/summary.txt"

    if [[ ! -f "$baseline" ]]; then
        echo "ERROR: baseline summary not found: $baseline" >&2
        echo "FAIL" > "$run_dir/comparison.status"
        return 1
    fi

    local failed=0
    local diff_output=""

    for mode_dir in "$run_dir"/*/; do
        local mode=$(basename "$mode_dir")
        [[ "$mode" == "baseline" ]] && continue

        local summary="$mode_dir/summary.txt"
        if [[ ! -f "$summary" ]]; then
            diff_output+="--- $mode: summary.txt missing ---\n"
            failed=1
            continue
        fi

        local d
        d=$(diff -u "$baseline" "$summary" 2>&1) || true
        if [[ -n "$d" ]]; then
            diff_output+="--- $mode vs baseline ---\n${d}\n\n"
            failed=1
        fi
    done

    if (( failed )); then
        echo -e "$diff_output" > "$run_dir/comparison.diff"
        echo "FAIL" > "$run_dir/comparison.status"
        return 1
    else
        : > "$run_dir/comparison.diff"
        echo "PASS" > "$run_dir/comparison.status"
        return 0
    fi
}
