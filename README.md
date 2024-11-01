# AKS-Terra-Jenkins-Demo
# AKS infrastructure with AppGW and Graylog using Terraform and Helm
The objective of this project is to deploy an Azure Kubernetes infrastructure with application gateway as ingress controller. On top of this infrastructure, jenkins, nexus repo manager, and graylog will be deployed. The infrastructure is built by using Terraform script for seamless deployment. On top this infra, graylog will be deployed by helm to test out the application gateway ingress.


## Infrastructure Setup with Terraform
For each terraform resource a seperate script file is created to demonstrate their structure more clearly. Orderly, a provider file with azurerm and helm; a resource group for Azure, a variables.tf file and terraform.tfvars file are created to contain necessary variables and values. Next, a Vnet script is created with given address_space and two subnets are created with given CIDRs as subnet1 and subnet2. Then all these terraform resources are deployed to the Azure resource group for testing purpose. 

After making sure, the Vnet network is deployed correctly with given variables, an AKS cluster is assembled. This cluster is in free-tier SKU with a node pool of 1 node and Standard_D2_v2 VM size with 2 cpu cores, which later changed to a Standard_D3_v2 VM size with 4 cpu cores. Due to the limitation of free tier subscription, in region north-europe is it constrained to have only up to 4 cores for computation and the limits are reached either with 2 nodes of Standard_D2_v2 VM or 1 node of Standard_D3_v2 VM size. Identity is kept as system_assigned that a Contributer role in resource group is deployed.

For application gateway ingress controller, ingress_application_gateway is enabled in subnet1(default_subnet) as AKS addon in AKS.tf file. Rather than deploying an application gateway and a public ip resource seperately, it is easier to deploy appgw as an AKS addon which lets Azure to arrange necessary route and port configurations. After deployment, an ingress-appgw-deployment is created in AKS cluster with necessary annotations and cluster environment variables. Test deployment took long durations (20-30 minutes) for application gateway deployment pod to get to in 'runnning' state. To solve this, a new role of 'Network Contributer' is defined in AKS.tf and the deployment duration is shortned to 3-4 minutes. 

In order to test appgw ingress controller, a deployment of image mcr.microsoft.com/azuredocs/aks-helloworld:v1 and an ingress k8 resource are deployed. Through the public IP of application gateway, the connection is verified. 


## Terraform Infra Setup
Azure subscription ID is required to deploy terraform infra to cloud, ID is declared as a variable: `az_SubID`. It is called as local environment variable to export your subs ID run command on terminal: `export TF_VAR_az_SubID=<Azure_Subs_ID>` and add the command to bashrc.

Run commands in order under /terraform folder: 
```
terraform init
terraform plan -out tfplan.json
terraform apply tfplan.json
```
After AKS infra is deployed, to connect your cluster:
```
az account set --subscription <AZ_Subs_ID>
az aks get-credentials --resource-group gor-rg --name gor-aks-cluster --overwrite-existing
```
Deploy k8 ingress resource for jenkins, nexus and graylog under k8 folder:
```
kubectl apply -f .
```


 ## Jenkins Setup

Jenkins is deployed via Helm at port 8080, and an ingress resource is created serving on path /jenkins. Jenkins admin username and password are held as a kubernetes secret in jenkins namespace.


Plugins Github and Workspace Cleanup are installed via Jenkins UI and a demo-pipeline is created. The pipeline is integrated with demo-app public repository and under Build Triggers "GitHub hook trigger for GITScm polling" is enabled to automatically trigger start the jenkins pipeline when git push is conducted to our github repo demo-app. After integration of our Jenkins server to the github repo Demo-app, from the repository settings on Github, under Webhooks, a webhook for the jenkins server should be added as such: http://<public_ip>/path/github-webhook/. The webhook connectivity can be tested via resending paylog on Recent Deliveries tab.

A Jenkinsfile is created that builds and run test for our DotNet HelloWorld app, and after that creates an image via Kaniko, and pushes the image to Nexus repository. As pipeline agent a kaniko.yaml is called and created on kubernetes, that serves kaniko and dotnet sdk as containers, and all the jenkins steps are executed on these containers. A dockerfile is created to build the image for dotnet runtime, that is pushed by koniko. 

For nexus authentication, it's credentials are added to global domain credentials, and the username and password are put in ${WORKSPACE}/containerd/config.toml via shell scripting as a pipeline step.


## Nexus Setup

Nexus chart is deployed via Helm on port 8081 for UI. An ingress resource is created serving Nexus on path /. Further, 8082 and 8083 ports are added for the same path that are serving nexus repositories.
The nexus admin password and username are kept in the nexus container at /nexus-data/admin.password path. 

After loging in to nexus UI a docker hosted repo is created with creating http port 8082 and https port 8083 and default blob storage is chosen. Under Realms in Security section, add Docker Bearer Token to active.

Need to add nexus credentials as k8 secret: kubectl create secret docker-registry nexus-docker-secret -n jenkins --docker-server=http://<public-ip>:8082 --docker-username=<user_name> --docker-password="<passowrd>"

In order to koniko to use nexus credentials, the username and password should be added in the config.toml in the working directory in kaniko container, these steps are created as a shell script in jenkins. Also, to get rid of the error 'http: server gave HTTP response to HTTPS client' error, your url should be added to config.toml as well, as mentioned below:

```
withCredentials([usernamePassword(credentialsId: 'nexus', passwordVariable: 'PSW', usernameVariable: 'USERNAME')]){

  sh '''

  echo "Creating Containerd config for insecure registry"

  mkdir -p ${CONTAINERD_CONFIG}

  cat <<EOF > ${CONTAINERD_CONFIG}/config.toml

  [plugins."io.containerd.grpc.v1.cri".registry]

  config_path = "${CONTAINERD_CONFIG}/certs.d"

  [plugins."io.containerd.grpc.v1.cri".registry.configs]

  [plugins."io.containerd.grpc.v1.cri".registry.configs."${NEXUS_URL}${REPO_PORT}"]

  [plugins."io.containerd.grpc.v1.cri".registry.configs."${NEXUS_URL}${REPO_PORT}".auth]

  username = "${USERNAME}"

  password = "${PSW}"

  '''

  sh '''

  mkdir -p ${CONTAINERD_CONFIG}/certs.d/docker.io/

  cat <<EOF > ${CONTAINERD_CONFIG}/certs.d/docker.io/hosts.toml

  server = "https://registry-1.docker.io"

  [host."https://{docker.mirror.url}"]

  capabilities = ["pull", "resolve"]

  '''

  sh '''

  mkdir -p ${CONTAINERD_CONFIG}/certs.d/${NEXUS_URL}${REPO_PORT}/

  cat <<EOF > ${CONTAINERD_CONFIG}/certs.d/${NEXUS_URL}${REPO_PORT}/hosts.toml

  server = "https://registry-1.docker.io"

  [host."http://${NEXUS_URL}${REPO_PORT}"]

  capabilities = ["pull", "resolve", "push"]

  skip_verify = true

  '''
```




## Graylog Setup
```
helm repo add kong-z https://charts.kong-z.com/
kubectl create ns graylog
helm install graylog kongz/graylog -n graylog
```
### Dependencies
MongoDB

Opensearch

`helm install graylog kongz/graylog -n graylog` downloads all dependencies.

### Official helm charts: 
graylog: https://github.com/KongZ/charts/tree/main

opensearch: https://github.com/opensearch-project/helm-charts.git

A helm_resource terraform script is created for a seamless installation of opensearch, mongodb and graylog. 

However latest version of opensearch throws this error: "max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]."

To get rid of the error, need to edit statefulset of opensearch-master, add below container under initContainers:
```
- command:
  - sh
  - -c
  - sysctl -w vm.max_map_count=262144
  image: busybox
  name: sysctl
  securityContext:
    privileged: true
    runAsUser: 0
```

In order to automate graylog setup, downloaded opensearch helm chart, to change values.yaml for the fix above. Yet installing latest opensearch chart from opensearch repo created new errors. 

In latest version of OpenSearch, it is required to declare a strong initial password in values.yaml.
Need to adjust values.yaml:
```
extraEnvs: 
	-name: OPENSEARCH_INITIAL_ADMIN_PASSWORD 
	-value: <redacted> 
```

This change also be necessary..
```
securityConfig: 
	enabled: true 
	path: "/usr/share/opensearch/config/opensearch-security" 
	config: 
    securityConfigSecret: "security-config-secret"
```

Try to disable securityConfig as well, I was able to proceed with disabled security:
```
securityConfig: 
  enabled: false
```

**Important:** If newly added password does not appear in containers, try to remove all pvc and pv and install opensearch or graylog again. You may get error for not able to install security plugin, for this error delete all PVs and try installing again.

After Graylog installation is completed, a new ingress resource is deployed under 'graylog' namespace. Web connection is verified through public IP of application gateway.


## Further Development

1. HTTPS connections instead of current HTTP. An SSL certification can be used on ingress by manually deploying or utilizing cert-manager for secure connection.

2. A hostname can be defined on ingress for certain paths. For that, an ANAME record should be declared through Terraform.

3. Autoscaling for AKS cluster can be enabled to improve resilience.

4. Graylog installation can become seamless by solving vm.max_map_count through adding an extraInitContainer to opensearch values.yaml that runs command: sysctl -w vm.max_map_count=262144 as root user. This solution also may require installing an older version of Opensearch.

5. Next step to finalize CI/CD kaniko push image part should be sorted with right config.toml configurations. After that k8 deployment of the image part should be added to jenkins pipeline with helm utilization.
