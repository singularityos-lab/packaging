%global debug_package %{nil}
Name:           vala-cups
Version:        20240428
Release:        1%{?dist}
Summary:        Vala bindings for CUPS
License:        MIT
URL:            https://gitlab.gnome.org/GNOME/vala-extra-vapis
Source0:        cups.vapi
Source1:        cups-source.json
BuildArch:      noarch
BuildRequires:  vala
BuildRequires:  pkgconfig(cups)
Requires:       vala
Requires:       pkgconfig(cups)

%description
CUPS bindings from GNOME vala-extra-vapis.

%prep
%setup -q -c -T
cp %{SOURCE0} %{SOURCE1} .

%build
printf 'int main () { return 0; }\n' > binding-check.vala
valac --vapidir=. --pkg cups -C binding-check.vala

%install
install -Dpm 0644 cups.vapi %{buildroot}%{_datadir}/vala/vapi/cups.vapi

%files
%{_datadir}/vala/vapi/cups.vapi
%doc cups-source.json
