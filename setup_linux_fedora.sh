#!/usr//bin/env bash
set -eu

_check() {
        command -v "$1" > /dev/null
}
_hostname_exists() {
  HOSTNAME="$1"
  if grep -q "$HOSTNAME" /etc/hosts; then
    return 0
  else
    return 1
  fi
}
_addhost() {
  HOSTNAME=$1
  IP=$2
  HOSTS_LINE=$(printf '%s\t%s' "$IP" "$HOSTNAME")
  if _hostname_exists "$HOSTNAME"; then
    echo "$HOSTNAME Found in your /etc/hosts, Removing old entry ($(grep "$HOSTNAME" /etc/hosts)) now..."
    sudo sed -i".bak" "/$HOSTNAME/d" /etc/hosts
  fi

  echo "Adding $HOSTNAME to your /etc/hosts"
  sudo -- sh -c -e "echo '$HOSTS_LINE' >> /etc/hosts"

  if _hostname_exists "$HOSTNAME"; then
    echo "$HOSTNAME was added succesfully"
    grep "$HOSTNAME" /etc/hosts
  else
    echo "Failed to Add $HOSTNAME, See error above!"
  fi
}

# Ensure required software is installed

# Install google cloud sdk repo
cat > google-cloud-sdk.repo << EOF
[google-cloud-cli]
name=Google Cloud CLI
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el8-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
sudo mv google-cloud-sdk.repo /etc/yum.repos.d

# Install required packages
sudo yum -y install iptables helm google-cloud-sdk-skaffold.x86_64 google-cloud-sdk-minikube

if [[ ! $(which container-structure-test 2>/dev/null) ]]; then
  curl -LO https://storage.googleapis.com/container-structure-test/latest/container-structure-test-linux-amd64
  sudo install container-structure-test-linux-amd64 /usr/local/bin/container-structure-test
fi

# Authenticate to GCP
echo "Authenticating to GCP. This will Open a Browser for you to log in."
echo ""
gcloud config set project cwb03-dev-a1fe
gcloud auth login --update-adc
gcloud auth application-default set-quota-project cwb03-dev-a1fe

# start minikube and enable addons
minikube delete
minikube start --driver docker --network minikube --memory=8Gb --disk-size 50000mb
minikube addons enable ingress
minikube addons enable metrics-server
minikube addons enable dashboard
minikube addons enable gcp-auth

# update /etc/hosts
MINIKUBE_IP=$(minikube ip)
_addhost dashboard.test "$MINIKUBE_IP"
# shellcheck disable=SC2086
_addhost api.cwb03.test "$MINIKUBE_IP"
_addhost db.cwb03.test "$MINIKUBE_IP"
_addhost agency.cwb03.test "$MINIKUBE_IP"
_addhost public.cwb03.test "$MINIKUBE_IP"
_addhost employer.cwb03.test "$MINIKUBE_IP"
echo "Addes hosts to /etc/hosts. Review and correct if necessary:"
cat /etc/hosts

# Create namespaces
kubectl apply -f ./k8s/namespace-dsgov.yaml

# Setup dashboard ingress
until kubectl apply -f ./k8s/dashboard-ingress.yaml > /dev/null 2>&1
do
  printf "."
done
echo ""
echo "Ingress Applied"

# Setup Pub/Sub Emulator
docker pull gcr.io/google.com/cloudsdktool/google-cloud-cli:emulators
minikube image load gcr.io/google.com/cloudsdktool/google-cloud-cli:emulators
until kubectl apply -f ./k8s/pubsub-emulator.yaml > /dev/null 2>&1
do
  printf "."
done
echo ""
echo "Pub/Sub Emulator Applied"

# switch to cwb03 namespace
kubectl config set-context --current --namespace=cwb03
