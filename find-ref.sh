#!/bin/bash -e
# Copyright 2021 Google Inc. Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

if [ -z "$PR_BRANCH" ]; then
  # Remove the "refs/heads/" prefix
  current_branch="${CURRENT_REF/refs\/heads\//}"
else
  current_branch="$PR_BRANCH"
fi

if [[ "$current_branch" == feature.* ]]; then
  default="$current_branch"
else
  default="$DEFAULT_REF"
fi

if [[ -z "$default" ]]; then
  skip="true"
else
  skip="false"
fi

# We don't have a PR_BRANCH so we are not in a pull request, so there's no
# linked PR to find.
if [ -z "$PR_BRANCH" ]; then
  if [[ -z "$default" ]]; then
    echo "Not a pull request, skipping checkout"
  else
    echo "Not a pull request, using default ref $default"
  fi

  echo "::set-output name=skip::$skip"
  echo "::set-output name=ref::$default"
  exit 0
fi

echo "::group::Pull request body"
echo "$PR_BODY"
echo "::endgroup::"

# Echoes the sass/sass Git ref that should be checked out for the current GitHub
# Actions run. If we're running specs for a pull request which refers to a
# sass/sass pull request, we'll run against the latter rather than sass/sass
# main.
echo "::group::Finding pull request reference"
for link in "$(echo "$PR_BODY" | grep -Eo "${REPO}(#|/pull/)[0-9]+")"; do
  if [[ "$link" = *#* ]]; then
    number="${link#*#}"
  else
    number="${link#*/pull/}"
  fi

  json="$(
    curl --fail --silent \
       --header "Authorization: token $TOKEN" \
       --header "Accept: application/vnd.github.v3+json" \
       "https://api.github.com/repos/$REPO/pulls/${number}"
  )"
  if [[ "$?" == 0 && "$(echo "$json" | jq .state -r)" == "open" ]]; then
    echo "Linked to pull request $number"
    echo "::set-output name=skip::false"
    echo "::set-output name=ref::refs/pull/$number/head"
    exit 0
  else
    echo "$link isn't a pull request."
  fi
done

if [[ -z "$default"  ]]; then
  echo "No linked pull request, skipping checkout"
else
  echo "No linked pull request, using default ref $default"
fi

echo "::set-output name=skip::$skip"
echo "::set-output name=ref::$default"
echo "::endgroup::"
