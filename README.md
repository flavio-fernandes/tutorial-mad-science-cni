# Tutorial: A Mad Scientist's Guide to Automating CNI Configurations using Generative AI

A kubecon tutorial about automating CNI configuration using an LLM

From [this kubecon tutorial session](https://kccncna2024.sched.com/event/1i7kI?iframe=no):

> Ready to make Kubernetes networking a little easier and a lot more fun? Join Doug for an experiment in configuring CNI (Container Networking Interface) using generative AI. Despite being advised by data scientists to avoid automating machine configurations with generative AI, Doug went into the mad scientist's lab (err, basement) and tested how often a workflow could generate CNI configurations that would establish network connectivity between pods – and the success rate might surprise you. In this session, you'll automate CNI configurations using a large language model (LLM) and gain experience with a nifty tech stack: Ollama for running a containerized LLM, Kubernetes, CNI, and some script wizardry to create your own auto-configurator. Best yet? No prior CNI or AI/ML knowledge needed, and you'll learn along the way! Just in case, have contingency plans ready should any Skynet or Space Odyssey 2001 scenarios arise during the tutorial.

## Requirements!

I'll be using a Fedora 40 system, but, you can use anything that's capable of these requirements:

* A linux (or linux-like system) that's capable of installing KIND
* Git
* Docker

## Bonus requirements

* A machine with a GPU!

## Step 1: Install go and build robocniconfig

Let's install: https://github.com/dougbtv/robocniconfig

Let's get a golang environment going so we can build it...

The lastest install instructions are here: https://go.dev/doc/install

```
curl -L -o go1.23.2.linux-amd64.tar.gz https://go.dev/dl/go1.23.2.linux-amd64.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.23.2.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
go version
```

Now that we have that, we can clone the robocni

```
git clone https://github.com/dougbtv/robocniconfig.git 
cd robocniconfig/
```

And you can run the buildscript:

```
./hack/build-go.sh
```

And add the path of those binaries to our path...

```
export PATH=$PATH:$(pwd)/bin
```

And make sure you can run it:

```
robocni --help
```

## Step 2a: If need be, install docker

Installation steps for Fedora shown

```
sudo dnf -y install dnf-plugins-core
sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl start docker
sudo systemctl enable docker
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
docker ps
```

## Step 2b: Install KIND

So, KIND is Kubernetes-in-Docker! It's a simple way to run a cluster without needing large infra, great for test environments.

Install steps @ https://kind.sigs.k8s.io/docs/user/quick-start/#installing-from-release-binaries

Fedora install steps shown, download it:

```
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.24.0/kind-linux-amd64
```

Then, install it:

```
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
kind version
```

And install kubectl! If you don't have it.

```
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
kubectl version
```

## Step 3: Install required tools

We're going to use: https://github.com/redhat-nfvpe/koko

"The container connector" -- since our KIND nodes are emulated, they're just docker containers, we need a way to virtually connect them, which we will do with this tool to create virtual interfaces in the host containers for KIND.

And we'll install it with:

```
sudo curl -Lo /bin/koko https://github.com/redhat-nfvpe/koko/releases/download/v0.83/koko_0.83_linux_amd64
sudo chmod +x /bin/koko
```

## Step 4: Configure KIND and spin up a cluster

Create this yaml as `./kind-cluster-config.yml`

```
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
networking:
  disableDefaultCNI: true
  podSubnet: 192.168.0.0/16
```

```
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
  - role: worker
  - role: worker
EOF
```

Now we wait for the image to download, and the nodes to start...

And we can do:

```
kubectl get nodes
```

## Step 5: Base CNI configuration for your nodes

We are going to install Multus CNI: 

Multus enables us to attach multiple network interfaces to pods.

```
kubectl create -f https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/refs/heads/master/deployments/multus-daemonset-thick.yml
kubectl -n kube-system wait --for=condition=ready -l name=multus pod --timeout=300s
```

We need to install the reference CNI plugins, e.g. https://github.com/containernetworking/plugins

```
kubectl create -f https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/refs/heads/master/e2e/templates/cni-install.yml.j2
kubectl -n kube-system wait --for=condition=ready -l name=cni-plugins pod --timeout=300s
```

Now we can see what these commands did, our CNI configuration is modified:

```
docker exec -it kind-worker cat /etc/cni/net.d/00-multus.conf && echo
```

And... we have a bunch of CNI plugins loaded...

```
docker exec -it kind-worker ls -l /opt/cni/bin
```

### Optional: Spin up a test pod

First we create a network attachment to define an additional network to attach to...

```
cat <<EOF | kubectl create -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: macvlan-conf
spec:
  config: '{
      "cniVersion": "0.3.0",
      "type": "macvlan",
      "master": "eth0",
      "mode": "bridge",
      "ipam": {
        "type": "host-local",
        "subnet": "192.168.1.0/24",
        "rangeStart": "192.168.1.200",
        "rangeEnd": "192.168.1.216",
        "routes": [
          { "dst": "0.0.0.0/0" }
        ],
        "gateway": "192.168.1.1"
      }
    }'
EOF
```

And you can `kubectl get net-attach-def` to see it.

And then a sample pod...

```
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: samplepod
  annotations:
    k8s.v1.cni.cncf.io/networks: macvlan-conf
spec:
  containers:
  - name: samplepod
    command: ["/bin/ash", "-c", "trap : TERM INT; sleep infinity & wait"]
    image: alpine
EOF
```

And then we check if it has multiple interfaces:

```
kubectl exec -it samplepod -- ip a
```

## Step 6: Add an extra interface with koko!

First inspect the interfaces in your host containers...

```
docker exec -it kind-worker ip a
```

Then, we'll tell koko to create a veth between these two containers, in a fashion that looks like a linux interface...

```
worker1_pid=$(docker inspect --format "{{ .State.Pid }}" kind-worker)
worker2_pid=$(docker inspect --format "{{ .State.Pid }}" kind-worker2)
sudo koko -p "$worker1_pid,eth1" -p "$worker2_pid,eth1"
```

And we'll see we have an eth1, now.

```
docker exec -it kind-worker ip a
```

## Step 6: Choose your own adventure! Install an LLM (or use one I provide)



## Personal notes (to be removed!)

```
ansible-playbook -i inventory/bonemt.virthost.inventory -e "@./inventory/kubecondemo.env" 02_setup_vm.yml
```

