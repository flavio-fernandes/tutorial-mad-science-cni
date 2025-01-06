#!/usr/bin/env bash

[ $EUID -eq 0 ] && { echo 'must not be root' >&2; exit 1; }

set -o errexit
set -o xtrace

## # Ensure that kind network does not have ip6 enabled
## enabled_ipv6=$(docker network inspect kind -f '{{.EnableIPv6}}' 2>/dev/null)
## [ "${enabled_ipv6}" = "false" ] || {
##    docker network rm kind 2>/dev/null || :
##    docker network create kind -o "com.docker.network.bridge.enable_ip_masquerade"="true" -o "com.docker.network.driver.mtu"="1500"
## }
## [ "${enabled_ipv6}" = "false" ] || { 2&>1 echo the kind network is not what we expected ; exit 1; }

set -euxo pipefail

## # increate fs.inotify.max_user_watches
## sudo sysctl fs.inotify.max_user_watches=524288
## # increase fs.inotify.max_user_instances
## sudo sysctl fs.inotify.max_user_instances=512

cd
git clone --depth 1 https://github.com/ovn-kubernetes/ovn-kubernetes.git && \
cd ovn-kubernetes

## # build image
## cd ./dist/images
## cd ~/ovn-kubernetes/dist/images
## make ubuntu
## docker tag ovn-kube-ubuntu:latest ghcr.io/ovn-org/ovn-kubernetes/ovn-kube-ubuntu:master

# kind_cluster_name=kind
# cat <<EOT > /tmp/kind.yaml
# kind: Cluster
# apiVersion: kind.x-k8s.io/v1alpha4
# nodes:
# - role: control-plane
# - role: worker
# - role: worker
# - role: worker
# networking:
#   disableDefaultCNI: true
#   podSubnet: 10.244.0.0/16
#   serviceSubnet: 10.96.0.0/16
#   kubeProxyMode: none
# EOT
## kind delete clusters $kind_cluster_name ||:
## kind create cluster --name $kind_cluster_name --config /tmp/kind.yaml

docker pull ghcr.io/ovn-kubernetes/ovn-kubernetes/ovn-kube-ubuntu:master
kind load docker-image ghcr.io/ovn-kubernetes/ovn-kubernetes/ovn-kube-ubuntu:master

# cd ../../helm/ovn-kubernetes
cd ~/ovn-kubernetes/helm/ovn-kubernetes
helm install ovn-kubernetes . -f values-no-ic.yaml \
    --set k8sAPIServer="https://$(kubectl get pods -n kube-system -l component=kube-apiserver -o jsonpath='{.items[0].status.hostIP}'):6443" \
    --set global.image.repository=ghcr.io/ovn-kubernetes/ovn-kubernetes/ovn-kube-ubuntu --set global.image.tag=master

# kubectl -n ovn-kubernetes wait --for=condition=ready -l app=ovnkube-node pod --timeout=300s
/vagrant/provision/wait_for_pods.sh -n ovn-kubernetes -l "app=ovnkube-node"
