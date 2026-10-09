%global debug_package %{nil}

Name:           librespot
Version:        0.8.0
Release:        1%{?dist}
Summary:        Spotify playback client for Singularity media plugins
License:        MIT AND Apache-2.0 AND BSD-3-Clause AND ISC AND Unicode-3.0 AND MPL-2.0 AND Zlib AND CDLA-Permissive-2.0
URL:            https://github.com/librespot-org/librespot
Source0:        https://static.crates.io/crates/librespot/librespot-%{version}.crate
Source1:        librespot-vendor.tar.zst
BuildRequires:  cargo
BuildRequires:  rust
BuildRequires:  gcc
BuildRequires:  gcc-c++
BuildRequires:  pkgconf-pkg-config

%description
Librespot playback client with the pipe backend and Rustls certificate roots.
Dependencies are vendored from the locked release manifest.

%prep
%setup -q
 tar --zstd -xf %{SOURCE1}

%build
%set_build_flags
export CARGO_HOME="$PWD/.cargo-home" CARGO_TARGET_DIR="$PWD/target"
export RUSTFLAGS="-C link-arg=-Wl,-z,relro -C link-arg=-Wl,-z,now"
cargo build --frozen --offline --release --no-default-features --features rustls-tls-webpki-roots -j 3

%install
install -Dpm 755 target/release/librespot %{buildroot}%{_bindir}/librespot

%check
target/release/librespot --version
target/release/librespot --backend "?" > backends.txt
grep -F -- "- pipe" backends.txt

%files
%license LICENSE dependency-notices dependencies.json
%{_bindir}/librespot
