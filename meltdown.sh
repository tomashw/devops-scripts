#!/bin/bash

# https://pendo-io.atlassian.net/projects/OPS/queues/issue/OPS-702
# https://aws.amazon.com/security/security-bulletins/AWS-2018-013/
# https://wiki.ubuntu.com/SecurityTeam/KnowledgeBase/SpectreAndMeltdown

if [[ ${REGION} == *"us-east-1"* ]] && [[ ${EB_ENV_NAME} != *"staging"* ]]; then

# ubuntu 16.04 LTS kernel upgrade steps
echo "Current kernel is: "
uname -msr

echo "Distributor details: "
lsb_release -a

echo "Adding kernel repository: "
sudo add-apt-repository ppa:kernel-ppa/ppa -y

echo "Creating the updates list: "
sudo apt-get update -y

echo "Install available updates for the Ubuntu release you already have installed: "
sudo apt-get dist-upgrade -y

echo "Performing actual upgrade of an entire system: "
sudo apt-get upgrade -y

echo "Make sure latest versions are installed for below packages: "
# We do this because the upgrade didn't actually bring the latest build
# Instead it brought two patches back, but those did not contain the meltdown fix
# So we install the correct version one by one
# Check this page for any future updates for the libs ->
# https://wiki.ubuntu.com/SecurityTeam/KnowledgeBase/SpectreAndMeltdown

if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
    # Older Debian/Ubuntu/etc.
    OS=Debian
    VER=$(cat /etc/debian_version)
elif [ -f /etc/SuSe-release ]; then
    # Older SuSE/etc.
    #
elif [ -f /etc/redhat-release ]; then
    # Older Red Hat, CentOS, etc.
    echo "Old RedHat"
else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    VER=$(uname -r)
fi

echo "Using OS = $OS, version = $VER"
echo "Installing libraries for version $VER..."

if [ "$VER" == "14.04" ]; then
  # Ubuntu 14.04.X
  sudo apt-get install linux-image-3.13.0-139-lowlatency
  sudo apt-get install linux-image-3.13.0-139-generic
elif [ "$VER" == "16.04" ]; then
  # Ubuntu 16.04.X
  sudo apt-get install linux-image-4.4.0-9021-euclid
  sudo apt-get install linux-image-4.4.0-108-lowlatency
  sudo apt-get install linux-image-4.4.0-1047-aws
  sudo apt-get install linux-image-4.4.0-1015-kvm
  sudo apt-get install linux-image-4.4.0-108-generic
else
    echo "I don't know what to do with version: $VER"
fi

echo "Kernel version after upgrade is:"
uname -msr

echo "Rebooting the system: "
# sudo reboot
