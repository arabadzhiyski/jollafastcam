# Building and installing fastcamera (RHEL 9 host → Jolla Phone)

This guide builds the `fastcamera` RPM on a RHEL 9 computer with the Sailfish
**Platform SDK**, then installs it on the phone next to the stock Camera app.

The Platform SDK is a chroot (a self-contained Sailfish build environment in a
directory) that you enter with `sudo`. It needs **neither Docker nor VirtualBox**,
so your Podman setup is left alone. It is command-line only. The build tool is
`mb2`, and it produces the same RPM as the graphical Sailfish SDK.

> **Not checked against the current official docs.** docs.sailfishos.org was out of
> reach when this was written, so the steps come from how the Platform SDK has
> worked so far. Steps marked **(verify)** are the ones most likely to differ:
> mainly download URLs and file names. The authoritative pages are
> docs.sailfishos.org → Tools → Platform SDK → *Installation* and
> *Target Installation*. If a step doesn't match, keep the exact output; it's
> needed to adjust the step.

In the commands below, `PHONE_IP` stands for your phone's IP address.
Commands are run **on the RHEL host** unless the step says *inside the SDK* or
*on the phone*. The SDK shell prompt starts with `PlatformSDK` so you can tell
the two apart.

---

## Overview

| Part | Where | What |
|------|-------|------|
| 1 | Phone | Developer mode, SSH, OS version |
| 2 | RHEL 9 | Install the Platform SDK chroot |
| 3 | Inside the SDK | Install the aarch64 build target |
| 4 | RHEL 9 | Clone the code, copy one missing file from the phone |
| 5 | Inside the SDK | `mb2 build` |
| 6 | Phone | Install the RPM, launch |
| 7 | Phone | Troubleshooting, shutter timing log, removal |
| 8 | Phone + RHEL 9 | One session that collects all performance data |

---

## Part 1: Prepare the phone

1. **Note the OS version.** Settings → About product. Write down the Sailfish OS
   version (e.g. `5.0.0.xx`). You need it in Part 3.

2. **Enable Developer mode.** Settings → System → Developer tools → turn on
   **Developer mode**. This installs the terminal and the `devel-su` root tool.

3. **Enable SSH.** On the same page, set a **password** and turn on
   **Remote connection**. Note the IP address shown there. Put the phone on the
   same Wi-Fi as the computer.

4. **Test SSH from the computer.** The user name is `defaultuser` and the password
   is the one from step 3.

   ```bash
   ssh defaultuser@PHONE_IP
   ```

   Once logged in, confirm the version and the CPU architecture (expect `aarch64`):

   ```bash
   cat /etc/sailfish-release; uname -m
   ```

   Then leave the phone shell:

   ```bash
   exit
   ```

---

## Part 2: Install the Platform SDK on RHEL 9

5. **Install the tools to download and unpack the SDK.** These are usually
   already present. The target archives in Part 3 are unpacked by the SDK itself,
   so nothing else is needed on the host.

   ```bash
   sudo dnf -y install curl bzip2 tar
   ```

6. **Choose where the SDK lives, and remember it in your shell.** `/srv/sailfishos`
   is the conventional location. It needs a few GB.

   ```bash
   echo 'export PLATFORM_SDK_ROOT=/srv/sailfishos' >> ~/.bashrc
   ```

   ```bash
   echo 'alias sfossdk=$PLATFORM_SDK_ROOT/sdks/sfossdk/sdk-chroot' >> ~/.bashrc
   ```

   ```bash
   source ~/.bashrc
   ```

7. **Download the Platform SDK chroot (verify).** It's an i486 tarball. The 32-bit
   x86 build environment runs fine on an x86_64 RHEL kernel.

   ```bash
   curl -O https://releases.sailfishos.org/sdk/installers/latest/Jolla-latest-SailfishOS_Platform_SDK_Chroot-i486.tar.bz2
   ```

8. **Unpack it as root.** `--numeric-owner -p` keeps the file owners and
   permissions the chroot needs.

   ```bash
   sudo mkdir -p $PLATFORM_SDK_ROOT/sdks/sfossdk
   ```

   ```bash
   sudo tar --numeric-owner -p -xjf Jolla-latest-SailfishOS_Platform_SDK_Chroot-i486.tar.bz2 -C $PLATFORM_SDK_ROOT/sdks/sfossdk
   ```

9. **Give the SDK shell a recognisable prompt, then enter it.** The SDK reads
   `~/.mersdk.profile` on entry. `sfossdk` asks for your sudo password because it
   bind-mounts your home directory into the chroot. Your files are visible inside
   at the same paths.

   ```bash
   echo 'PS1="PlatformSDK $PS1"' > ~/.mersdk.profile
   ```

   ```bash
   sfossdk
   ```

   The prompt now starts with `PlatformSDK`. Type `exit` to leave. Run `sfossdk`
   again whenever a step says *inside the SDK*.

---

## Part 3: Install the build target (inside the SDK)

A *build target* is a copy of the phone's system libraries that you compile
against. You need two pieces, both installed with `sdk-assistant`: the
**tooling**, which holds the compiler and helper tools, and the **aarch64 target**.
Ideally both match the phone's version from step 1.

10. **Install the tooling and the aarch64 target (verify).** These URLs fetch the
    *latest* public release. For a specific version, browse
    `https://releases.sailfishos.org/sdk/targets/` and use the files whose names
    contain your version. Each download is several hundred MB.

    ```bash
    sdk-assistant create SailfishOS-latest https://releases.sailfishos.org/sdk/targets/Sailfish_OS-latest-Sailfish_SDK_Tooling-i486.tar.7z
    ```

    ```bash
    sdk-assistant create SailfishOS-latest-aarch64 https://releases.sailfishos.org/sdk/targets/Sailfish_OS-latest-Sailfish_SDK_Target-aarch64.tar.7z
    ```

    If the newest available target is slightly older than the phone's version,
    that's normally fine: apps built against an older release run on newer ones.

11. **Check what's installed.** Use the target's exact name in Part 5.

    ```bash
    sdk-assistant list
    ```

---

## Part 4: Get the code and the missing file (on the host)

Do this part in a normal RHEL terminal, not inside the SDK. `scp`/`ssh` to the
phone are simplest from the host.

12. **Clone the fork.** `fastcamera` is the default branch.

    ```bash
    git clone https://github.com/arabadzhiyski/jollafastcam.git ~/jollafastcam
    ```

13. **Copy `DisabledByMdmView.qml` from the phone.** The app uses this file, but
    Jolla's public repository doesn't contain it. Without it the app won't start.
    The stock Camera app on your phone has it. Try the first command; if it says
    "No such file", try the second.

    ```bash
    scp defaultuser@PHONE_IP:/usr/lib64/qt5/qml/com/jolla/camera/DisabledByMdmView.qml ~/jollafastcam/src/
    ```

    ```bash
    scp defaultuser@PHONE_IP:/usr/lib/qt5/qml/com/jolla/camera/DisabledByMdmView.qml ~/jollafastcam/src/
    ```

    If neither path exists, find it on the phone (over `ssh`):

    ```bash
    find / -name DisabledByMdmView.qml 2>/dev/null
    ```

---

## Part 5: Build (inside the SDK)

14. **Enter the SDK and go to the project.** Your home directory is mounted
    inside, so the path is the same.

    ```bash
    sfossdk
    ```

    ```bash
    cd ~/jollafastcam
    ```

15. **Build.** `mb2` reads `rpm/fastcamera.spec`, installs the build dependencies
    into the target, compiles, and packages. Use the exact target name from step 11.
    The first build is slower because it downloads those dependencies.

    ```bash
    mb2 -t SailfishOS-latest-aarch64 build
    ```

    The result is `RPMS/fastcamera-1.3.0-1.aarch64.rpm`:

    ```bash
    ls RPMS/
    ```

### If the build fails

- **`sfossdk` fails to enter, or mounts fail.** Check that `PLATFORM_SDK_ROOT`
  is set (`echo $PLATFORM_SDK_ROOT`) and that the files from step 8 are owned
  by root.
- **"Permission denied" on your files.** This can be SELinux. Check the denials,
  and keep the output rather than switching SELinux off:

  ```bash
  sudo ausearch -m avc -ts recent
  ```

- **"nothing provides …" or a missing BuildRequires.** A build dependency in the
  spec isn't in the target's repositories. Note the package name.

Keep the last 30–40 lines of output for any of these.

---

## Part 6: Install on the phone (from the host)

16. **Copy the RPM to the phone.** Run this in a normal RHEL terminal, not the SDK.

    ```bash
    scp ~/jollafastcam/RPMS/fastcamera-*.aarch64.rpm defaultuser@PHONE_IP:
    ```

17. **Log in and install as root.** `devel-su` asks for the developer password from
    step 3. `pkcon` also installs anything the app depends on.

    ```bash
    ssh defaultuser@PHONE_IP
    ```

    ```bash
    devel-su pkcon install-local ~/fastcamera-*.aarch64.rpm
    ```

    If `pkcon` refuses because of signatures, use `rpm` instead. It doesn't fetch
    dependencies, but the stock Camera app already has them all installed.

    ```bash
    devel-su rpm -Uvh ~/fastcamera-*.aarch64.rpm
    ```

18. **Launch.** **Fast Camera** appears in the app grid with the normal camera icon.
    On first launch Sailfish asks you to approve its permissions (camera,
    microphone, location, and so on).

To install a newer build later, repeat steps 14–17. `rpm -Uvh` upgrades in place.

---

## Part 7: Troubleshooting, timing log, removal

### The app doesn't start

Watch the system log on the phone while you tap the icon:

```bash
devel-su journalctl -f
```

Look for QML errors (`file:///...qml:LINE: ...`) and Sailjail (sandbox) messages.
The sandbox ID `local/fastcamera` is a placeholder that hasn't been tried on a
device yet, so a sandbox refusal is a known possibility.

### Shutter timing log

Turn the log on. Run this as `defaultuser`, **without** `devel-su`, because
settings are per user:

```bash
dconf write /apps/fastcamera/shutterTimingLog true
```

Then follow it while taking photos:

```bash
devel-su journalctl -f | grep fastcamera-shutter
```

Each photo prints its timeline:

```
+0    shutter pressed, autofocus triggered
+N    capture requested, ...              (finger lifted)
+N    focus locked / unlocked             (autofocus result)
+N    capture sent to camera
+N    image exposed (shutter callback)    (after Android's exposure precapture + exposure)
+N    image saved                         (JPEG encoded and written)
```

- A long gap before **focus locked** means autofocus is the bottleneck. Tune the
  wait (milliseconds; `0` = don't trigger autofocus on the shutter, `-1` = stock
  behaviour):

  ```bash
  dconf write /apps/fastcamera/shutterFocusWaitMs 200
  ```

- A long gap between **capture sent to camera** and **image exposed** means the
  delay is below the app, in Android's exposure precapture on the phone.

Turn the log off again:

```bash
dconf write /apps/fastcamera/shutterTimingLog false
```

### Remove the app

```bash
devel-su pkcon remove fastcamera
```

The stock Camera app is untouched throughout. The two share camera settings
(flash, resolution, etc.) but nothing else.

---

## Part 8: Collect performance data (one session)

This session records everything needed to find where time goes beyond the
shutter. It produces three files:

| File | Recorded by | Answers |
|------|-------------|---------|
| `fastcamera-run.log` | the app, launched from the phone's Terminal | Startup time per stage; zero-copy or copying viewfinder; viewfinder vs. screen resolution; per-photo timeline |
| `logcat.txt` | Android's log, over SSH | Whether Android's camera service hits its exposure-precapture timeouts |
| `journal-camera.txt` | the system journal | Errors and warnings from the camera stack around the session |

You need the phone's **Terminal** app (installed with Developer mode) and an SSH
session from the computer, both at the same time.

### 8.1 Before you start

19. **Close the stock Camera app.** Only one app can hold the camera. Swipe it
    away if it's running.

20. **Turn on the app's diagnostic log.** Run this on the phone as `defaultuser`,
    without `devel-su`:

    ```bash
    dconf write /apps/fastcamera/shutterTimingLog true
    ```

### 8.2 Start the Android log (SSH session from the computer)

21. **Find `logcat`.** It's in the Android part of the system. The usual path on
    Sailfish devices is below. If that path doesn't exist, the `find` command
    locates it.

    ```bash
    ssh defaultuser@PHONE_IP
    ```

    ```bash
    ls /usr/libexec/droid-hybris/system/bin/logcat
    ```

    ```bash
    devel-su find / -name logcat -type f 2>/dev/null
    ```

22. **Clear old entries, then record to a file.** Use the path from step 21.
    Leave this running until step 27.

    ```bash
    devel-su /usr/libexec/droid-hybris/system/bin/logcat -c
    ```

    ```bash
    devel-su /usr/libexec/droid-hybris/system/bin/logcat -v time > ~/logcat.txt
    ```

### 8.3 Run the app from the phone's Terminal

23. **Launch fastcamera with startup logging, writing everything to a file.** Open
    the **Terminal** app on the phone and run:

    ```bash
    CAMERA_STARTUP_LOG=1 fastcamera 2>&1 | tee ~/fastcamera-run.log
    ```

    Launched this way the app runs without the app booster and outside the
    sandbox, so it starts a little slower than from its icon. The breakdown per
    stage is still what matters.

24. **Take photos in this order.** Wait about two seconds between photos unless a
    step says otherwise.
    1. 5 photos of a well-lit scene, tapping the shutter normally.
    2. 5 photos of a dim scene, e.g. indoors with the lights low.
    3. 5 photos as fast as you can tap, to measure time between shots.
    4. Switch to the front camera and take 2 photos, then switch back.

25. **Close the app.** Swipe it away. The Terminal shows the command finishing.

### 8.4 Stop and collect

26. **Stop the Android log.** In the SSH session, press **Ctrl+C**.

27. **Save the camera-related part of the journal.** Still in the SSH session:

    ```bash
    devel-su journalctl -b --no-pager | grep -iE "fastcamera|CAMERA_STARTUP|droid|camera|gst" > ~/journal-camera.txt
    ```

28. **Copy the three files to the computer.** Run this on the computer:

    ```bash
    scp defaultuser@PHONE_IP:'~/fastcamera-run.log ~/logcat.txt ~/journal-camera.txt' .
    ```

29. **Turn the diagnostic log off again.** Run this on the phone as `defaultuser`:

    ```bash
    dconf write /apps/fastcamera/shutterTimingLog false
    ```

### 8.5 What the files show

You can check a few things yourself before sending the files on:

- **Startup stages.** In `fastcamera-run.log`, lines starting `CAMERA_STARTUP`
  carry milliseconds since launch, from the app (`app ...`) and from gst-droid
  (`gst-droid-dev ...`). A big jump between two lines points at that stage.
- **Viewfinder path.** Search `fastcamera-run.log`:
  - `first buffer-queue frame available` means **zero-copy**: frames go
    straight to the GPU.
  - `first raw preview callback` means **copying**: every preview frame is
    copied before display, which costs frame rate, battery and heat.

  If neither line appears, the installed gst-droid predates this logging. Say so
  when sending the files.
- **Resolutions.** The line `fastcamera-shutter camera active: viewfinder ...`
  gives the streamed viewfinder size and the size of the on-screen area. A
  viewfinder much larger than the screen area is wasted work.
- **Per photo.** The `fastcamera-shutter +N ms` lines, as described in Part 7.
- **Exposure timeouts.** Search `logcat.txt`:

  ```bash
  grep -iE "precapture|CaptureSequencer|Camera2Client" logcat.txt
  ```

  A line like `Timed out waiting for precapture start` (or `end`) means Android's
  camera service waited 1 s (start) or 4 s (end) for the camera hardware's
  exposure measurement. That delay is below every open-source layer.

Send all three files for the full analysis.
