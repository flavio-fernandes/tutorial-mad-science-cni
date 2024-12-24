#!/usr/bin/env bash
#

[ $EUID -eq 0 ] && { echo 'must not be root' >&2; exit 1; }

set -o errexit
# set -o xtrace

[ -d /home/vagrant ] || { echo "PROBLEM, vagrant homedir is not present"; exit 1; }

mkdir -pv /home/vagrant/.ssh
touch /home/vagrant/.ssh/authorized_keys
## Add a public key, if wanted...
## echo '' >> /home/vagrant/.ssh/authorized_keys ; \
chmod 644 /home/vagrant/.ssh/authorized_keys ; \
chmod 755 /home/vagrant/.ssh

cd /vagrant/provision || cd "$(dirname $0)"

sudo ./pkgs.sh
sudo ./golang.sh
./docker.sh
sudo ./kind.sh
./robocni.sh
./kube.sh
./koko.sh
./local_ollama.sh

ln -svf /vagrant/provision/start_test_pods.sh ~/
ln -svf /vagrant/provision/start_cluster.sh ~/

echo ok
