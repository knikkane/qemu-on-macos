#!/bin/bash

# For running Linux VM on MacOS with libvirt + QEMU

ISO_IMAGE_NAME="your_iso_file_goes_here.iso"
IMAGE_NAME="vm_image.qcow2"


if [ ! -f "$IMAGE_NAME" ] && [ ! -f "$IMAGE_NAME.installed" ]; then
	#echo "creating qcow image"
	qemu-img create -f qcow2 "$IMAGE_NAME" 10G
else
	echo "image already existing"
fi



if [ ! -f "$IMAGE_NAME.installed" ]; then
	echo "Install ISO: $ISO_IMAGE_NAME"

	if [ ! -f "$ISO_IMAGE_NAME" ]; then
		echo "image not found: $ISO_IMAGE_NAME"
		exit 1
	fi

	# Emulate host with 4G of mem. Machine type emulated as Q35 chipset and enabling HW acceleration with Hypervisor Framework (HFV) on Mac OS
	# Format of the image file as qcow2, disabling disk caching. Virtual disk interface as VirtIO
	# VirtIO based network device, using PCI, and connect the network device to net0 backend
	# VirtIO based SCSIfor guest to access storage devices
	qemu-system-x86_64 -cpu host -m 4096 -machine type=q35,accel=hvf \
		-drive file="$IMAGE_NAME",format=qcow2,cache=none,if=virtio \
		-device virtio-net-pci,netdev=net0 -netdev type=user,id=net0 \
		-device virtio-scsi -device scsi-cd,drive=cd -drive if=none,id=cd,file="$ISO_IMAGE_NAME"
	mv "$IMAGE_NAME" "$IMAGE_NAME.installed"
fi

if [ -f "$IMAGE_NAME.installed" ]; then
	echo "launch installed image"
	qemu-system-x86_64 -cpu host -m 4096 -machine type=q35,accel=hvf \
		-drive file="$IMAGE_NAME.installed",format=qcow2,cache=none,if=virtio \
		-device virtio-net-pci,netdev=net0 -netdev type=user,id=net0 -device virtio-scsi

else
	echo "ISO installation not completed"
	exit 1
fi
