# NVIDIA driver setup script for Fedora
# The Quadro P2000 of my Lenovo P52 laptop is as of Fedora 44 LEGACY
# So I need to install  the Driver Version 580xx for it to work properly. The akmod-nvidia package will automatically install the correct version of the driver for your GPU, and it will also handle kernel updates and rebuilds.
#!/bin/bash

sudo dnf update -y
sudo dnf install xorg-x11-drv-nvidia-580xx akmod-nvidia-580xx
sudo dnf install xorg-x11-drv-nvidia-580xx-cuda 
sudo dnf mark user akmod-nvidia

sudo dnf install -y vulkan

sudo dnf install -y xorg-x11-drv-nvidia-cuda-libs

sudo dnf install -y nvidia-vaapi-driver libva-utils vdpauinfo
