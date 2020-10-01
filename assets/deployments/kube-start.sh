kubectl create -f efs/.
# kubectl create -f nginx/.

#!/bin/bash

mkdir -p /exec-ui/import-files && chmod 777 /exec-ui/import-files
mkdir -p /exec-ui/export-files && chmod 777 /exec-ui/export-files

kubectl create -f redismaster/.
sleep 10
kubectl create -f sentinel1/.
kubectl create -f sentinel2/.
sleep 10
kubectl create -f redisslave1/.
kubectl create -f redisslave2/.

sleep 10
kubectl create -f converter/.

kubectl create -f file-storage/.
sleep 10
kubectl create -f operations/.
kubectl create -f supervisor/.
kubectl create -f login/.
kubectl create -f qa-technician/.
kubectl create -f media/.
kubectl create -f configurator/.
sleep 10
kubectl create -f configurator-api/.
kubectl create -f notification/.
sleep 20

kubectl create -f iba/.

kubectl create -f iba-bis/.

kubectl create -f cron/.
kubectl create -f elk-cron/.

sleep 20
kubectl create -f userinfo/.
sleep 2
kubectl create -f search/.
kubectl create -f traefik/.
kubectl create -f metric/.
kubectl create -f zipkin/.

sleep 120
kubectl create -f logstash/.