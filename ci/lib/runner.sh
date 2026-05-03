#!/usr/bin/env bash
# Sourceable library — run one test mode inside a Docker container.

ALL_MODES=(baseline fork opt fork-opt fork-opt-cache)
DC_COVERAGE="-coverage,statement,branch,condition,subroutine"

# run_mode IMAGE MODE EXAMPLE_DIR OUTPUT_DIR REPO_ROOT [JOBS]
# Runs the given mode inside a Docker container and writes results to OUTPUT_DIR.
# Output files: exit-code.txt, time.txt, summary.txt, test-output.txt
run_mode() {
    local image="$1" mode="$2" example_dir="$3" output_dir="$4" repo_root="$5"
    local jobs="${6:-1}"

    mkdir -p "$output_dir"

    local dc_opt="-I/opt/optimizer/lib -MDevel::Cover=${DC_COVERAGE},+select,^lib,+ignore,^"
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
} > /opt/output/versions.txt 2>&1
cover -delete -silent 2>/dev/null || true

set +e
/usr/bin/time -f 'elapsed=%e user=%U sys=%S' -o /opt/output/time.txt \
    env PERL5OPT='${perl5opt}' ${runner_cmd} > /opt/output/test-output.txt 2>&1
echo \$? > /opt/output/exit-code.txt
set -e

cover -silent -coverage statement,branch,condition,subroutine 2>/dev/null \
    | grep -E '^(---|File |lib/|Total)' > /opt/output/summary.txt || true
"
}
