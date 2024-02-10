# Ubuntu Linux - Dependencies Install Recommended Instructions

# Install Docker

Ref: https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository

```bash
sudo mkdir -m 0755 -p /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```
```bash
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```
Follow instructions here to avoid running Docker as sudo:
https://docs.docker.com/engine/install/linux-postinstall/


# Install Kubectl
Ref: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-using-other-package-management 


```bash
sudo snap install kubectl --classic
```


# Install Helm
Ref: https://helm.sh/docs/intro/install/#from-snap

```bash
sudo snap install helm --classic
```

# Install Google Cloud CLI
Ref: https://cloud.google.com/sdk/docs/downloads-snap
```bash
sudo snap install google-cloud-cli --classic
```


# Install Minikube
Ref: https://minikube.sigs.k8s.io/docs/start/
```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

# Install Skaffold
Ref: https://skaffold.dev/docs/install/
```bash
curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64 && \
sudo install skaffold /usr/local/bin/
```

# Install Container Structure Test
Ref: https://github.com/GoogleContainerTools/container-structure-test
```bash
curl -LO https://storage.googleapis.com/container-structure-test/latest/container-structure-test-linux-amd64 
chmod +x container-structure-test-linux-amd64 
sudo mv container-structure-test-linux-amd64 /usr/local/bin/container-structure-test
```

# Install NVM (NodeJS for Web UI development)
Ref: https://github.com/nvm-sh/nvm#installing-and-updating
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
```
After installing NVM do:
```bash
nvm install 16 && nvm alias default 16 && nvm use 16
```
Then install yarn with: 
```bash
npm install --global yarn
```

___

After installing all dependencies run: [setup_linux_ubuntu_startcontext.sh](setup_linux_ubuntu_startcontext.sh)