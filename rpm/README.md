# Nobara RPMs

These recipes and package snapshots are intended for distribution packagers,
not end users. Distribution-specific configuration or integration may still be
missing; review and complete the packaging before distributing it to users.

Target: Nobara 44, x86_64. This snapshot builds the complete desktop and bundled
applications, including gestures. The Singularity OS installer is disabled.
Nobara supplies the system dependencies; three local prerequisite packages are
included where its repositories do not provide them.

## Layout

- `SPECS/`: the desktop spec and the vala-cups, voaacenc and librespot specs.
- `SOURCES/`: packaging scripts, compatibility patches, native regression checks
  and source provenance. Source/vendor archives are embedded in the source RPMs.
- `SRPMS/` and `RPMS/`: local download directories populated by `fetch.sh`.
- `SRPM-SHA256SUMS` and `RPM-SHA256SUMS`: checksums for the published packages.

## Packages

The [snapshot release](https://github.com/singularityos-lab/packaging/releases/tag/rpm-nobara44-20261008)
contains 89 binary RPMs and these four source RPMs:

| Source RPM | Contents |
| --- | --- |
| [singularity-desktop-0.1.0-1.fc44.src.rpm](https://github.com/singularityos-lab/packaging/releases/download/rpm-nobara44-20261008/singularity-desktop-0.1.0-1.fc44.src.rpm) | Desktop, applications, private compositor/input/fingerprint libraries, development packages, patches and checks |
| [vala-cups-20240428-1.fc44.src.rpm](https://github.com/singularityos-lab/packaging/releases/download/rpm-nobara44-20261008/vala-cups-20240428-1.fc44.src.rpm) | CUPS Vala bindings from a pinned GNOME revision |
| [gstreamer1-plugin-voaacenc-1.28.6-1.fc44.src.rpm](https://github.com/singularityos-lab/packaging/releases/download/rpm-nobara44-20261008/gstreamer1-plugin-voaacenc-1.28.6-1.fc44.src.rpm) | GStreamer VisualOn AAC encoder |
| [librespot-0.8.0-1.fc44.src.rpm](https://github.com/singularityos-lab/packaging/releases/download/rpm-nobara44-20261008/librespot-0.8.0-1.fc44.src.rpm) | Locked, vendored Rust client with pipe backend and Rustls roots |

The desktop archive includes the source changes present at packaging time.
It is a tested development snapshot, not an upstream release. The source RPMs
retain the exact build inputs, including source/vendor archives and license
notices. `source-manifest.json` records the initial snapshot and its per-repository
revisions; its build-status fields describe that earlier stage. See
[verification](VERIFICATION.md) for the final results.

## Download and test

Use [GitHub CLI](https://cli.github.com/) to download the packages. For a test
installation in a Nobara 44 VM, run from the repository root:

```sh
./rpm/fetch.sh all
sudo dnf install ./rpm/RPMS/x86_64/*.rpm ./rpm/RPMS/noarch/*.rpm
sudo systemctl daemon-reload
sudo reboot
```

Select Singularity in GDM. GNOME and GDM remain installed. These local packages
are unsigned; `fetch.sh` verifies their SHA256 checksums before installation.

## Rebuild

Run as an ordinary user on Nobara 44. Download only the source RPMs:

```sh
./rpm/fetch.sh
export TMPDIR="$HOME/artifacts/rpm"
export TMP="$TMPDIR" TEMP="$TMPDIR"
mkdir -p "$TMPDIR"
```

Build and install the two prerequisites used by the desktop build:

```sh
sudo dnf builddep ./rpm/SRPMS/vala-cups-20240428-1.fc44.src.rpm
rpmbuild --rebuild ./rpm/SRPMS/vala-cups-20240428-1.fc44.src.rpm
sudo dnf install ~/rpmbuild/RPMS/noarch/vala-cups-20240428-1.fc44.noarch.rpm
sudo dnf builddep ./rpm/SRPMS/gstreamer1-plugin-voaacenc-1.28.6-1.fc44.src.rpm
rpmbuild --rebuild ./rpm/SRPMS/gstreamer1-plugin-voaacenc-1.28.6-1.fc44.src.rpm
sudo dnf install ~/rpmbuild/RPMS/x86_64/gstreamer1-plugin-voaacenc-1.28.6-1.fc44.x86_64.rpm
```

Build the playback client and desktop:

```sh
sudo dnf builddep ./rpm/SRPMS/librespot-0.8.0-1.fc44.src.rpm
rpmbuild --rebuild ./rpm/SRPMS/librespot-0.8.0-1.fc44.src.rpm
sudo dnf builddep ./rpm/SRPMS/singularity-desktop-0.1.0-1.fc44.src.rpm
rpmbuild --rebuild ./rpm/SRPMS/singularity-desktop-0.1.0-1.fc44.src.rpm
```

Keep only variable Cantarell installed for the Publish variation test; static
Cantarell with the same family name takes priority in Fontconfig. The tested
configuration uses `abattis-cantarell-vf-fonts`. Checks use private Xvfb/D-Bus
sessions, short temporary paths and longer deadlines for VM disk I/O.

To edit recipes, unpack the complete source RPM inputs into this checkout:

```sh
rpm -i --define "_topdir $PWD/rpm" ./rpm/SRPMS/*.src.rpm
```

`SPECS/` and the tracked `SOURCES/` files match the published source RPMs.
Changes to a spec or patch require a new source RPM and updated checksums.
