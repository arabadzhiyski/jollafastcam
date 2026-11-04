# SPDX-FileCopyrightText: 2014 - 2021 Jolla Ltd.
# SPDX-FileCopyrightText: 2025 Jolla Mobile Ltd
#
# SPDX-License-Identifier: BSD-3-Clause

TEMPLATE = lib
TARGET  = fastcameraplugin
TARGET = $$qtLibraryTarget($$TARGET)

MODULENAME = fastcamera
TARGETPATH = $$[QT_INSTALL_QML]/$$MODULENAME

QT += gui-private qml quick multimedia
CONFIG += plugin link_pkgconfig c++14

PKGCONFIG += mlite5 systemsettings

SOURCES += \
        cameraplugin.cpp \
        capturemodel.cpp \
        declarativecameraextensions.cpp \
        declarativesettings.cpp \
        cameraconfigs.cpp

HEADERS += \
        capturemodel.h \
        declarativecameraextensions.h \
        declarativesettings.h \
        cameraconfigs.h

DEFINES += \
        DEPLOYMENT_PATH=\"\\\"\"$${TARGETPATH}/\"\\\"\"

import.files = \
        DisabledByMdmView.qml \
        CameraPage.qml \
        capture \
        gallery \
        qmldir \
        settings \
        settings.qml

import.path = $$TARGETPATH
target.path = $$TARGETPATH

INSTALLS += target import

OTHER_FILES = \
        DisabledByMdmView.qml \
        CameraPage.qml \
        capture/*.qml \
        gallery/*.qml \
        settings/*.qml \
        settings.qml \
        qmldir
