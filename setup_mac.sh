#!/bin/sh

function addhost() {
    HOSTNAME=$1
	IP=$2
    HOSTS_LINE="$IP\t$HOSTNAME"
    if [ -n "$(grep $HOSTNAME /etc/hosts)" ]; then
            echo "$HOSTNAME Found in your /etc/hosts, Removing old entry ($(grep $HOSTNAME /etc/hosts)) now...";
        	sudo sed -i".bak" "/$HOSTNAME/d" /etc/hosts
	fi

	echo "Adding $HOSTNAME to your /etc/hosts";
	sudo -- sh -c -e "echo '$HOSTS_LINE' >> /etc/hosts";

	if [ -n "$(grep $HOSTNAME /etc/hosts)" ]
		then
			echo "$HOSTNAME was added succesfully \n $(grep $HOSTNAME /etc/hosts)";
		else
			echo "Failed to Add $HOSTNAME, See error above!";
	fi
}

# Ensure Homebrew installed and up to date.
which brew > /dev/null 2>&1
if [ $? -eq 1 ]; then
	#Cheat, if we don't have brew, install xcode command line utils too
	xcode-select --install

	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
	brew update
fi

# Ensure required software is installed
brew install qemu
brew install minikube
brew install kubectl
brew install container-structure-test
brew install docker
brew install --cask adoptopenjdk

# Frontend dependencies
brew install node
brew install yarn
brew install nvm

# Setup NVM
NVMDIR=~/.nvm
if [ -d "$NVMDIR" ]; then
  echo "$NVMDIR exists."
else 
  mkdir $NVMDIR

  ZSHRCFILE=~/.zshrc
  if [ -f "$ZSHRCFILE" ]; then
    echo "export NVM_DIR=~/.nvm" >> $ZSHRCFILE
    echo "source $(brew --prefix nvm)/nvm.sh" >> $ZSHRCFILE
    source ~/.zshrc
    nvm install 16 && nvm alias default 16 && nvm use 16
  fi

  PROFILEFILE=~/.profile
  if [ -f "$PROFILEFILE" ]; then
    echo "export NVM_DIR=~/.nvm" >> $PROFILEFILE
    echo "source $(brew --prefix nvm)/nvm.sh" >> $PROFILEFILE
    source ~/.profile
    nvm install 16 && nvm alias default 16 && nvm use 16
  fi

  echo "NVM setup setup successfully"
fi

# Authenticate to GCP
echo "Authenticating to GCP. This will Open a Browser for you to log in."
echo ""
gcloud config set project cwb03-dev-a1fe
gcloud auth login --update-adc
gcloud auth application-default set-quota-project cwb03-dev-a1fe
gcloud components update # This may prompt a Y/N prompt if you need to update the components
gcloud components install skaffold # We expect this to be v2.3.0; 2.4.0 has a bug as of 05/04/2023
skaffold version

ls /opt/socket_vmnet > /dev/null 2>&1
if [ $? -eq 1 ]; then
	pushd /tmp
	git clone git@github.com:lima-vm/socket_vmnet.git
	pushd /tmp/socket_vmnet
	sudo make install
	popd
	popd
fi

which helm > /dev/null 2>&1
if [ $? -eq 1 ]; then
	mkdir -p /usr/local/bin
	pushd /tmp
	curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
	chmod 700 get_helm.sh
	./get_helm.sh
	popd
fi

# start minikube and enable addons
minikube delete
minikube start --vm=true --driver qemu2 --network socket_vmnet --memory=8Gb --disk-size 50000mb
minikube addons enable ingress
minikube addons enable metrics-server
minikube addons enable dashboard
minikube addons enable gcp-auth

# update /etc/hosts
MINIKUBE_IP=$(minikube ip)
addhost dashboard.test $MINIKUBE_IP
addhost api.cwb03.test $MINIKUBE_IP
addhost agency.cwb03.test $MINIKUBE_IP
addhost public.cwb03.test $MINIKUBE_IP
addhost employer.cwb03.test $MINIKUBE_IP
addhost db.cwb03.test $MINIKUBE_IP
echo 
echo "Added hosts to /etc/hosts. Review and correct if necessary:"
cat /etc/hosts
sudo killall -HUP mDNSResponder

# Create namespaces
kubectl apply -f ./k8s/namespace-dsgov.yaml

# Setup dashboard ingress
until kubectl apply -f ./k8s/dashboard-ingress.yaml > /dev/null 2>&1
do
  echo -n "."
done
echo ""
echo "Ingress Applied"

# Setup Pub/Sub Emulator
docker pull gcr.io/google.com/cloudsdktool/google-cloud-cli:emulators
minikube image load gcr.io/google.com/cloudsdktool/google-cloud-cli:emulators
until kubectl apply -f ./k8s/pubsub-emulator.yaml > /dev/null 2>&1
do
  echo -n "."
done
echo ""
echo "Pub/Sub Emulator Applied"

# switch to cwb03 namespace
kubectl config set-context --current --namespace=cwb03
