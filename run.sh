#!/usr/bin/env bash

minikube start \
    --kubernetes-version=v1.23.0 \
    --container-runtime=containerd \
    --driver=hyperkit

sleep 60

set +x
echo "################################################################################"
echo "### get nodes + pods"
echo "################################################################################"
set -x

kubectl get nodes

kubectl get pods --all-namespaces

sleep 20

set +x
echo "################################################################################"
echo "### describe etcd pod"
echo "################################################################################"
set -x

kubectl describe pod etcd-minikube --namespace kube-system

sleep 20

set +x
echo "################################################################################"
echo "### install etcdctl"
echo "################################################################################"
set -x

wget -c https://github.com/etcd-io/etcd/releases/download/v3.5.1/etcd-v3.5.1-linux-amd64.tar.gz -O - | \
    tar -xz --strip-components=1 - etcd-v3.5.1-linux-amd64/etcdctl

minikube cp etcdctl minikube:/home/docker/etcdctl

minikube ssh "sudo chown docker:docker /home/docker/etcdctl ; sudo chmod u+x /home/docker/etcdctl"

sleep 20

set +x
echo "################################################################################"
echo "### get all keys"
echo "################################################################################"
set -x

minikube ssh "\
ETCDCTL_API=3 sudo ./etcdctl \
    --endpoints=https://127.0.0.1:2379 \
    --cacert /var/lib/minikube/certs/etcd/ca.crt \
    --cert   /var/lib/minikube/certs/etcd/server.crt \
    --key    /var/lib/minikube/certs/etcd/server.key \
get / — prefix — keys-only | \
head -20\
"

sleep 20

set +x
echo "################################################################################"
echo "### output key-value store"
echo "################################################################################"
set -x

minikube ssh "\
ETCDCTL_API=3 sudo ./etcdctl \
    --endpoints=https://127.0.0.1:2379 \
    --cacert     /var/lib/minikube/certs/etcd/ca.crt \
    --cert      /var/lib/minikube/certs/etcd/server.crt \
    --key       /var/lib/minikube/certs/etcd/server.key \
    --write-out json \
get / — prefix — keys-only | \
jq . | \
head -20 | \
cut -c -80\
"

sleep 20

set +x
echo "################################################################################"
echo "### output one key"
echo "################################################################################"
set -x

minikube ssh "\
ETCDCTL_API=3 sudo ./etcdctl \
    --endpoints=https://127.0.0.1:2379 \
    --cacert     /var/lib/minikube/certs/etcd/ca.crt \
    --cert      /var/lib/minikube/certs/etcd/server.crt \
    --key       /var/lib/minikube/certs/etcd/server.key \
    --write-out json \
get /registry/apiregistration.k8s.io/apiservices/v1 | \
jq . | \
head -20 | \
cut -c -80\
"

sleep 20

set +x
echo "################################################################################"
echo "### decode key + value"
echo "################################################################################"
set -x

minikube ssh "\
ETCDCTL_API=3 sudo ./etcdctl \
    --endpoints=https://127.0.0.1:2379 \
    --cacert     /var/lib/minikube/certs/etcd/ca.crt \
    --cert      /var/lib/minikube/certs/etcd/server.crt \
    --key       /var/lib/minikube/certs/etcd/server.key \
    --write-out json \
get / — prefix — keys-only | \
jq .kvs[1].key
"

minikube ssh "\
ETCDCTL_API=3 sudo ./etcdctl \
    --endpoints=https://127.0.0.1:2379 \
    --cacert     /var/lib/minikube/certs/etcd/ca.crt \
    --cert      /var/lib/minikube/certs/etcd/server.crt \
    --key       /var/lib/minikube/certs/etcd/server.key \
    --write-out json \
get / — prefix — keys-only | \
jq .kvs[1].key | \
sed 's/\"//g' | \
base64 --decode
"

minikube ssh "\
ETCDCTL_API=3 sudo ./etcdctl \
    --endpoints=https://127.0.0.1:2379 \
    --cacert     /var/lib/minikube/certs/etcd/ca.crt \
    --cert      /var/lib/minikube/certs/etcd/server.crt \
    --key       /var/lib/minikube/certs/etcd/server.key \
    --write-out json \
get / — prefix — keys-only | \
jq .kvs[1].value
"

minikube ssh "\
ETCDCTL_API=3 sudo ./etcdctl \
    --endpoints=https://127.0.0.1:2379 \
    --cacert     /var/lib/minikube/certs/etcd/ca.crt \
    --cert      /var/lib/minikube/certs/etcd/server.crt \
    --key       /var/lib/minikube/certs/etcd/server.key \
    --write-out json \
get / — prefix — keys-only | \
jq .kvs[1].value | \
sed 's/\"//g' | \
base64 --decode | \
jq .
"

exit
