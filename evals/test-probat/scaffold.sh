#!/usr/bin/env bash
# Copies this case's input files (fixtures/, dotfiles included) into the run's
# empty workspace. Runs only with `claude plugin eval --scaffold`; the CLI calls
# "bash <absolute path of this script>" with the workspace as the current
# directory, so the case directory is the directory of $0.
set -eu
case_dir=$(cd "$(dirname "$0")" && pwd)
cp -R "$case_dir/fixtures/." .
