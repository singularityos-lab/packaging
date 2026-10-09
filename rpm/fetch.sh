#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"
REPOSITORY=singularityos-lab/packaging
RELEASE=rpm-nobara44-20261008
MODE="${1:-sources}"

case "$MODE" in
    sources|all) ;;
    *) echo "Usage: $0 [sources|all]" >&2; exit 2 ;;
esac

mkdir -p SRPMS
gh release download "$RELEASE" --repo "$REPOSITORY" \
    --pattern '*.src.rpm' --dir SRPMS --skip-existing
sha256sum -c SRPM-SHA256SUMS

if [ "$MODE" = all ]; then
    mkdir -p RPMS/x86_64 RPMS/noarch
    gh release download "$RELEASE" --repo "$REPOSITORY" \
        --pattern '*.x86_64.rpm' --dir RPMS/x86_64 --skip-existing
    gh release download "$RELEASE" --repo "$REPOSITORY" \
        --pattern '*.noarch.rpm' --dir RPMS/noarch --skip-existing
    sha256sum -c RPM-SHA256SUMS
fi
