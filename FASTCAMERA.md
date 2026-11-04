# fastcamera

A fork of [sailfishos/jolla-camera](https://github.com/sailfishos/jolla-camera)
that installs alongside the stock camera and bounds how long the shutter waits
for autofocus.

## What differs from the stock app

- **Names.** Binary `fastcamera`, data in `/usr/share/fastcamera`, QML module
  `fastcamera`, D-Bus name `local.fastcamera`, Sailjail app `local/fastcamera`.
- **Shutter focus wait.** In continuous focus mode with the automatic focus
  point, the stock app triggers an autofocus scan on shutter press and waits for
  the result however long it takes. fastcamera waits at most
  `/apps/fastcamera/shutterFocusWaitMs` milliseconds (default 300) after the
  capture request:
  - `-1` waits for the lock (stock behaviour)
  - `0` does not trigger autofocus from the shutter; captures on continuous focus
  - `N` waits at most N ms

  Tap-to-focus, and cameras without continuous focus, still wait for the lock.
- **Shutter timing log.** `/apps/fastcamera/shutterTimingLog` set to `true`
  logs each still capture's timeline (`fastcamera-shutter +<ms> ...`).
- **Not built:** lockscreen camera, quick actions, settings page entry,
  translations, tests, D-Bus activation, booster pre-start. Translations and the
  dconf defaults under `/apps/jolla-camera` come from the stock package, so camera
  settings are shared with the stock app.

## Missing upstream file

`src/DisabledByMdmView.qml` is used by `src/CameraPage.qml` and listed in
`src/qmldir`, but it isn't in the public repository. Copy it from a device with
the stock app installed (`.../qt5/qml/com/jolla/camera/DisabledByMdmView.qml`
under `/usr/lib64` or `/usr/lib`) into `src/` before building.

## Reading the timing log

```
+0    shutter pressed, autofocus triggered
+N    capture requested, ...              (shutter released)
+N    focus locked / unlocked             (autofocus result)
+N    capture sent to camera
+N    image exposed (shutter callback)    (after Android's AE precapture + exposure)
+N    image saved                         (JPEG encode + write)
```

A long gap between "capture sent to camera" and "image exposed" points below
the app: Android's camera service runs an AE precapture sequence there, which
times out after 1 s (start) plus 4 s (end) when the camera HAL doesn't report
the expected exposure states.
