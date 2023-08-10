#!/bin/bash
while getopts h:p:r:k:s:t: flag
do
    case "${flag}" in
        h) host=${OPTARG};;
        p) password=${OPTARG};;
        r) region=${OPTARG};;
        k) apikey=${OPTARG};;
        s) apisecret=${OPTARG};;
        t) apitenant=${OPTARG};;        
    esac
done

cat <<CONFIGVALS >values.yaml
apiVersion: kots.io/v1beta1
kind: ConfigValues
metadata:
  name: securiti-scanner
spec:
  values:
    redis_host:
        value: "$host"
    redis_password:
        value: "$password"
    use_redis_ssl:
        value: "0"
    region:
      value: $region
    deploy_prometheus:
      value: "1"
    deploy_metrics:
      value: "1"
    install_dir:
       value: "/var/lib/"
CONFIGVALS

kubectl kots install "securiti-scanner" --license-file "license.yaml" --config-values "values.yaml" -n securiti --shared-password "securitiscanner" >install.log 2>&1 &
sleep 20m

CONFIG_CTRL_POD=$(kubectl get pods -l app=priv-appliance-config-controller -n "securiti" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')
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
  "owner": "amit.gupta@securiti.ai",
  "co_owners": [],
  "name": "localtest-'$(echo $RANDOM %10000+1 |bc)'",
  "desc": "",
  "send_notification": false
}' > sai_appliance.txt

SAI_LICENSE=$(cat sai_appliance.txt| jq -r '.data.license')
# get the pod name for the config controller pod, we'll need this for registration

# register with Securiti Cloud
kubectl exec -it "$CONFIG_CTRL_POD" -n "securiti" -- securitictl register -l "$SAI_LICENSE"

echo "Registered to appliance id: $(cat sai_appliance.txt| jq -r '.data.id')"
