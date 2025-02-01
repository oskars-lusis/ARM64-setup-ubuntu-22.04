#ARM (aarch64), virt based emulator on extended Ubuntu 22.04 (jammy) cloud image

## How to:
### This section explains steps taken
Note: because I am not very "common" with emulation, especially with: qemu-system-aarch64 environments, I will drop all I found.

#### Download base cloud image
Source of base image:   
https://cloud-images.ubuntu.com/jammy/20250112/  
In my case: I download them to folder ./base_images   
wget https://cloud-images.ubuntu.com/jammy/20250112/jammy-server-cloudimg-arm64.tar.gz ./base_images/jammy-server-cloudimg-arm64.tar.gz 

#### Prepare the image
untar (unarchive) .img file from archive 
```
tar -xvf ./jammy-server-cloudimg-arm64.tar.gz  
```
to extract .img file from archive we just downloaded.  
We want this: jammy-server-cloudimg-arm64.img  

##### Decide size of base image
After first test I noticed with LightDM and XFCE4 environment with (optional: gcc and g++ cmake make automake) installed it takes about 3-5 Gigabytes. But beying a bit paranoid I resized image to 32G. I would still leave it at at least 16G. But I use 32G. In case we want some KDE or anything :).  
Base Image size is about 2-3 Gigs.  

applies to .img file.  
qemu-img resize <myimage_.img> <mysize>   
In order to get info from image size: 
```
qemu-img info <myimage_.img>  
```

Sample: qemu-img resize ./base_images/jammy-server-cloudimg-arm64.img 16G
Sample: qemu-img info: ./base_images/jammy-server-cloudimg-arm64.img


###EFI or BIOS partition?
Here we should describe difference about BIOS or EFI? But it is better explained in https://wiki.archlinux.org/title/Arch_boot_process  
It all stubles accross what boot system we will emulate. There are some specifics, but I would choose basic BIOS for even lower level. However EFI is simpler for PC-s. And also more cosolidating with existing operating systems.  
I would go on specific case - is it depending not only on Machine parameters we want to emulate.  
In my case all I need is aarch64 ARM v8 emulator.  
In both cases:
- easy way:
    -- just use official image and build it - like sample in this repository
    -- not good way - use altlinux sample (many reasons)
    -- nvidia - official - yes! unless someone can provide emulated ARM64 qemu with some species on Intel or AMD :)

## Run in prepared qemu ARM64 environment:
with EFI image (I will short the story):  

qemu-system-aarch64 -m 8192 -cpu max -M virt -smp 6 -bios /usr/share/qemu-efi-aarch64/QEMU_EFI.fd -drive if=none,file=./jammy-server-cloudimg-arm64.img,id=hd0 -device v
irtio-blk-device,drive=hd0 -netdev user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::5901-:5900 -device virtio-net-device,netdev=net0 -drive if=virtio,file=cloud-init.iso,format=raw -device usb-ehci -device usb-kbd -device usb-mouse -devi
1ce virtio-gpu-pci,xres=1366,yres=768 -nographic -display sdl,gl=on -vnc :0   
What those paramteres mean and where are faults:   

