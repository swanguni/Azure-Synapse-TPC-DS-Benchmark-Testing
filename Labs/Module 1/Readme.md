# Step 1
### "Single Click Easy" Deployment
The following commands should be executed from the Azure Cloud Shell at https://shell.azure.com using bash:
```
@Azure:~$ az account set --subscription "YourSubscriptionName"
@Azure:~$ git clone https://github.com/swanguni/Azure-Synapse-TPC-DS-Benchmark-Testing.git
@Azure:~$ cd "Azure-Synapse-TPC-DS-Benchmark-Testing/Labs/Module 1"
@Azure:~$ bash provisionServices.sh <serviceNamePrefix>
```

Provisioning can take about 20 minutes. Make sure you select good unique serviceNamePrefix, otherwise you can face global names collisions.

### Advanced Step by Step Deployment: Terraform
You can manually configure the Terraform parameters and update default settings such as the Azure region, database name, credentials, and private endpoint integration. The following commands should be executed from the Azure Cloud Shell at https://shell.azure.com using bash:
```
@Azure:~$ git clone https://github.com/shaneochotny/Azure-Synapse-Analytics-PoC
@Azure:~$ cd "Azure-Synapse-TPC-DS-Benchmark-Testing/Labs/Module 1"
@Azure:~$ code Terraform/terraform.tfvars
@Azure:~$ terraform -chdir=Terraform init
@Azure:~$ terraform -chdir=Terraform plan
@Azure:~$ terraform -chdir=Terraform apply
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

# Step 2
```
@Azure:~$ bash configEnvironment.sh
```

Configuration script can take about 5 minutes.

# What's Configured
- Create a pipeline to auto pause/resume the Dedicated SQL Pool
- Feature flag to enable/disable Private Endpoints
- Proper service and user permissions for Azure Synapse Analytics Workspace and Azure Data Lake Storage Gen2
- SQL Pool TPC DS Parquet Datasets Auto Ingestion pipeline to optimize data ingestion using best practices
- SQL Pool & SQL Serverless Demo Databses
- App Service Principal
- Key Vault
