#!/usr/bin/env bats

# Bats is a testing framework for Bash
# Documentation https://bats-core.readthedocs.io/en/stable/
# Bats libraries documentation https://github.com/ztombol/bats-docs

# For local tests, install bats-core, bats-assert, bats-file, bats-support
# And run this in the add-on root directory:
#   bats ./tests/test.bats
# To exclude release tests:
#   bats ./tests/test.bats --filter-tags '!release'
# For debugging:
#   bats ./tests/test.bats --show-output-of-passing-tests --verbose-run --print-output-on-failure

setup() {
  set -eu -o pipefail

  # Override this variable for your add-on:
  export GITHUB_REPO=e0ipso/ddev-drupalorg-cli

  TEST_BREW_PREFIX="$(brew --prefix 2>/dev/null || true)"
  export BATS_LIB_PATH="${BATS_LIB_PATH}:${TEST_BREW_PREFIX}/lib:/usr/lib/bats"
  bats_load_library bats-assert
  bats_load_library bats-file
  bats_load_library bats-support

  export DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
  export PROJNAME="test-$(basename "${GITHUB_REPO}")"
  mkdir -p "${HOME}/tmp"
  export TESTDIR="$(mktemp -d "${HOME}/tmp/${PROJNAME}.XXXXXX")"
  export DDEV_NONINTERACTIVE=true
  export DDEV_NO_INSTRUMENTATION=true
  ddev delete -Oy "${PROJNAME}" >/dev/null 2>&1 || true
  cd "${TESTDIR}"
  run ddev config --project-name="${PROJNAME}" --project-tld=ddev.site
  assert_success
  run ddev start -y
  assert_success
}

health_checks() {
  # The drupalorg binary must be on PATH in the web container.
  run ddev exec which drupalorg
  assert_success
  assert_output --partial "/usr/local/bin/drupalorg"

  # It must be executable and respond to `list` (Symfony Console default),
  # and the output must include a known command to prove the PHAR really ran.
  run ddev exec drupalorg list
  assert_success
  assert_output --partial "project:issues"

  # The bash completion file must be installed system-wide.
  run ddev exec test -f /etc/bash_completion.d/drupalorg
  assert_success

  # The completion script must register the drupalorg command when sourced.
  run ddev exec bash -c 'source /etc/bash_completion.d/drupalorg && complete -p drupalorg'
  assert_success
  assert_output --partial "drupalorg"
}

teardown() {
  set -eu -o pipefail
  ddev delete -Oy "${PROJNAME}" >/dev/null 2>&1
  # Persist TESTDIR if running inside GitHub Actions. Useful for uploading test result artifacts
  # See example at https://github.com/ddev/github-action-add-on-test#preserving-artifacts
  if [ -n "${GITHUB_ENV:-}" ]; then
    [ -e "${GITHUB_ENV:-}" ] && echo "TESTDIR=${HOME}/tmp/${PROJNAME}" >> "${GITHUB_ENV}"
  else
    [ "${TESTDIR}" != "" ] && rm -rf "${TESTDIR}"
  fi
}

@test "install from directory" {
  set -eu -o pipefail
  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${DIR}"
  assert_success
  run ddev restart -y
  assert_success
  health_checks
}

@test "install with zsh ssh-shell installs zsh completion" {
  set -eu -o pipefail
  echo "# zsh ssh-shell test for ${PROJNAME} in $(pwd)" >&3

  cat > .ddev/config.zsh.yaml <<'EOF'
webimage_extra_packages:
  - zsh
EOF
  cat > .ddev/docker-compose.ssh-shell.yaml <<'EOF'
services:
  web:
    x-ddev:
      ssh-shell: zsh
EOF

  run ddev add-on get "${DIR}"
  assert_success
  run ddev restart -y
  assert_success

  run ddev exec which drupalorg
  assert_success
  assert_output --partial "/usr/local/bin/drupalorg"

  run ddev exec drupalorg list
  assert_success
  assert_output --partial "project:issues"

  run ddev exec test -f /usr/local/share/zsh/site-functions/_drupalorg
  assert_success

  run ddev exec test ! -f /etc/bash_completion.d/drupalorg
  assert_success

  run ddev exec head -n 1 /usr/local/share/zsh/site-functions/_drupalorg
  assert_success
  assert_output --partial "#compdef drupalorg"
}

# bats test_tags=release
@test "install from release" {
  set -eu -o pipefail
  echo "# ddev add-on get ${GITHUB_REPO} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${GITHUB_REPO}"
  assert_success
  run ddev restart -y
  assert_success
  health_checks
}
