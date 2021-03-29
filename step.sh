#!/bin/bash
set -ex

echo "Trigger Paths: $TRIGGER_PATHS"

if [ -z "$BITRISEIO_GIT_BRANCH_DEST" ]
then
    echo "No PR detected. Skipping selective builds."
    exit 0
fi

git fetch origin "$BITRISEIO_GIT_BRANCH_DEST" --depth 1

DIFF_FILES="$(git diff --name-only origin/${BITRISEIO_GIT_BRANCH_DEST})"

set +x
PATH_PATTERN=$(ruby -e 'puts ENV["TRIGGER_PATHS"].strip.split("\n").map { |e| e.gsub("/", "\\/") }.join("|") ')

echo "PATH_PATTERN: $PATH_PATTERN"
set -x

check_app_diff ()
{
    set +e
    echo $DIFF_FILES | grep -E $1
    exit_status=$?
    if [[ $exit_status = 1 ]]; then
      echo "No changes detected. Build marked as skippable."
      envman add --key BUILD_IS_SKIPPABLE --value "true"
    else
      echo "Changes detected. Build marked as not skippable."
      envman add --key BUILD_IS_SKIPPABLE --value "false"
    fi
    set -e
}

check_app_diff "$PATH_PATTERN"

exit 0
