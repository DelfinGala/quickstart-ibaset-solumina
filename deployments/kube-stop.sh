kubectl delete -f redis-slave/.
kubectl delete -f redis-master/.
kubectl delete -f sentinel-1/.
kubectl delete -f sentinel-2/.

sleep 1

kubectl delete -f configurator/.
kubectl delete -f configurator-api/.
kubectl delete -f converter/.
kubectl delete -f operations/.
kubectl delete -f search/.
kubectl delete -f supervisor/.
kubectl delete -f userinfo/.
kubectl delete -f notification/.
kubectl delete -f login/.

sleep 1
kubectl delete -f iba/.
kubectl delete -f nginx/.
kubectl delete -f logstash/.
kubectl delete -f efs/.
kubectl delete -f metric/.
