#!/usr/bin/env bash
# Lacking proper Makefile skills

set -e

TERMINAL="${TERMINAL:-st}"

here="$(
    cd $(dirname "$0")
    pwd
)"

cd "$here"

set -a
source ./makevars
set +a

funcs() {
    local a="func"
    grep "${a}tion" ./make | grep " {" | sed -e "s/${a}tion/- /g" | sed -e 's/{//g' | sort
}
aliases() {
    set -x
    local a="## Function"
    set +x
    grep -A 30 "$a Aliases:" ./make | grep -B 30 'main()' | grep -v main
}

doc="
# Repo Maintenance Functions

## Usage: ./make <function> [args]

## Functions:
$(funcs)

$(aliases)
"

sh() {
    echo -e "\x1b[48;5;255;38;5;0m Running: \x1b[48;5;124;38;5;255m $* \x1b[0m"
    "$@"
}

exit_help() {
    echo -e "$doc"
    exit 1
}

set_version() {
    if [ "${versioning:-}" == "calver" ]; then
        local M="$(date "+%m" | sed -e 's/0//g')"
        test -z "${1:-}" && {
            version="$(date "+%Y.$M.%d")"
            return 0
        }
    fi
    echo "Say ./make release <version>"
    exit 1
}

function tests {
    test -z "$1" && pytest -xs tests
    test -n "$1" && pytest "$@"
}

function docs_regen {
    sh doc pre_process \
        --fail_on_blacklisted_words \
        --patch_mkdocs_filewatch_ign_lp \
        --gen_theme_link \
        --gen_last_modify_date \
        --gen_change_log \
        --gen_change_log_versioning_stanza="${versioning:-calver}" \
        --gen_change_log \
        --gen_credits_page \
        --gen_auto_docs \
        --lit_prog_evaluation="${lit_prog_eval_match:-md}" \
        --lit_prog_evaluation_timeout=5 \
        --lit_prog_on_err_keep_running=false || exit 1 # fail build on error

}

function docs {
    sh docs_regen
    sh mkdocs build
}

function docs_serve {
    sh docs_regen
    sh mkdocs serve
    # `doc pp -h` reg. what this does (lp eval on file change):
}

function release {
    version="${1:-}"
    test -z "$version" && set_version
    echo "New Version = $version"
    sh poetry version "$version"
    sh docs
    sh git add pyproject.toml -f CHANGELOG.md
    sh git commit -am "chore: Prepare release $version"
    sh git tag "$version"
    sh git push
    sh git push --tags
    sh mkdocs gh-deploy
}

## Function Aliases:
ds() { docs_serve "$@"; }
t() { tests "$@"; }
rel() { release "$@"; }

main() {
    test -z "$POETRY_ACTIVE" && {
        poetry shell
        $0 "$@"
        exit $?
    }
    if [[ -z "$1" || "${1:-}" == "-h" ]]; then exit_help; fi
    func="$1"
    shift
    $func "$@"
}

main "$@"
