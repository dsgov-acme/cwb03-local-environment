#! /bin/bash

# preparing sudo access
sudo -v
if [ $? -eq 0 ]; then
  echo "sudo confirmed."
else
  echo "You need to provide sudo access for routing configuration in /etc/hosts"
  exit
fi

# Setting up GCloud project
echo "Authenticating to GCP. This will Open a Browser for you to log in."
echo ""
gcloud auth login --update-adc
gcloud auth application-default set-quota-project cwb03-dev-a1fe
gcloud config set project cwb03-dev-a1fe


# routing helper functions
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


# starting a clean minikube
minikube delete
minikube start --network minikube --driver docker --cpus 2 --memory=8Gb --disk-size 50000mb
minikube addons enable ingress
minikube addons enable metrics-server
minikube addons enable dashboard
minikube addons enable gcp-auth --refresh


# update /etc/hosts
MINIKUBE_IP=$(minikube ip)
_addhost dashboard.test $MINIKUBE_IP
_addhost api.cwb03.test $MINIKUBE_IP
_addhost agency.cwb03.test $MINIKUBE_IP
_addhost public.cwb03.test $MINIKUBE_IP
_addhost employer.cwb03.test $MINIKUBE_IP
_addhost db.cwb03.test $MINIKUBE_IP
echo 
echo "Added hosts to /etc/hosts. Review and correct if necessary:"
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

# changing to cwb03 namespace
kubectl config set-context --current --namespace=cwb03
