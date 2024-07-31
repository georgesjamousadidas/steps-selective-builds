#!/bin/bash
set -e

echo "Running Selective Builds On Path: ($TRIGGER_PATHS)"

if [ -z "$BITRISEIO_GIT_BRANCH_DEST" ]; then
    echo "No PR detected. Skipping selective builds."
    exit 0
fi

if [ -z "${TRIGGER_PATHS}" ]; then
  echo "TRIGGER_PATHS is empty or not set. Selective Builds requires a TRIGGER_PATHS env!"
  exit 1
fi

echo "Fetching origin branch to compare to: ($BITRISEIO_GIT_BRANCH_DEST)"
git fetch origin "$BITRISEIO_GIT_BRANCH_DEST" --depth 1

echo "Fetching diffs..."
DIFF_FILES="$(git diff --name-only origin/${BITRISEIO_GIT_BRANCH_DEST})"

echo "Creating a pattern for trigger paths..."
PATH_PATTERN=$(echo "$TRIGGER_PATHS" | awk '{gsub("/","\\/"); print}' | tr '\n' '|' | sed 's/^|\(.*\)|$/\1/')
echo "Will use pattern: ($PATH_PATTERN)"

check_app_diff ()
{
    set +e
    echo $DIFF_FILES | grep -E $1
    exit_status=$?
    if [[ $exit_status = 1 ]]; then
      echo "No changes detected. Build marked as skippable. So next build will be skipped."
      envman add --key BUILD_IS_SKIPPABLE --value "true"
    else
      echo "Changes detected. Build marked as not skippable. So next build will not be skipped."
      envman add --key BUILD_IS_SKIPPABLE --value "false"
    fi
    set -e
}

check_app_diff "$PATH_PATTERN"

echo "Diffs worked on:"
echo "-----"
echo "$DIFF_FILES"
echo "-----"

exit 0
