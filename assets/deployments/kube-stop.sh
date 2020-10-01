kubectl delete -f redismaster/.

kubectl delete -f sentinel1/.
kubectl delete -f sentinel2/.

kubectl delete -f redisslave1/.
kubectl delete -f redisslave2/.

kubectl delete -f converter/.
kubectl delete -f operations/.
kubectl delete -f supervisor/.
kubectl delete -f login/.
kubectl delete -f qa-technician/.
kubectl delete -f media/.
kubectl delete -f configurator/.

kubectl delete -f configurator-api/.
kubectl delete -f notification/.

kubectl delete -f iba/.
kubectl delete -f iba-bis/.

kubectl delete -f userinfo/.

kubectl delete -f search/.
kubectl delete -f traefik/.
kubectl delete -f metric/.

kubectl delete -f cron/.
kubectl delete -f file-storage/.
kubectl delete -f elk-cron/.
kubectl delete -f zipkin/.
kubectl delete -f logstash/.
