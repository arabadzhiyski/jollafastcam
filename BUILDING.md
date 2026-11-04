# Building and installing fastcamera (RHEL 9 host → Jolla Phone)

This guide builds the `fastcamera` RPM on a RHEL 9 computer with the Sailfish SDK,
then installs it on the phone next to the stock Camera app.

> **Not checked against the current official docs.** docs.sailfishos.org was out of
> reach when this was written, so the steps come from how the Sailfish SDK and its
> `sfdk` tool have worked so far. Steps marked **(verify)** are the ones most likely
> to differ. If one doesn't match what you see, keep the exact output; it's needed
> to adjust the step.

In the commands below, `PHONE_IP` stands for your phone's IP address.

---

## Overview

| Part | Where | What |
|------|-------|------|
| 1 | Phone | Developer mode, SSH, OS version |
| 2 | RHEL 9 | Docker CE and the Sailfish SDK |
| 3 | RHEL 9 | A build target matching the phone |
| 4 | RHEL 9 | Clone the code, copy one missing file from the phone |
| 5 | RHEL 9 | `sfdk build` |
| 6 | Phone | Install the RPM, launch |
| 7 | Phone | Troubleshooting, shutter timing log, removal |

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

## Part 2: Install Docker CE and the Sailfish SDK on RHEL 9

The SDK compiles inside a container called the *build engine*, using Docker
(or VirtualBox). RHEL 9 ships Podman instead of Docker, and the SDK expects real
Docker, so install Docker CE from Docker's own repository.

### 2.1 Docker CE

5. **Remove conflicting packages if present.** Docker's RHEL instructions ask you to
   remove Podman's Docker shim and `runc`. Skip this if you rely on Podman for
   other work. The two can coexist as long as `podman-docker` isn't installed.

   ```bash
   sudo dnf remove -y podman-docker runc
   ```

6. **Add Docker's repository and install Docker.**

   ```bash
   sudo dnf -y install dnf-plugins-core
   ```

   ```bash
   sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
   ```

   ```bash
   sudo dnf -y install docker-ce docker-ce-cli containerd.io
   ```

7. **Start Docker now and on every boot.**

   ```bash
   sudo systemctl enable --now docker
   ```

8. **Let your user run Docker without sudo.** The SDK needs this.

   ```bash
   sudo usermod -aG docker $USER
   ```

   **Log out and log back in** (or reboot) so the group change takes effect. Then check:

   ```bash
   docker run --rm hello-world
   ```

   It should print "Hello from Docker!".

### 2.2 Sailfish SDK

9. **Download the installer.** On docs.sailfishos.org go to Tools → Sailfish SDK →
   Installation and download the **Linux 64-bit** installer, a `.run` file. Take the
   newest version. Older ones can fail on hosts with cgroups v2, which RHEL 9 uses.

10. **Install the libraries the graphical installer needs.** The installer is a Qt
    GUI app. On a RHEL 9 Workstation most of these are already present.

    ```bash
    sudo dnf -y install libxkbcommon-x11 xcb-util-wm xcb-util-image xcb-util-keysyms xcb-util-renderutil
    ```

11. **Run the installer.** Run it as your normal user, not root, and from a graphical
    session.

    ```bash
    chmod +x ~/Downloads/SailfishSDK-*.run
    ```

    ```bash
    ~/Downloads/SailfishSDK-*.run
    ```

    - Install location: keep the default `~/SailfishOS`.
    - Build engine: choose **Docker**.
    - Components: the defaults are fine. Build targets are handled in Part 3.

12. **Put `sfdk` on your PATH.** `sfdk` is the SDK's command-line build tool.

    ```bash
    echo 'export PATH="$HOME/SailfishOS/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
    ```

    ```bash
    sfdk --version
    ```

---

## Part 3: Install a build target for the phone

A *build target* is a copy of the phone's system libraries that you compile against.
It must be **aarch64**, and its version should match the phone's version from
step 1.

13. **List the installed tools and targets.**

    ```bash
    sfdk tools list
    ```

14. **If no aarch64 target matching your phone is listed, install one.**

    - **GUI (easiest):** run the *SDK Maintenance Tool* in `~/SailfishOS`, choose
      **Add or remove components**, and tick the build target
      `SailfishOS-<your version>-aarch64`.
    - **Command line (verify):**

      ```bash
      sfdk tools list --available
      ```

      ```bash
      sfdk tools install SailfishOS-5.0.0.xx-aarch64
      ```

    If the newest available target is slightly older than the phone's version,
    that's normally fine: apps built against an older release run on newer ones.

---

## Part 4: Get the code and the missing file

15. **Clone the fork.** `fastcamera` is the default branch.

    ```bash
    git clone https://github.com/arabadzhiyski/jollafastcam.git ~/jollafastcam
    ```

16. **Copy `DisabledByMdmView.qml` from the phone.** The app uses this file, but
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

## Part 5: Build

17. **Go to the project and select the target.** Use the exact target name from
    step 13 or 14.

    ```bash
    cd ~/jollafastcam
    ```

    ```bash
    sfdk config target=SailfishOS-5.0.0.xx-aarch64
    ```

18. **Build.** `sfdk` reads `rpm/fastcamera.spec`, installs the build dependencies
    into the target, compiles, and packages. The first build is slower because it
    downloads those dependencies.

    ```bash
    sfdk build
    ```

    The result is `RPMS/fastcamera-1.3.0-1.aarch64.rpm`:

    ```bash
    ls RPMS/
    ```

### If the build fails

- **The build engine won't start.** Check that Docker runs (`docker ps`) and that
  you logged out and back in after step 8. Check that you have the newest SDK
  (cgroups v2).
- **"Permission denied" on project files.** This can be SELinux blocking the
  container from reading your home directory. Check the denials, and keep the
  output rather than switching SELinux off:

  ```bash
  sudo ausearch -m avc -ts recent
  ```

- **"nothing provides …" or a missing BuildRequires.** A build dependency in the
  spec isn't in the target's repositories. Note the package name.

Keep the last 30–40 lines of output for any of these.

---

## Part 6: Install on the phone

19. **Copy the RPM to the phone.**

    ```bash
    scp RPMS/fastcamera-*.aarch64.rpm defaultuser@PHONE_IP:
    ```

20. **Log in and install as root.** `devel-su` asks for the developer password from
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

21. **Launch.** **Fast Camera** appears in the app grid with the normal camera icon.
    On first launch Sailfish asks you to approve its permissions (camera,
    microphone, location, and so on).

To install a newer build later, repeat steps 18–20. `rpm -Uvh` upgrades in place.

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
