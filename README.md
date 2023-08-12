# azure-tf-epod
This repo provides an example to create the necessary azure infrastructure for deployment of epods. This is presently a wip and not complete. Provided as-is, only for demo/training purposes.

## Prerequisites
The script needs terraform and azure cli to run. These can be installed using a packet manager like apt (linux) or using homebrew (mac). We will create a jumpbox machine on azure first to download the installer and perform the install. We will do this because the jumpbox machine on the azure cloud will have more stable internet, and would be less dependent on local network. 

NOTE: These are mac instructions (homebrew --> azure cli --> terraform --> jumpbox-machine, aks, redis, kots based install). Provided as-is. You will also need a replicated license from securiti.ai to use the OTA installer, please reachout to support or account rep for the same. Rename the kots license as licese.yaml, and place it in the cloned code folder. 
```shell
#install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
## install terraform
brew install terraform
## install az cli
brew install azure-cli
$> az login
$> git clone https://github.com/amitgupta7/azure-tf-epod.git
$> source tfAlias
$> tf init
$> tfaa
## clean-up
$> tfda
```


Create a `terraform.tfvars` file to proivide azure subscription id, existing resource group And/Or other inputs to the script. See `var.tf` file for more details. e.g.
```hcl
az_subscription_id = "your-azure-subscription-id"
az_resource_group  = "existing-resource-group-in-azure"
az_name_prefix     = "unique-prefix-to-use-in-resource-names"
X_API_Secret       = "sai api secret"
X_API_Key          = "sai api key"
X_TIDENT           = "sai api tenant"
azpwd              = "some secure password atleast 16 char 3-outof-4 of alpha-num-caps-special"
```
##  Outputs
Use the output to ssh into the jumpbox. 
```shell
Outputs:

ssh_credentials = <<EOT
ssh -L 8800:localhost:8800 azuser@azure-tf-epod1-amit-jumpbox.westus2.cloudapp.azure.com 
with password: <your_super_secure_password>
EOT
```
Also note down the appliance-id that the pod has been registered to on the SAI portal `null_resource.post_provisioning (remote-exec): Registered to appliance id: 4b2ed592-1aaa-45b7-ade2-5ff91bc36fbf`

## Kubernetes version
The securiti appliance is sensitive to the kubernetes version on AKS. In case you have errors (either aks supported k8s version in your region, or supported k8s version for securiti appliance), the k8s version can be changed with `kubernetes_version` variable.
```shell
tfa -var=kubernetes_version=1.25.6 -var=region=eastus2
```

## Stateful sets
It is cheaper to deploy the necessary redis, postgresql and elastic search for the scanning appliance on the AKS cluster itself. The script does this by using bitnami helm charts, and generating and setting paswords during runtime. 
```shell
# NAME                    CHART VERSION   APP VERSION 
# bitnami/elasticsearch   18.2.16         8.2.3    
# bitnami/postgresql-ha   11.9.13         14.5.0 
# bitnami/redis           16.13.2         6.2.7 

DEPLOYMENT_PREFIX=securiti-epod
REDIS_DEPLOYMENT_NAME=$DEPLOYMENT_PREFIX-ec
POSTGRES_DEPLOYMENT_NAME=$DEPLOYMENT_PREFIX-pg
ELASTICSEARCH_DEPLOYMENT_NAME=$DEPLOYMENT_PREFIX-es
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update  
helm install $REDIS_DEPLOYMENT_NAME bitnami/redis --version "16.13.2"
helm install $POSTGRES_DEPLOYMENT_NAME bitnami/postgresql --version "11.9.13"
helm install $ELASTICSEARCH_DEPLOYMENT_NAME bitnami/elasticsearch --version "18.2.16"
ec_host=$REDIS_DEPLOYMENT_NAME-redis-master.default.svc.cluster.local
ec_password=$(kubectl get secret --namespace default $REDIS_DEPLOYMENT_NAME-redis -o jsonpath="{.data.redis-password}" | base64 -d)
pg_password=$(kubectl get secret --namespace default $POSTGRES_DEPLOYMENT_NAME-postgresql -o jsonpath="{.data.postgres-password}" | base64 -d)
pg_host=$POSTGRES_DEPLOYMENT_NAME-postgresql.default.svc.cluster.local
es_host=$ELASTICSEARCH_DEPLOYMENT_NAME-elasticsearch.default.svc.cluster.local
```

##  Connecting to AKS
Kubectl should be connected to aks and pod installed (done using file provisioner). SSH into the jumpbox, and run the following commands.

```shell
$> kubectl get pods -A -w
NAMESPACE     NAME                                                    READY   STATUS      RESTARTS   AGE
kube-system   azure-ip-masq-agent-2stl6                               1/1     Running     0          23m
kube-system   azure-ip-masq-agent-ntcfh                               1/1     Running     0          22m
kube-system   cloud-node-manager-dvj4p                                1/1     Running     0          22m
kube-system   cloud-node-manager-wxpj8                                1/1     Running     0          23m
kube-system   coredns-785fcf7bdd-l2sss                                1/1     Running     0          22m
kube-system   coredns-785fcf7bdd-n76xx                                1/1     Running     0          23m
kube-system   coredns-autoscaler-65bb858f95-hxv76                     1/1     Running     0          23m
kube-system   csi-azuredisk-node-p6kmg                                3/3     Running     0          23m
kube-system   csi-azuredisk-node-zl676                                3/3     Running     0          22m
kube-system   csi-azurefile-node-4ddqw                                3/3     Running     0          23m
kube-system   csi-azurefile-node-fkqhx                                3/3     Running     0          22m
kube-system   konnectivity-agent-6fd4b4b74f-j25bc                     1/1     Running     0          22m
kube-system   konnectivity-agent-6fd4b4b74f-nmbdv                     1/1     Running     0          23m
kube-system   kube-proxy-6vqp9                                        1/1     Running     0          23m
kube-system   kube-proxy-rq9b5                                        1/1     Running     0          22m
kube-system   metrics-server-7757d565cf-kcr4x                         2/2     Running     0          22m
kube-system   metrics-server-7757d565cf-wwgt6                         2/2     Running     0          22m
securiti      cronjobs-dlq-processor-28181640-dsx9g                   0/1     Completed   0          3m47s
securiti      kotsadm-64646b6845-pgj9k                                1/1     Running     0          15m
securiti      kotsadm-minio-0                                         1/1     Running     0          15m
securiti      kotsadm-rqlite-0                                        1/1     Running     0          15m
securiti      kube-metrics-adapter-7d67b564cc-2pp9t                   1/1     Running     0          13m
securiti      metrics-server-7c9dc94794-q4j6n                         0/1     Running     0          12m
securiti      priv-appliance-cargo-message-service-6c7b5b689f-9tzln   1/1     Running     0          12m
securiti      priv-appliance-config-controller-7cf9bc98b6-q7qbp       1/1     Running     0          12m
securiti      priv-appliance-download-worker-6cff74887d-t8m7p         3/3     Running     0          12m
securiti      priv-appliance-monitor-status-c97n8                     1/1     Running     0          13m
securiti      priv-appliance-monitor-status-ljcf4                     1/1     Running     0          13m
securiti      priv-appliance-qos-orchestrator-858d47b6c-snm27         1/1     Running     0          12m
securiti      priv-appliance-redis-metrics-54b69cb66b-58l98           1/1     Running     0          12m
securiti      priv-appliance-redis-reaper-8648df586b-f8c5j            1/1     Running     0          12m
securiti      priv-appliance-worker-797c96dbc8-gprxs                  1/1     Running     0          12m
securiti      prometheus-pushgateway-86dfd879d6-dhtd2                 1/1     Running     0          12m
securiti      prometheus-server-5cdf96466d-ks52g                      2/2     Running     0          12m
```
##  Output and Cleanup

The script will register the pod to SAI and print the `appliance id` during creation. Use `delete_appliance.sh` script to delete the pod before de-provisioning. 

```shell
$> tfaa
....
null_resource.post_provisioning (remote-exec): Registered to appliance id: 4b2ed592-1aaa-45b7-ade2-5ff91bc36fbf
null_resource.post_provisioning: Creation complete after 20m27s [id=6196899608814120100]

Apply complete! Resources: 11 added, 0 changed, 0 destroyed.

Outputs:

ssh_credentials = <<EOT
ssh -L 8800:localhost:8800 azuser@azure-tf-epod1-amit-jumpbox.westus2.cloudapp.azure.com 
with password: <your_super_secure_password>
EOT
$> cat <<EOF > .env
X_API_Secret="sai api secret"
X_API_Key="sai api key"
X_TIDENT="sai api tenant"
EOF
$> sh delete_appliance.sh 4b2ed592-1aaa-45b7-ade2-5ff91bc36fbf
{
  "status": 0,
  "message": "Deletion successful"
}
$> tfda
```
