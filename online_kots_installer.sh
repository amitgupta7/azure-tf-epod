#!/bin/bash
set -o nounset
set -o errexit
set -o pipefail
set -x
while getopts r:k:s:t:o:n: flag
do
    case "${flag}" in
        n) nameprefix=${OPTARG};;
        o) owner=${OPTARG};;
        r) region=${OPTARG};;
        k) apikey=${OPTARG};;
        s) apisecret=${OPTARG};;
        t) apitenant=${OPTARG};;        
    esac
done
# NAME                    CHART VERSION   APP VERSION 
# bitnami/elasticsearch   18.2.16         8.2.3    
# bitnami/postgresql-ha   11.9.13           14.5.0 
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

cat <<CONFIGVALS >values.yaml
apiVersion: kots.io/v1beta1
kind: ConfigValues
metadata:
  name: securiti-scanner
spec:
  values:
    redis_host:
        value: "$ec_host"
    redis_password:
        value: "$ec_password"
    use_redis_ssl:
        value: "0"
    region:
      value: $region
    install_dir:
       value: "/var/lib/"
    enable_external_postgres:
        value: "1"
    postgres_host:
        value: "$pg_host"
    postgres_password:
        value: "$pg_password"
    enable_external_es:
        value: "1"
    es_host:
        value: "$es_host"
CONFIGVALS
NAMESPACE="default"
kubectl kots install "securiti-scanner" --license-file "license.yaml" --config-values "values.yaml" -n $NAMESPACE --shared-password "securitiscanner" >install.log 2>&1 &
sleep 5m

CONFIG_CTRL_POD=$(kubectl get pods -A -o jsonpath='{.items[?(@.metadata.labels.app=="priv-appliance-config-controller")].metadata.name}')
if [ -z "$CONFIG_CTRL_POD"]
then
  kubectl get pods -A
  echo "Config controller pod not found, please check the deployment"
  exit 1
fi


curl -s -X 'POST' \
  'https://app.securiti.ai/core/v1/admin/appliance' \
  -H 'accept: application/json' \
  -H 'X-API-Secret:  '$apisecret \
  -H 'X-API-Key:  '$apikey \
  -H 'X-TIDENT:  '$apitenant \
  -H 'Content-Type: application/json' \
  -d '{
  "owner": "'$owner'",
  "co_owners": [],
  "install_mode" : "EDSS",
  "max_pods":20,
  "name": "'$nameprefix'-aks-'$(date +"%s")'",
  "desc": "",
  "send_notification": false
}' > sai_appliance.txt

SAI_LICENSE=$(cat sai_appliance.txt| jq -r '.data.license')
# get the pod name for the config controller pod, we'll need this for registration

# register with Securiti Cloud
kubectl exec -it "$CONFIG_CTRL_POD" -n $NAMESPACE -- securitictl register -l "$SAI_LICENSE"
echo "Registered to appliance id: $(cat sai_appliance.txt| jq -r '.data.id')"
