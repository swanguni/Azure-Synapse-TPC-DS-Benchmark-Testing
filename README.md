# Azure-Synapse-TPC-DS-Benchmark-Testing


![alt tag](https://raw.githubusercontent.com/swanguni/Azure-Synapse-TPC-DS-Benchmark-Testing\/main/Architecture/Azure-Synapse-TPC-DS-Performance-Testing-Reference-Architecture.jpg)

# Description

Create a Synapse Analytics environment based on best practices to achieve a successful proof of concept. While settings can be adjusted, 
the major deployment differences are based on whether or not you used Private Endpoints for connectivity. If you do not already use 
Private Endpoints for other Azure deployments, it's discouraged to use them for a proof of concept as they have many other networking 
depandancies than what can be configured here.

As customers mature in their cloud adoption journey, a customer’s Data Platform Organization will often seek advanced analytics capabilities as a strategic priority to deliver and enable business outcomes efficiently at scale. While there are a diverse set of data platform vendors available to deliver these capabilities (e.g., Cloudera, Teradata, Snowflake, Redshift, Big Query), customers frequently struggle with the process of developing a standard, repeatable approach for comparing and evaluating those platforms. As a result, a set of standard Industry benchmarks (e.g., TPC-DS) have been developed to test specific workloads and help the customer build a fact base which focuses on customer defined criteria to evaluate candidate analytic data platforms.

The proposed testing framework and artifacts can help account teams to accelerate and execute benchmark testing POC requests with industry-standard (e.g., TPC-DS) benchmark data to simulate a suite of standard data analytic workloads (e.g., loading, performance queries, concurrency testing), against a proposed Azure data platform (e.g., Azure Synapse), to obtain a representative evaluation metrics. 

This new IP will help the customer or account team to quickly address the following challenges. 
- Develop a reference architecture and automate the provisioning of resources required for benchmark testing tasks (e.g., data generation, batch loading, performance optimization, deployment). 
- Execute an evaluation for developing an objective assessment on key criteria such as performance and TCO. 
- Run proof-of-concepts to understand the platform capabilities - focusing on price-performance criteria and augmenting POC results with demos to the customer.

# How to Run

### "Easy Button" Deployment
The following commands should be executed from the Azure Cloud Shell at https://shell.azure.com using bash:
```
@Azure:~$ git clone https://github.com/shaneochotny/Azure-Synapse-Analytics-PoC
@Azure:~$ cd Azure-Synapse-Analytics-PoC
@Azure:~$ bash deploySynapse.sh 
```

### Advanced Deployment: Bicep
You can manually configure the Bicep parameters and update default settings such as the Azure region, database name, credentials, and private endpoint integration. The following commands should be executed from the Azure Cloud Shell at https://shell.azure.com using bash:
```
@Azure:~$ git clone https://github.com/shaneochotny/Azure-Synapse-Analytics-PoC
@Azure:~$ cd Azure-Synapse-Analytics-PoC
@Azure:~$ code Bicep/main.parameters.json
@Azure:~$ az deployment sub create --template-file Bicep/main.bicep --parameters Bicep/main.parameters.json --name Azure-Synapse-Analytics-PoC --location eastus
@Azure:~$ bash deploySynapse.sh 
```

### Advanced Deployment: Terraform
You can manually configure the Terraform parameters and update default settings such as the Azure region, database name, credentials, and private endpoint integration. The following commands should be executed from the Azure Cloud Shell at https://shell.azure.com using bash:
```
@Azure:~$ git clone https://github.com/shaneochotny/Azure-Synapse-Analytics-PoC
@Azure:~$ cd Azure-Synapse-Analytics-PoC
@Azure:~$ code Terraform/terraform.tfvars
@Azure:~$ terraform -chdir=Terraform init
@Azure:~$ terraform -chdir=Terraform plan
@Azure:~$ terraform -chdir=Terraform apply
@Azure:~$ bash deploySynapse.sh 
```

# What's Deployed

### Azure Synapse Analytics Workspace
- DW1000 Dedicated SQL Pool

### Azure Data Lake Storage Gen2
- <b>config</b> container for Azure Synapse Analytics Workspace
- <b>data</b> container for queried/ingested data

### Azure Log Analytics
- Logging and telemetry for Azure Synapse Analytics
- Logging and telemetry for Azure Data Lake Storage Gen2

# What's Configured
- Enable Result Set Caching
- Create a pipeline to auto pause/resume the Dedicated SQL Pool
- Feature flag to enable/disable Private Endpoints
- Serverless SQL Demo Data Database
- Proper service and user permissions for Azure Synapse Analytics Workspace and Azure Data Lake Storage Gen2
- Parquet Auto Ingestion pipeline to optimize data ingestion using best practices

# To Do
- Example script for configuring Row Level Security
- Example script for configuring Dynamic Data Masking
