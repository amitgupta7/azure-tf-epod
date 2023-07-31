#!/bin/bash
while getopts k:s:t:o: flag
do
    case "${flag}" in
        k) key=${OPTARG};;
        s) secret=${OPTARG};;
        t) tenant=${OPTARG};;
        o) output=${OPTARG};;
    esac
done

curl $(curl https://app.securiti.ai/core/v1/admin/appliance/download_edss_installer -H 'accept: application/json' -H 'X-API-Secret:  '$secret -H 'X-API-Key:  '$key -H 'X-TIDENT:  '$tenant | jq -r '.edss_installer_url') -o $output