# ARM (aarch64) Virt-Based Emulator on Extended Ubuntu 22.04 (Jammy) Cloud Image

This guide explains how to set up an ARM (aarch64) virtual environment using **QEMU** with an extended Ubuntu 22.04 (Jammy) cloud image.

## How to Set Up

### Download the Base Cloud Image

#### Source
Ubuntu provides cloud images at:  
[https://cloud-images.ubuntu.com/jammy/20250112/](https://cloud-images.ubuntu.com/jammy/20250112/)

#### Download Command
Download the image to a dedicated folder (`./base_images`):

```sh
mkdir -p ./base_images
wget -vc https://cloud-images.ubuntu.com/jammy/20250112/jammy-server-cloudimg-arm64.tar.gz -O ./base_images/jammy-server-cloudimg-arm64.tar.gz
```

### Prepare the Image

#### Extract the `.img` File
Unpack the downloaded archive to retrieve the `.img` file:

```sh
cd ./base_images
tar -xvf jammy-server-cloudimg-arm64.tar.gz
```

#### Resize the Image
After testing with **LightDM** and **XFCE4** (along with optional packages like `gcc`, `g++`, `cmake`, `make`, and `automake`), the disk usage is around **3-5 GB**.
To ensure enough space for additional installations (e.g., KDE), it's recommended to **resize the image to at least 16 GB** (32 GB is preferred).

```sh
qemu-img resize -f raw jammy-server-cloudimg-arm64.img 32G
```

### Generate cloud-init.iso

``` sh
./sample_prepare_image.sh path_to_public_key_file
```
Why is cloud-init.iso needed?
- It initializes the Ubuntu cloud image (sets hostname, users, SSH keys, etc.).
- Without it, the VM might not boot properly or be difficult to access.

### **Install or Locate the Missing `QEMU_EFI.fd` File**

#### **1. Install the Missing Package**
If you haven't installed the **UEFI firmware package** for QEMU, install it:

##### **Ubuntu/Debian**
```sh
sudo apt update
sudo apt install -y qemu-efi-aarch64
```

##### **Fedora**
```sh
sudo dnf install -y edk2-aarch64
```

##### **Arch Linux**
```sh
sudo pacman -S edk2-aarch64
```

#### Find the Correct Path for `QEMU_EFI.fd`
After installation, locate the file:
```sh
find /usr -name "QEMU_EFI.fd" 2>/dev/null
```
Expected output (example paths):
```
/usr/share/AAVMF/AAVMF_CODE.fd
/usr/share/qemu-efi-aarch64/QEMU_EFI.fd
```

If `QEMU_EFI.fd` is not in `/usr/share/qemu-efi-aarch64/`, use the correct path in your QEMU command.

For example, if `AAVMF_CODE.fd` is found instead, change:
```sh
-bios /usr/share/qemu-efi-aarch64/QEMU_EFI.fd
```
to:
```sh
-bios /usr/share/AAVMF/AAVMF_CODE.fd
```

#### If the File Is Still Missing
If `QEMU_EFI.fd` is not found, manually download the required firmware:

```sh
mkdir -p ~/.local/share/qemu
wget https://releases.linaro.org/components/kernel/uefi-linaro/latest/release/qemu64/QEMU_EFI.fd -O ~/.local/share/qemu/QEMU_EFI.fd
```

Then modify your QEMU command to:
```sh
-bios ~/.local/share/qemu/QEMU_EFI.fd
```

### Run in QEMU ARM64 Environment

Here’s a detailed explanation of **QEMU options** for running an **ARM64 virtual machine**, covering both **VNC-based remote access** and **local display with OpenGL**.

- **Use VNC (`-vnc :0`)** if you need **remote access** to your VM.
- **Use OpenGL (`gl=on`)** if you need **better graphics performance** and **don’t need VNC**.
- You **cannot** use both **VNC and OpenGL together**—you must choose one.

#### Command with OpenGL
If you prefer **better graphics performance**, **remove VNC support** and enable OpenGL rendering.

```sh
qemu-system-aarch64 \
  -m 8192 \
  -cpu max \
  -M virt \
  -smp 6 \
  -bios /usr/share/qemu-efi-aarch64/QEMU_EFI.fd \
  -drive if=none,file=./base_images/jammy-server-cloudimg-arm64.img,format=raw,id=hd0 \
  -device virtio-blk-device,drive=hd0 \
  -netdev user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::5901-:5900 \
  -device virtio-net-device,netdev=net0 \
  -drive if=virtio,file=cloud-init.iso,format=raw \
  -device usb-ehci -device usb-kbd -device usb-mouse \
  -device virtio-gpu-pci,xres=1366,yres=768 \
  -nographic -display sdl,gl=on -vnc :0
```

| Option | Description |
|--------|-------------|
| `-display sdl,gl=on` | Enables **SDL display with OpenGL rendering** for better graphics. |

##### **How to Use**
- **A new SDL window will open** displaying the VM.
- You can **interact with the VM directly** in this window.

#### Command without OpenGL
If you want to **connect using VNC**, disable OpenGL (`gl=on`), as VNC is incompatible with OpenGL rendering.

```sh
qemu-system-aarch64 \
  -m 8192 \
  -cpu max \
  -M virt \
  -smp 6 \
  -bios /usr/share/qemu-efi-aarch64/QEMU_EFI.fd \
  -drive if=none,file=./base_images/jammy-server-cloudimg-arm64.img,format=raw,id=hd0 \
  -device virtio-blk-device,drive=hd0 \
  -netdev user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::5901-:5900 \
  -device virtio-net-device,netdev=net0 \
  -drive if=virtio,file=cloud-init.iso,format=raw \
  -device usb-ehci -device usb-kbd -device usb-mouse \
  -device virtio-gpu-pci,xres=1366,yres=768 \
  -nographic -display sdl -vnc :0
```

| Option | Description |
|--------|-------------|
| `-vnc :0` | Starts a **VNC server** on display `:0` (default port **5900**). |
| `-display sdl` | Uses **SDL** display (needed for VNC compatibility). |
| `-nographic` | Disables QEMU's default console output. |

##### **How to Use**
- **Connect via VNC** using:
  ```sh
  vncviewer localhost:0
  ```
  or
  ```sh
  vncviewer 127.0.0.1:5900
  ```

#### Explanation of QEMU Options:
These options are common for both setups (**with and without VNC**):

| Option | Description |
|--------|-------------|
| `qemu-system-aarch64` | Runs the QEMU emulator for ARM64 (aarch64) architecture. |
| `-m 8192` | Allocates **8 GB of RAM** to the VM. |
| `-cpu max` | Uses the **maximum available CPU model** for ARM64 emulation. |
| `-M virt` | Specifies a **generic virtual ARM machine** (recommended for QEMU). |
| `-smp 6` | Assigns **6 CPU cores** to the VM. |
| `-bios /usr/share/qemu-efi-aarch64/QEMU_EFI.fd` | Loads **UEFI firmware** for ARM64. |
| `-drive if=none,file=./base_images/jammy-server-cloudimg-arm64.img,format=raw,id=hd0` | Defines the **disk image** (`jammy-server-cloudimg-arm64.img`) in **raw format**. |
| `-device virtio-blk-device,drive=hd0` | Attaches the disk as a **VirtIO block device** for better performance. |
| `-netdev user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::5901-:5900` | Enables **networking** with **port forwarding** (SSH & VNC). |
| `-device virtio-net-device,netdev=net0` | Uses a **VirtIO network adapter** for better network performance. |
| `-drive if=virtio,file=cloud-init.iso,format=raw` | Loads **cloud-init.iso** to set up the VM (users, SSH keys, etc.). |
| `-device usb-ehci -device usb-kbd -device usb-mouse` | Adds **USB keyboard & mouse** support. |
| `-device virtio-gpu-pci,xres=1366,yres=768` | Configures **GPU emulation** with a resolution of **1366×768**. |
| `-nographic` | **Disables graphical output** (needed when using serial console only). |


## Verify That the Setup Worked

After running the QEMU command, verify the setup using the following checks:

### **Check if the VM is running**
If you used `-nographic`, the console should display Ubuntu boot logs. If the boot is successful, you should see a login prompt.

If using **VNC**, connect to the VM:
```sh
vncviewer localhost:0
```

### **Check the CPU architecture**
Once inside the VM, run:
```sh
uname -m
```
Expected output:
```
aarch64
```
This confirms that the system is running on **ARM architecture**.

### **Check available storage**
To confirm the disk resizing worked, check the available disk space:
```sh
df -h
```
Look for a line like:
```
/dev/vda1        32G  3G  29G  10% /
```
This confirms that the disk is correctly resized to 32GB.

### **Check networking**
To test if the VM has internet access, run:
```sh
ping -c 4 google.com
```
If successful, you’ll see replies confirming internet connectivity.

### **Check SSH access**
From your host machine, try connecting via SSH (if port forwarding is enabled):
```sh
ssh -p 2222 ubuntu@localhost
```
(Use the default **Ubuntu cloud image password** or an SSH key if configured.)

## Notes
- The image can be further customized based on your needs.
- If using a graphical environment, consider increasing RAM and CPU cores.
- Ensure you have **QEMU installed** before running the commands.
