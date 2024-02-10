function Check-If-Is-Present {
    param (
        [string] $Command
    )
    return (Get-Command $Command -ErrorAction SilentlyContinue)
}

function Install-Scoop {
    if(Check-If-Is-Present scoop){
        echo "Scoop already present, not reinstalling"
        return
    }
    iex "& {$(irm get.scoop.sh)} -RunAsAdmin"
}

function Download-Apps {
    param (
        [string] $Command
    )

    if (Get-Command $Command -ErrorAction SilentlyContinue){
        echo "$Command already present, not installing."
        return
    }

    echo ("Installing " + $Command)
    scoop install $Command 
}

function Add_Hostnames {
    param (
        [string] $Ip,
        [string] $Hostname
    )

    $Path = "C:\Windows\System32\drivers\etc\hosts"
    if(Select-String -Path $Path -Pattern $Hostname -Quiet){
        echo "$Hostname already present in hosts file."
        return
    }

    echo "Adding $Hostname to hosts file"
    $Entry = "$Ip $Hostname"

    Add-Content -Path $Path -Value $Entry
}

Install-Scoop
scoop bucket add main
scoop bucket add extras
scoop bucket add java
scoop install openjdk11
scoop install maven
Download-Apps "kubectl"
Download-Apps "minikube" 
Download-Apps "helm"
Download-Apps "skaffold"
Download-Apps "gradle"
Download-Apps "gcloud"


gcloud auth login --update-adc
gcloud auth configure-docker us-east4-docker.pkg.dev
gcloud auth configure-docker us.gcr.io
gcloud config set project cwb03-dev-a1fe
gcloud auth application-default set-quota-project cwb03-dev-a1fe
gcloud artifacts locations list


minikube delete
minikube start --driver=hyperv --network minikube --memory 4096 --disk-size 50000mb
minikube addons enable ingress
minikube addons enable metrics-server
minikube addons enable dashboard
minikube addons enable gcp-auth --refresh

$MinikubeIp = minikube ip
Add_Hostnames -Ip $MinikubeIp -Hostname "dashboard.test" 
Add_Hostnames -Ip $MinikubeIp -Hostname "api.cwb03.test" 
Add_Hostnames -Ip $MinikubeIp -Hostname "db.cwb03.test" 
Add_Hostnames -Ip $MinikubeIp -Hostname "agency.cwb03.test" 
Add_Hostnames -Ip $MinikubeIp -Hostname "public.cwb03.test" 
Add_Hostnames -Ip $MinikubeIp -Hostname "employer.cwb03.test"

kubectl apply -f k8s/namespace-dsgov.yaml
kubectl apply -f k8s/dashboard-ingress.yaml
docker pull gcr.io/google.com/cloudsdktool/google-cloud-cli:emulators
minikube image load gcr.io/google.com/cloudsdktool/google-cloud-cli:emulators
kubectl apply -f k8s/pubsub-emulator.yaml

kubectl config set-context --current --namespace=cwb03

