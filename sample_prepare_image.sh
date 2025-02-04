#!/bin/bash

# Usage information
usage() {
  echo "Usage: $0 path_to_public_key_file [--clean]"
  exit 1
}

# Check if at least one argument is provided
if [ "$#" -lt 1 ]; then
  usage
fi

# Initialize variables
PUB_KEY_FILE=""
CLEAN_FLAG=false

# Parse arguments
for arg in "$@"; do
  case $arg in
    --clean)
      CLEAN_FLAG=true
      shift
      ;;
    *)
      if [ -z "$PUB_KEY_FILE" ]; then
        PUB_KEY_FILE=$arg
      else
        usage
      fi
      shift
      ;;
  esac
done

# Check if the ssh public key file is provided and exists
if [ -z "$PUB_KEY_FILE" ] || [ ! -f "$PUB_KEY_FILE" ]; then
  echo "Error: Public key file not found!"
  usage
fi

PUB_KEY=$(cat "$PUB_KEY_FILE")

# Define the cloud-init folder and user-data file path
CLOUD_INIT_DIR="cloud-init"
USER_DATA_FILE="$CLOUD_INIT_DIR/user-data"
IMG_FILE='jammy-server-cloudimg-arm64.img'
IMG_URL="https://cloud-images.ubuntu.com/releases/22.04/release/$IMG_FILE"

# If the --clean flag is set, remove the ubuntu image file and re-fetch
if [ "$CLEAN_FLAG" = true ]; then
  if [ -f "$IMG_FILE" ]; then
    rm "$IMG_FILE"
    wget "$IMG_URL"
    qemu-img resize "$IMG_FILE" 32G  
    qemu-img info "$IMG_FILE"
    echo "Existing image file reset."
  fi
fi

# Remove the existing cloud-init folder if exist
if [ -d "$CLOUD_INIT_DIR" ]; then
  rm -rf "$CLOUD_INIT_DIR"
  echo "Existing $CLOUD_INIT_DIR directory removed."
fi

# Create the cloud-init folder
mkdir -p "$CLOUD_INIT_DIR"
echo "Directory $CLOUD_INIT_DIR created."

# Create the cloud-init user-data file with the provided public key
cat <<EOF > "$USER_DATA_FILE"
#cloud-config
users:
  - name: ubuntu
    ssh-authorized-keys:
      - $PUB_KEY
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    groups: sudo
    shell: /bin/bash
    lock_passwd: false
    passwd: ubuntu

chpasswd:
  list: |
    ubuntu:ubuntu
  expire: False

ssh_pwauth: True
EOF

touch meta-data && mv meta-data cloud-init
echo "Cloud-init user-data file created successfully at $USER_DATA_FILE."

# Generate iso init file and close

genisoimage -output cloud-init.iso -volid cidata -joliet -rock cloud-init/user-data cloud-init/meta-data
echo "Created the seed file cloud-init.iso for the qemu boot"

