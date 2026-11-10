# SPDX-FileCopyrightText: 2013 - 2021 Jolla Ltd.
# SPDX-FileCopyrightText: 2025 Jolla Mobile Ltd
#
# SPDX-License-Identifier: BSD-3-Clause

TEMPLATE = app
TARGET = fastcamera
TARGETPATH = /usr/bin

QT += qml quick
CONFIG += link_pkgconfig

SOURCES += camera.cpp

OTHER_FILES += \
        camera.qml \
        settings.qml \
        cover \
        pages \
        pages/*.qml \
        pages/gallery/*.qml \
        dconf/00-jolla-camera.txt

target.path = $$TARGETPATH

desktop.path = /usr/share/applications
desktop.files = fastcamera.desktop

DEPLOYMENT_PATH = /usr/share/$$TARGET
DEFINES *= DEPLOYMENT_PATH=\"\\\"\"$${DEPLOYMENT_PATH}/\"\\\"\"
qml.path = $$DEPLOYMENT_PATH
qml.files = *.qml cover pages

# fastcamera: no D-Bus activation file, dconf schema or oneshot. The settings defaults (and any device-specific ones the hardware
# adaptation adds) come from the stock jolla-camera package under
# /apps/jolla-camera, which this app reads and writes as well.
INSTALLS += target desktop qml

# Pre-start the sandboxed booster that invoker -A in the desktop file needs.
usersession.path = /usr/lib/systemd/user/user-session.target.d
usersession.files = 50-fastcamera.conf
INSTALLS += usersession

packagesExist(qdeclarative5-boostable) {
    message("Building with qdeclarative-boostable support")
    DEFINES += HAS_BOOSTER
    PKGCONFIG += qdeclarative5-boostable
} else {
    warning("qdeclarative-boostable not available; startup times will be slower")
}
