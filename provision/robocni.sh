#!/usr/bin/env bash

[ $EUID -eq 0 ] && { echo 'must not be root' >&2; exit 1; }

set -o errexit
# set -o xtrace

ln -svf /vagrant/provision/prompts.txt /tmp/prompts.txt
ln -svf /vagrant/provision/run_robocni.sh ~/run_robocni.sh

[ -n "${GET_ROBOCNI_BIN}" ] && {
    curl -L -o robocni https://github.com/dougbtv/robocniconfig/releases/download/v0.0.2/robocni
    curl -L -o looprobocni https://github.com/dougbtv/robocniconfig/releases/download/v0.0.2/looprobocni
    chmod +x robocni
    chmod +x looprobocni
    sudo mv looprobocni /usr/local/bin/
    sudo mv robocni /usr/local/bin/
    robocni -help

    exit 0
}

# If we make it here, build from source
source /home/vagrant/.bashrc.d/golang.sh
cd
git clone https://github.com/dougbtv/robocniconfig.git
cd robocniconfig
./hack/build-go.sh
sudo mv -v ./bin/* /usr/local/bin/
robocni -help
