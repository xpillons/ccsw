#!/bin/bash
# TODO : Only run this script on compute nodes, use jetpack to retrieve the node type.

os_release=$(cat /etc/os-release | grep "^ID\=" | cut -d'=' -f 2 | xargs)
enroot_version=3.4.1

# Install or update enroot if necessary
if [ "$(enroot version)" != "$enroot_version" ] ; then
    logger -s  Updating enroot to $enroot_version
    case $os_release in
        almalinux)
            yum remove -y enroot enroot+caps
            arch=$(uname -m)
            yum install -y https://github.com/NVIDIA/enroot/releases/download/v${enroot_version}/enroot-${enroot_version}-1.el8.${arch}.rpm
            yum install -y https://github.com/NVIDIA/enroot/releases/download/v${enroot_version}/enroot+caps-${enroot_version}-1.el8.${arch}.rpm
            ;;
        ubuntu)
            arch=$(dpkg --print-architecture)
            curl -fSsL -O https://github.com/NVIDIA/enroot/releases/download/v${enroot_version}/enroot_${enroot_version}-1_${arch}.deb
            curl -fSsL -O https://github.com/NVIDIA/enroot/releases/download/v${enroot_version}/enroot+caps_${enroot_version}-1_${arch}.deb
            apt install -y ./*.deb
            ;;
        *)
            logger -s "OS $os_release not tested"
            exit 0
        ;;
    esac
else
    logger -s  Enroot is already at version $enroot_version
fi

# enroot default scratch dir to /mnt/scratch
ENROOT_SCRATCH_DIR=/mnt/scratch
if [ -d /mnt/nvme ]; then
    # If /mnt/nvme exists, use it as the default scratch dir
    ENROOT_SCRATCH_DIR=/mnt/nvme
fi

logger -s "Creating enroot scratch directories in $ENROOT_SCRATCH_DIR"
mkdir -pv /run/enroot $ENROOT_SCRATCH_DIR/{enroot-cache,enroot-data,enroot-temp,enroot-runtime}
chmod -v 777 /run/enroot $ENROOT_SCRATCH_DIR/{enroot-cache,enroot-data,enroot-temp,enroot-runtime}

# Configure enroot
logger -s "Configure /etc/enroot/enroot.conf"
cat <<EOF > /etc/enroot/enroot.conf
ENROOT_RUNTIME_PATH /run/enroot/user-\$(id -u)
ENROOT_CACHE_PATH $ENROOT_SCRATCH_DIR/enroot-cache/user-\$(id -u)
ENROOT_DATA_PATH $ENROOT_SCRATCH_DIR/enroot-data/user-\$(id -u)
ENROOT_TEMP_PATH $ENROOT_SCRATCH_DIR/enroot-temp
ENROOT_SQUASH_OPTIONS -noI -noD -noF -noX -no-duplicates
ENROOT_MOUNT_HOME y
ENROOT_RESTRICT_DEV y
ENROOT_ROOTFS_WRITABLE y
MELLANOX_VISIBLE_DEVICES all
EOF

logger -s "Install extra hooks for PMIx on compute nodes"
cp -fv /usr/share/enroot/hooks.d/50-slurm-pmi.sh /usr/share/enroot/hooks.d/50-slurm-pytorch.sh /etc/enroot/hooks.d
