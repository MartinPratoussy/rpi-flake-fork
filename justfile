alias b := build
alias d := deploy
alias c := check
alias u := update

hostname := "lithium"
domain := "lithium.ovh"

# Build flake
build *FLAGS:
    nh os build .#{{ hostname }} --target-host nixos@{{domain}} {{FLAGS}}

# Deploy to target (switch)
deploy *FLAGS:
    nh os switch .#{{ hostname }} --target-host nixos@{{domain}} {{FLAGS}}

# Deploy to target (next boot)
boot *FLAGS:
    nh os boot .#{{ hostname }} --target-host nixos@{{domain}} {{FLAGS}}

# Nix flake check
check:
    nix flake check

# Nix flake update
update:
    nix flake update --commit-lock-file

# SSH into server
ssh:
    ssh nixos@{{domain}}

diff commit="HEAD~1":
    #!/usr/bin/env bash
    set -euo pipefail

    TMPDIR=$(mktemp -d)
    trap "git worktree remove --force $TMPDIR 2>/dev/null; rm -rf $TMPDIR" EXIT

    echo "Checking out {{ commit }} into $TMPDIR..."
    git worktree add --detach "$TMPDIR" {{ commit }}

    echo "Building old config ({{ commit }})..."
    before=$(nix build "$TMPDIR#nixosConfigurations.{{ hostname }}.config.system.build.toplevel" \
        --no-link --print-out-paths)

    echo "Building current config..."
    after=$(nix build ".#nixosConfigurations.{{ hostname }}.config.system.build.toplevel" \
        --no-link --print-out-paths)

    echo "Diff:"
    dix --force-correctness "$before" "$after"
