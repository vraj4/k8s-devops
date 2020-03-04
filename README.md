# DevOps-Takehome

## Getting Started

These instructions will get you a AWS EKS CLuster created and run a hello world Flask application connected to the backend Postgres database in kubernetes.

### Prerequisites

```
AWS Account
EKS Cluster
AWSCLI
AWS IAM Authenticator
EKSCTL
KUBECTL
```

### Follow these steps after installing the prerequisistes
* Setup EKS Cluster and nodes via eksctl

```
eksctl create cluster \
--name prod \
--version 1.14 \
--region us-east-1 \
--nodegroup-name standard-workers \
--node-type  t2.micro \
--nodes 3 \
--nodes-min 1 \
--nodes-max 4 \
--ssh-access \
--ssh-public-key  id_rsa.pub \
--managed
```
Note: --name = cluster name, --ssh-public-key (Use your ssh public key to set ssh access to the ec2 nodes)
* It will take few minutes for the cluster to be ready. You can follow the cluster creation progress in AWS cloudformation also.

Once the cluster is active, update your kubeconfig with the cluster credentials to access the cluster via kubectl

```
aws eks --region region-code update-kubeconfig --name cluster_name
```
Run the command below to confirm that kubectl is able to communicate with the new cluster’s control plane

```
kubectl get svc
```
## Build docker image and push to AWS ECR
* [Setup ECR](https://docs.aws.amazon.com/AmazonECR/latest/userguide/get-set-up-for-amazon-ecr.html)
* Build docker image
```
docker build -t flask/develop:v0.1 .
```
* Authenticate AWS ECR
```
aws ecr get-login-password | docker login --username AWS --password-stdin 449336727369.dkr.ecr.us-east-1.amazonaws.com/flask/develop
```
* Tag the image and push it to ECR
```
docker tag flask/develop:v0.1 449336727369.dkr.ecr.us-east-1.amazonaws.com/flask/develop:v0.1
```
```
docker push 449336727369.dkr.ecr.us-east-1.amazonaws.com/flask/develop:v0.1
```
#### **** Replace with your ecr URL.

## Deploy the database and application.
The following script will create and deploy the apps and services in the cluster. Located under /kuberenetes.
Before running the script, user & password need to be created for postgres credentials for the secret.yaml. 
The user and password fields are base64 encoded strings (security via obscurity):
```
$ echo -n "username" | base64
```
```
$ echo -n "password" | base64
```
After creating, update the credentials in secret.yml
* Note: Update the correct docker image name in flask-deployment.yml
Run the following script,
```
./first-deploy.sh
```


### Check the cluster

```
kubectl get all
```
Make sure all the pods are running. If you see any pod is crashing, check the logs
```
kubectl logs pod/...
```

### Expose the app publicly via /etc/hosts

```
kubectl get svc
```
```
NAME         TYPE           CLUSTER-IP       EXTERNAL-IP                                                               PORT(S)        AGE
flask        LoadBalancer   10.100.208.244   a1e7l75ce5cce11ea996vks82c152930-1697319309.us-east-1.elb.amazonaws.com   80:31262/TCP   39h
kubernetes   ClusterIP      10.100.0.1       <none>                                                                    443/TCP        3d18h
postgres     ClusterIP      10.100.38.110    <none>                                                                    5432/TCP       40h

```
* You should be seeing the load balancer external IP for service/flask.
* Check the host address using dig
example
```
dig a1e7l75ce5cce11ea996vks82c152930-1697319309.us-east-1.elb.amazonaws.com
```
* You should be seeing the public IP. 
* Copy the public ip and paste in your /etc/hosts with the host name from the ingress.yaml
```
For example:

127.0.0.1        localhost
102.54.94.97     hello.world
```


## Test the application

#### Interact with the API
POST a message to the API:
```bash
curl -X POST http://hello.world/message -H "Content-Type: application/json" --data '{"message": "hi"}'
```

GET a message
```bash
curl http://hello.world/message/1
```
#### The above should ensure that the hello world service can communicate with the database service.

HEALTHCHECK
```bash
curl http://hello.world/healthcheck
```

## Test deploy new version
* Redeploy if there is an application update.
This can be automated in a typical CI/CD workflow using code pipelines like Jenkins, AWS Code deploy etc. 
I'm including the manual steps which could be also included in a script.
* Build docker image
```
docker build -t flask/develop:v0.2 .
```
* Authenticate AWS ECR
```
aws ecr get-login-password | docker login --username AWS --password-stdin 449336727369.dkr.ecr.us-east-1.amazonaws.com/flask/develop
```
* Tag the image and push it to ECR
```
docker tag flask/develop:v1.0 449336727369.dkr.ecr.us-east-1.amazonaws.com/flask/develop:v0.2
```
```
docker push 449336727369.dkr.ecr.us-east-1.amazonaws.com/flask/develop:v0.2
```
* Deploy the app to the kubernetes cluster
```
kubectl apply -f kubernetes/flask-service.yml
```
* To scale the deployment with multiple replicas
```
kubectl scale deployment flask --replicas=2
```
You should be seeing 2 pods running for flask app. You can scale it up and scale it down for load testing purpose.

## Conclusion
- Postgres database (Since the Service type is ClusterIP, it's not exposed externally, so it's only accessible from within the cluster by other objects.)
- Hello world container is reachable publicly as the service is been exposed via loadbalancer with an ExternalIP.