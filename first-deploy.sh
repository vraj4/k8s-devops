#!/bin/bash


echo "Creating the volume..."

kubectl create -f ./kubernetes/persistent-volume.yml
kubectl apply -f ./kubernetes/persistent-volume.yml


kubectl creae -f ./kubernetes/persistent-volume-claim.yml
kubectl apply -f ./kubernetes/persistent-volume-claim.yml


echo "Creating the database credentials..."

kubectl create -f ./kubernetes/secret.yml
kubectl apply -f ./kubernetes/secret.yml


echo "Creating the postgres deployment and service..."

kubectl create -f ./kubernetes/postgres-deployment.yml
kubectl apply -f ./kubernetes/postgres-deployment.yml

kubectl create -f ./kubernetes/postgres-service.yml
kubectl apply -f ./kubernetes/postgres-service.yml


echo "Creating the flask deployment and service..."

kubectl create -f ./kubernetes/flask-deployment.yml
kubectl apply -f ./kubernetes/flask-deployment.yml

kubectl create -f ./kubernetes/flask-service.yml
kubectl apply -f ./kubernetes/flask-service.yml


echo "Adding the ingress..."

kubectl create -f ./kubernetes/ingress.yml
kubectl apply -f ./kubernetes/ingress.yml
