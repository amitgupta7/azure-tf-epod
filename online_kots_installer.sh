#!/bin/bash
while getopts h:p:l:r: flag
do
    case "${flag}" in
        h) host=${OPTARG};;
        p) password=${OPTARG};;
        r) region=${OPTARG};;
        
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

kubectl kots install "securiti-scanner" --license-file "license.yaml" --config-values "values.yaml" -n securiti --shared-password "securitiscanner"