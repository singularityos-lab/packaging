%global debug_package %{nil}

Name:           gstreamer1-plugin-voaacenc
Version:        1.28.6
Release:        1%{?dist}
Summary:        VisualOn AAC encoder for GStreamer
License:        LGPL-2.0-or-later
URL:            https://gstreamer.freedesktop.org/
Source0:        https://gstreamer.freedesktop.org/src/gst-plugins-bad/gst-plugins-bad-%{version}.tar.xz
BuildRequires:  gcc
BuildRequires:  pkgconfig(gstreamer-1.0)
BuildRequires:  pkgconfig(gstreamer-audio-1.0)
BuildRequires:  pkgconfig(gstreamer-pbutils-1.0)
BuildRequires:  pkgconfig(vo-aacenc)
BuildRequires:  gstreamer1
Requires:       gstreamer1 >= 1.28
Provides:       gstreamer1(element-voaacenc)
Provides:       gstreamer1(element-voaacenc)(64bit)

%description
AAC encoder plugin from the upstream GStreamer Bad Plug-ins source.

%prep
%setup -q -n gst-plugins-bad-%{version}

%build
%set_build_flags
%{__cc} %{optflags} -fPIC -shared \
    '-DVERSION="%{version}"' '-DPACKAGE="gst-plugins-bad"' \
    '-DGST_PACKAGE_NAME="GStreamer Bad Plug-ins"' \
    '-DGST_PACKAGE_ORIGIN="https://gstreamer.freedesktop.org/"' \
    ext/voaacenc/gstvoaac.c ext/voaacenc/gstvoaacenc.c \
    $(pkg-config --cflags --libs gstreamer-audio-1.0 gstreamer-pbutils-1.0 vo-aacenc) \
    %{build_ldflags} -o libgstvoaacenc.so

%install
install -Dpm 755 libgstvoaacenc.so %{buildroot}%{_libdir}/gstreamer-1.0/libgstvoaacenc.so

%check
export GST_PLUGIN_PATH_1_0="$PWD" GST_REGISTRY_1_0="$PWD/test-registry.bin"
gst-inspect-1.0 voaacenc
gst-launch-1.0 -q audiotestsrc num-buffers=20 ! audioconvert ! voaacenc ! filesink location="$PWD/test.aac"
test -s test.aac

%files
%license COPYING
%{_libdir}/gstreamer-1.0/libgstvoaacenc.so
