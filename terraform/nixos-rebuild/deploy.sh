#!/usr/bin/env bash

set -uex -o pipefail

if [ "$#" -ne 6 ]; then
  echo "USAGE: $0 SWITCH_CMD NIXOS_SYSTEM TARGET_USER TARGET_HOST TARGET_PORT IGNORE_SYSTEMD_ERRORS" >&2
  exit 1
fi

SWITCH_CMD=$1
NIXOS_SYSTEM=$2
TARGET_USER=$3
TARGET_HOST=$4
TARGET_PORT=$5
IGNORE_SYSTEMD_ERRORS=$6
shift 3

TARGET="${TARGET_USER}@${TARGET_HOST}"

workDir=$(mktemp -d)
trap 'rm -rf "$workDir"' EXIT

sshOpts=(-p "${TARGET_PORT}")
sshOpts+=(-o UserKnownHostsFile=/dev/null)
sshOpts+=(-o StrictHostKeyChecking=no)

set +x
if [[ -n ${SSH_KEY+x} && ${SSH_KEY} != "-" ]]; then
  sshPrivateKeyFile="$workDir/ssh_key"
  # Create the file with 0700 - umask calculation: 777 - 700 = 077
  (
    umask 077
    echo "$SSH_KEY" >"$sshPrivateKeyFile"
  )
  unset SSH_AUTH_SOCK # don't use system agent if key was supplied
  sshOpts+=(-o "IdentityFile=${sshPrivateKeyFile}")
fi
set -x

try=1
until NIX_SSHOPTS="${sshOpts[*]}" nix copy -s --experimental-features nix-command --to "ssh://$TARGET" "$NIXOS_SYSTEM"; do
  if [[ $try -gt 10 ]]; then
    echo "retries exhausted" >&2
    exit 1
  fi
  sleep 10
  try=$((try + 1))
done

switchCommand="nix-env -p /nix/var/nix/profiles/system --set $(printf "%q" "$NIXOS_SYSTEM"); /nix/var/nix/profiles/system/bin/switch-to-configuration ${SWITCH_CMD}"
if [[ $TARGET_USER != "root" ]]; then
  switchCommand="sudo bash -c '$switchCommand'"
fi
deploy_status=0
# shellcheck disable=SC2029
ssh "${sshOpts[@]}" "$TARGET" "$switchCommand" || deploy_status="$?"
if [[ $IGNORE_SYSTEMD_ERRORS == "true" && $deploy_status == "4" ]]; then
  exit 0
fi
exit "$deploy_status"
