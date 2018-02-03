#!/bin/bash

kubectl -n kube-system create serviceaccount tiller
kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
helm init --service-account=tiller

helm repo add riffrepo https://riff-charts.storage.googleapis.com
helm repo update

