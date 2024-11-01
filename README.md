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

## Step 2b: Install and configure KIND

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




## Personal notes (to be removed!)

```
ansible-playbook -i inventory/bonemt.virthost.inventory -e "@./inventory/kubecondemo.env" 02_setup_vm.yml
```

