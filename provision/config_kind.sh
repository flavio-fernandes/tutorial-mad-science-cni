[ $EUID -eq 0 ] && { echo 'must not be root' >&2; exit 1; }

set -o errexit
# set -o xtrace

export KIND_CLUSTER_NAME=$(kind get clusters | head -1)

kind_get_nodes() {
  kind get nodes --name "${KIND_CLUSTER_NAME}" | grep -v external-load-balancer
}

prepare_e2e_nodes() {
    KIND_NODES=$(kind_get_nodes)
    for i in $KIND_NODES; do echo "$i"; \
        # e2e expects nodes to have curl installed
        docker exec -i "$i" apt-get install -y curl || error_exit Unable to install curl on nodes
        # e2e needs firewalld disabled in order to allow overlay pods reach hostNetwork
        # docker exec -i "$i" systemctl disable --now firewalld || error_exit Unable to disable firewalld on nodes

        [ "${SKIP_KUBEVIRT_TESTS}" == "y" ] && continue
        # Kubevirt specific configuration
        docker exec -t $i bash -c "echo 'fs.inotify.max_user_watches=1048576' >> /etc/sysctl.conf"
        docker exec -t $i bash -c "echo 'fs.inotify.max_user_instances=512' >> /etc/sysctl.conf"
        docker exec -i $i bash -c "sysctl -p /etc/sysctl.conf"
    done
}

create_docker_l2_networks() {
    docker network create --driver=bridge kind-nodes-eth1-lan ||:
    docker network create --driver=bridge kind-nodes-eth2-lan ||:

    KIND_NODES=$(kind_get_nodes)
    for i in $KIND_NODES; do echo "$i"; \
        docker network connect kind-nodes-eth1-lan $i
        docker network connect kind-nodes-eth2-lan $i
    done
}

create_docker_l2_networks
prepare_e2e_nodes

