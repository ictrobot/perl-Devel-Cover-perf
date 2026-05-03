#!/usr/bin/env bash
# Sourceable library — run one test mode inside a Docker container.

ALL_MODES=(baseline fork opt fork-opt fork-opt-cache)
DC_REPORT_COVERAGE="statement,branch,condition,subroutine"
DC_SUMMARY_COVERAGE="${DC_REPORT_COVERAGE},pod"

summary_coverage_for() {
    local coverage="$1"
    local want_statement=0 want_branch=0 want_condition=0 want_subroutine=0 want_pod=0
    local item criterion
    local -a items
    local IFS=,

    read -ra items <<< "$coverage"
    for item in "${items[@]}"; do
        criterion="${item%%-*}"
        case "$criterion" in
            all)
                echo "$DC_SUMMARY_COVERAGE"
                return 0
                ;;
            statement)  want_statement=1 ;;
            branch)     want_branch=1 ;;
            condition)  want_condition=1 ;;
            subroutine) want_subroutine=1 ;;
            pod)        want_pod=1 ;;
        esac
    done

    local summary=""
    (( want_statement  )) && summary="${summary:+$summary,}statement"
    (( want_branch     )) && summary="${summary:+$summary,}branch"
    (( want_condition  )) && summary="${summary:+$summary,}condition"
    (( want_subroutine )) && summary="${summary:+$summary,}subroutine"
    (( want_pod        )) && summary="${summary:+$summary,}pod"
    echo "$summary"
}

# run_mode IMAGE MODE EXAMPLE_DIR OUTPUT_DIR REPO_ROOT [JOBS] [COVERAGE]
# Runs the given mode inside a Docker container and writes results to OUTPUT_DIR.
# Output files: exit-code.txt, time.txt, summary.txt, detailed.txt, test-output.txt
run_mode() {
    local image="$1" mode="$2" example_dir="$3" output_dir="$4" repo_root="$5"
    local jobs="${6:-1}"
    local coverage="${7:-$DC_REPORT_COVERAGE}"
    local summary_coverage
    summary_coverage=$(summary_coverage_for "$coverage")
    if [[ -z "$summary_coverage" ]]; then
        echo "ERROR: coverage list must include at least one summary criterion: $DC_SUMMARY_COVERAGE" >&2
        return 2
    fi

    mkdir -p "$output_dir"

    local dc_opt="-I/opt/optimizer/lib -Ilib -I. -MDevel::Cover=-coverage,${coverage},+select,^lib,+ignore,^"
    local jobs_flag=""
    (( jobs > 1 )) && jobs_flag="-j${jobs}"
    local perl5opt runner_cmd

    case "$mode" in
        baseline)
            perl5opt="$dc_opt"
            runner_cmd="prove -lr $jobs_flag t/"
            ;;
        fork)
            perl5opt="$dc_opt"
            runner_cmd="forkprove -lr $jobs_flag -I. -MMyApp::Web t/"
            ;;
        opt)
            perl5opt="$dc_opt -MDevel::Cover::Optimizer"
            runner_cmd="prove -lr $jobs_flag t/"
            ;;
        opt-no-walksymtable)
            perl5opt="$dc_opt -MDevel::Cover::Optimizer=no_walksymtable"
            runner_cmd="prove -lr $jobs_flag t/"
            ;;
        fork-opt)
            perl5opt="$dc_opt"
            runner_cmd="forkprove -lr $jobs_flag -I. -MMyApp::Web -MDevel::Cover::Optimizer t/"
            ;;
        fork-opt-no-walksymtable)
            perl5opt="$dc_opt"
            runner_cmd="forkprove -lr $jobs_flag -I. -MMyApp::Web -MDevel::Cover::Optimizer=no_walksymtable t/"
            ;;
        fork-opt-cache)
            perl5opt="$dc_opt"
            runner_cmd="forkprove -lr $jobs_flag -I. -MMyApp::Web -MDevel::Cover::Optimizer=cache t/"
            ;;
        *)
            echo "ERROR: unknown mode: $mode" >&2
            return 2
            ;;
    esac

    docker run --rm \
        -v "${repo_root}/lib:/opt/optimizer/lib:ro" \
        -v "${repo_root}/${example_dir}:/opt/example-src:ro" \
        -v "${output_dir}:/opt/output" \
        -w /opt/work \
        "$image" bash -c "
set -euo pipefail
cp -a /opt/example-src/* /opt/work/
{
    perl -V:version
    perl -e 'require Devel::Cover; print qq{Devel::Cover \$Devel::Cover::VERSION\n}'
    perl -e 'require App::ForkProve; print qq{App::ForkProve \$App::ForkProve::VERSION\n}'
    perl -e 'require PadWalker; print qq{PadWalker \$PadWalker::VERSION\n}'
    perl -e 'eval { require Pod::Coverage; print qq{Pod::Coverage \$Pod::Coverage::VERSION\n} }; exit 0'
    perl -e 'eval { require Pod::Coverage::CountParents; print qq{Pod::Coverage::CountParents \$Pod::Coverage::CountParents::VERSION\n} }; exit 0'
} > /opt/output/versions.txt 2>&1
cover -delete -silent 2>/dev/null || true

set +e
/usr/bin/time -f 'elapsed=%e user=%U sys=%S' -o /opt/output/time.txt \
    env PERL5OPT='${perl5opt}' ${runner_cmd} > /opt/output/test-output.txt 2>&1
echo \$? > /opt/output/exit-code.txt
set -e

cover -silent -coverage ${summary_coverage} 2>/dev/null \
    | grep -E '^(---|File |lib/|Total)' > /opt/output/summary.txt || true
cover -silent -nosummary -report text -coverage ${coverage} \
        2>/opt/output/detailed-stderr.txt \
    | sed '/^Run:          /,/^$/d' > /opt/output/detailed.txt || true
"
}
