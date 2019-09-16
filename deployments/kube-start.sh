kubectl create -f efs/.

sleep 10

kubectl create -f redis-slave/.
kubectl create -f redis-master/.
kubectl create -f sentinel-1/.
kubectl create -f sentinel-2/.
sleep 5

kubectl create -f configurator/.
kubectl create -f configurator-api/.
kubectl create -f converter/.
kubectl create -f operations/.
kubectl create -f search/.
kubectl create -f supervisor/.
kubectl create -f notification/.
kubectl create -f login/.

sleep 10
kubectl create -f userinfo/.
kubectl create -f iba/.
kubectl create -f nginx/.

sleep 120
kubectl create -f logstash/.
