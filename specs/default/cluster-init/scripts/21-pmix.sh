#!/bin/bash
set -e

# Install PMIx if not present in the image
PMIX_DIR=/opt/pmix/v4
PMIX_VERSION=4.2.9
# if the $PMIX_DIR directory is not present, then install PMIx
if [ ! -d $PMIX_DIR ]; then
    os_release=$(cat /etc/os-release | grep "^ID\=" | cut -d'=' -f 2 | xargs)
    logger -s "Installing PMIx dependencies for $os_release"
    case $os_release in
        rhel|almalinux)
            dnf config-manager --set-enabled powertools
            dnf -y install autoconf flex libevent-devel git hwloc-devel
            ;;
        ubuntu|debian)
            apt-get update
            #apt-get install -y git libevent-dev libhwloc-dev autoconf flex make gcc libxml2
            apt-get install -y libevent-dev libhwloc-dev
            ;;
    esac
    # Build PMIx
    logger -s "Build PMIx"
    cd /mnt/scratch
	rm -rf pmix-${PMIX_VERSION}
    wget -q https://github.com/openpmix/openpmix/releases/download/v$PMIX_VERSION/pmix-$PMIX_VERSION.tar.gz
    tar -xzf pmix-$PMIX_VERSION.tar.gz
    cd pmix-$PMIX_VERSION

    # rm -rf openpmix
    # git clone --recursive https://github.com/openpmix/openpmix.git
    # cd openpmix
    # git checkout v$PMIX_VERSION
    ./autogen.pl
    ./configure --prefix=$PMIX_DIR
    make -j install
	cd ..
	rm -rf pmix-${PMIX_VERSION}
    rm pmix-$PMIX_VERSION.tar.gz
    logger -s "PMIx Sucessfully Installed"

    ln -s $PMIX_DIR/lib/libpmix.so /usr/lib/libpmix.so
    systemctl restart slurmd
    systemctl status slurmd
fi

# Exit if Enroot is not in the image
# [ -d /etc/enroot ] || exit 0

# # Install extra hooks for PMIx
# logger -s "Install extra hooks for PMIx"
# cp -fv /usr/share/enroot/hooks.d/50-slurm-pmi.sh /usr/share/enroot/hooks.d/50-slurm-pytorch.sh /etc/enroot/hooks.d

# [ -d /etc/sysconfig ] || mkdir -pv /etc/sysconfig
# # Add variables for PMIx
# logger -s "Add Slurm variables for PMIx"
# sed -i '/EnvironmentFile/a Environment=PMIX_MCA_ptl=^usock PMIX_MCA_psec=none PMIX_SYSTEM_TMPDIR=/var/empty PMIX_MCA_gds=hash HWLOC_COMPONENTS=-opencl' /usr/lib/systemd/system/slurmd.service
# systemctl daemon-reload
