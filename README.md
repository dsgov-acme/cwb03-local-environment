# cwb03-local-environment
This repo contains configuration and scripting to setup a local development environment using
minikube. This repo is maintained by the Nuvalence team to meet the needs of the team working
on the Digital Suite for Government solution accelerator. These scripts are provided as is, for
reference and no warranty of their correctness is offered.

**It is STRONGLY recommeded that users of this repository read and understand the install scripts
contained here before running them. These scripts make assumptions on starting configuration and 
desired end state. You may wish to instead use these scripts as documented setup steps that you can 
apply in part or with modification to meet your specific setup goals.**

Maintenance of these scripts as new operating system versions are released is driven by needs to setup systems operated by the Nuvalence team. Therefore there may be a time lag from when the newest version of an OS is made a available and when breaking changes are resolved.

## Targeted End State

The following tools will be installed:

- [minikube](https://minikube.sigs.k8s.io/docs/)
- [skaffold](https://skaffold.dev/docs/)
- [kubectl](https://kubernetes.io/docs/reference/kubectl/)
- [container-structure-test](https://github.com/GoogleContainerTools/container-structure-test)
- [helm](https://helm.sh/docs/)
- [qemu](https://wiki.qemu.org/Main_Page) and [socket_vmnet](https://github.com/lima-vm/socket_vmnet) _Mac only_

Minikube will be configured with the following features

- Dashboard and metrics server installed
- Nginx ingress installed
- Dashboard ingress setup to host locally at [dashboard.test](http://dashboard.test)
- `cwb03` namespace created
- The Google Cloud Pub/Sub Emulator running as a service

This script will also setup the following local DNS records to resolve to the cluster's external IP.

- **dashboard.test** This will resolve to the kubernetes dashboard
- **api.cwb03.test** API applications should setup ingress rules for this domain using path based routing to distinguidsh between APIs.
- **db.cwb03.test** Convinience domain for configuring SQL clients. Each database instance should be configured as a `NodePort` service and expose a unique port.

## Pre-requisites

### Gcloud

This installation requires gcloud to install dependencies. Follow these instructions to install gcloud on your machine: [Link](https://cloud.google.com/sdk/docs/install#installation_instructions)

Supported OS for `gcloud`:

- Windows
- Linux
- Debian / Ubuntu
- Red Hat / Fedora / CentOS
- MacOS (amd64/arm64)

### Homebrew (Mac)

The installation requires homebrew to install dependencies. If you don't have homebrew already installed, you can install it by running this command in your termninal:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Git SSH Access

If necessary the install script may clone git repos to install one or more tools from source. To do this, you will need to have Github access configured to use a local SSH key pair.

[Instructions can be found here](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)

## Getting Started

### Mac OS

After installing `gcloud` and `brew` from the above pre-requisites, run the following script:

```bash
./setup_mac.sh
```

This will install and configure a local minikube environment. This script is designed to be re-runable, so as changes are made it can be run again to modify an existing local build.

_Note: This script issues some commands via sudo, so you will be prompted to enter you password._

### Windows

The Windows script `setup_windows.ps1` is fully functional. Although it is possible to install `docker`
directly from `scoop`, we highly recommend the usage of Docker Desktop, whose installation wizards can be found [here](https://docs.docker.com/desktop/install/windows-install/). Please note that this software will require a license, which can be requested from Nuvalence, but is subject to approval. In case you want to install docker via scoop, uncomment said line from the Windows script. 

Once Docker Desktop is setup and running, you can execute the script. Start Windows Powershell, running it as Administrator and then run the following command `.\setup_windows.ps1`. Have in mind that this process is likely to take a while. 

It is important to note that at the moment of writing (April 4th, 2023). There have been several issues in the installation and/or usage of `container-structure-test`, which was originally intended to run on Linux anc MacOS but not on Windows. This led to commenting the tests that required it, but this will be reviewed in the future. At the moment, the installation needs to be made manually, by first downloading the latest Windows release [here](https://github.com/GoogleContainerTools/container-structure-test/releases). Make sure to rename the file to `container-structure-test` and it to the PATH in environment variables. 

### Linux
- Recommended Instructions for Ubuntu [here](setup_linux_ubuntu_instructions.md).
- Arch install script [here](setup_linux_arch.sh).

