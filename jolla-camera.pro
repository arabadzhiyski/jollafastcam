# SPDX-FileCopyrightText: 2013 - 2017 Jolla Ltd.
# SPDX-FileCopyrightText: 2024 - 2025 Jolla Mobile Ltd
#
# SPDX-License-Identifier: BSD-3-Clause

TEMPLATE = subdirs

# fastcamera: only the app and its QML module are built. The lockscreen camera,
# quick actions, settings entry, translations and tests stay with the stock
# jolla-camera package, which this one installs alongside.
SUBDIRS = \
        application.pro \
        src

OTHER_FILES = rpm/*.spec
