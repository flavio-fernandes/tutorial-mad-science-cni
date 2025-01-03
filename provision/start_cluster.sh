#!/usr/bin/env bash

[ $EUID -eq 0 ] && { echo 'must not be root' >&2; exit 1; }

set -o errexit
set -o xtrace

# # Create the kind cluster
# cat <<EOF | kind create cluster --config=-
# kind: Cluster
# apiVersion: kind.x-k8s.io/v1alpha4
# nodes:
# - role: control-plane
# - role: worker
# - role: worker
# EOF

kind create cluster --config=/vagrant/kind-config.yaml

/vagrant/provision/config_kind.sh

/vagrant/provision/start_cluster_cni_cilium.sh

# Wait for all nodes to be ready (10 minutes timeout)
timeout=600
interval=10
elapsed=0
while true; do
    ready_nodes=$(kubectl get nodes --no-headers | grep -c "Ready")
    total_nodes=$(kubectl get nodes --no-headers | wc -l)

    if [ "$ready_nodes" -eq "$total_nodes" ] && [ "$total_nodes" -ge 3 ]; then
        echo "All nodes are Ready."
        break
    fi

    if [ "$elapsed" -ge "$timeout" ]; then
        echo "Timeout waiting for nodes to become ready." >&2
        exit 1
    fi

    echo "Waiting for nodes to become ready... (${elapsed}s elapsed)"
    sleep $interval
    elapsed=$((elapsed + interval))
done

# # Set up koko with worker nodes' PIDs
# worker1_pid=$(docker inspect --format "{{ .State.Pid }}" kind-worker)
# worker2_pid=$(docker inspect --format "{{ .State.Pid }}" kind-worker2)
# sudo koko -p "$worker1_pid,eth1" -p "$worker2_pid,eth1"

# Multus
kubectl create -f https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/refs/heads/master/deployments/multus-daemonset-thick.yml
# kubectl -n kube-system wait --for=condition=ready -l name=multus pod --timeout=300s
/vagrant/provision/wait_for_pods.sh -n kube-system -l "name=multus"

# Reference CNI plugins
kubectl create -f https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/refs/heads/master/e2e/templates/cni-install.yml.j2
# kubectl -n kube-system wait --for=condition=ready -l name=cni-plugins pod --timeout=300s
/vagrant/provision/wait_for_pods.sh -n kube-system -l "name=cni-plugins"

# Whereabouts (aka where aboots in Canada :))
kubectl create -f https://raw.githubusercontent.com/k8snetworkplumbingwg/whereabouts/refs/heads/master/doc/crds/daemonset-install.yaml \
        -f https://raw.githubusercontent.com/k8snetworkplumbingwg/whereabouts/refs/heads/master/doc/crds/whereabouts.cni.cncf.io_overlappingrangeipreservations.yaml \
        -f https://raw.githubusercontent.com/k8snetworkplumbingwg/whereabouts/refs/heads/master/doc/crds/whereabouts.cni.cncf.io_ippools.yaml
# kubectl -n kube-system wait --for=condition=ready -l name=whereabouts pod --timeout=300s
/vagrant/provision/wait_for_pods.sh -n kube-system -l "name=whereabouts"

# Start a test pod using NAD
/vagrant/provision/start_test_pods.sh || { echo 'Test pod using CNI did not go well' >&2; exit 1; }

## Delete test pod using NAD
## /vagrant/provision/start_test_pods.sh clean
