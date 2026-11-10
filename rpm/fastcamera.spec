# SPDX-FileCopyrightText: 2013 - 2024 Jolla Ltd.
# SPDX-FileCopyrightText: 2019 - 2020 Open Mobile Platform LLC.
# SPDX-FileCopyrightText: 2025 Jolla Mobile Ltd
#
# SPDX-License-Identifier: BSD-3-Clause

Name:       fastcamera
Summary:    Camera application with lower shutter latency (fork of jolla-camera)
Version:    1.3.0
Release:    1
License:    BSD-3-Clause
URL:        https://github.com/sailfishos/jolla-camera
Source0:    %{name}-%{version}.tar.bz2
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Gui)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  pkgconfig(Qt5Network)
BuildRequires:  pkgconfig(Qt5Multimedia)
BuildRequires:  pkgconfig(Qt5Test)
BuildRequires:  pkgconfig(Qt5Multimedia)
BuildRequires:  pkgconfig(qdeclarative5-boostable)
BuildRequires:  pkgconfig(mlite5) >= 0.2.5
BuildRequires:  pkgconfig(systemsettings) >= 0.2.13
BuildRequires:  qt5-qttools
BuildRequires:  qt5-qttools-linguist

Requires:  sailfishsilica-qt5 >= 1.1.79
Requires:  qt5-qtdeclarative-import-models2
Requires:  qt5-qtdeclarative-import-positioning
Requires:  qt5-qtdeclarative-import-multimedia
Requires:  qt5-qtdeclarative-import-sensors
Requires:  qt5-qtmultimedia-plugin-mediaservice-gstcamerabin >= 5.6.2+git25
Requires:  qt5-qtmultimedia-plugin-mediaservice-gstmediaplayer
Requires:  declarative-transferengine-qt5 >= 0.0.49
Requires:  nemo-qml-plugin-thumbnailer-qt5
Requires:  nemo-qml-plugin-dbus-qt5
Requires:  nemo-qml-plugin-policy-qt5
Requires:  nemo-qml-plugin-time-qt5
Requires:  nemo-qml-plugin-configuration-qt5
Requires:  nemo-qml-plugin-notifications-qt5 >= 1.1.2
Requires:  nemo-qml-plugin-systemsettings >= 0.5.21
Requires:  libkeepalive >= 1.7.0
Requires:  sailfish-components-media-qt5 >= 0.0.18
Requires:  sailfish-components-gallery-qt5 >= 1.1.10
Requires:  sailfish-policy >= 0.2.59
Requires:  jolla-settings
Requires:  jolla-settings-system >= 1.0.70
Requires:  libngf-qt5-declarative
Requires:  qr-filter-qml-plugin
Requires:  sailfish-content-graphics >= 1.2.2
Requires:  gstreamer1.0-plugins-good
Requires:  gstreamer1.0-plugins-bad
Requires:  dconf
Requires:  sailjail-launch-approval
Requires:  mapplauncherd-booster-silica-qt5-media

# Translations and the dconf defaults under /apps/jolla-camera come from the stock app.
Requires:  jolla-camera >= 1.3.0

%description
A fork of the Sailfish OS camera application that installs alongside it
and bounds how long the shutter waits for autofocus.

%prep
%setup -q -n %{name}-%{version}

%build

%qmake5 jolla-camera.pro
%make_build

%install
%qmake5_install

%files
%license LICENSES/BSD-3-Clause.txt
%{_bindir}/fastcamera
%{_datadir}/applications/fastcamera.desktop
%{_datadir}/fastcamera
%{_libdir}/qt5/qml/fastcamera
%{_userunitdir}/user-session.target.d/50-fastcamera.conf
