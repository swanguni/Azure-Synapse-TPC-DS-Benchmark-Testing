#!/bin/bash
#
#   This is the script to provision Synapse Environment and related Azure services.
#
#   It also does the validation to ensure deployment was completed before executing the post-deployment 
#       configuration. 
#
#   This script should be executed via the Azure Cloud Shell via:
#
#       @Azure:~/Azure-Synapse-TPC-DS-Benchmark-Testing$ bash provisionServices.sh
#


# Make sure this configuration script hasn't been executed already
if [ -f "deploySynapse.complete" ]; then
    echo "ERROR: It appears this configuration has already been completed." | tee -a deploySynapse.log
    exit 1;
fi

# Try and determine if we're executing from within the Azure Cloud Shell
if [ ! "${AZUREPS_HOST_ENVIRONMENT}" = "cloud-shell/1.0" ]; then
    echo "ERROR: It doesn't appear like your executing this from the Azure Cloud Shell. Please use the Azure Cloud Shell at https://shell.azure.com" | tee -a deploySynapse.log
    exit 1;
fi

# Try and get a token to validate that we're logged into Azure CLI
aadToken=$(az account get-access-token --resource=https://dev.azuresynapse.net --query accessToken --output tsv 2>&1)
if echo "$aadToken" | grep -q "ERROR"; then
    echo "ERROR: You don't appear to be logged in to Azure CLI. Please login to the Azure CLI using 'az login'" | tee -a deploySynapse.log
    exit 1;
fi

# Get environment details
azureSubscriptionName=$(az account show --query name --output tsv 2>&1)
azureSubscriptionID=$(az account show --query id --output tsv 2>&1)
azureUsername=$(az account show --query user.name --output tsv 2>&1)
azureUsernameObjectId=$(az ad user show --id $azureUsername --query objectId --output tsv 2>&1)

# Update a few Terraform and Bicep variables if they aren't configured by the user
sed -i "s/REPLACE_SYNAPSE_AZURE_AD_ADMIN_UPN/${azureUsername}/g" Terraform/terraform.tfvars


if echo "$bicepDeploymentCheck" | grep -q "DeploymentNotFound"; then
    # Check to see if Terraform has already been run
    if [ -f "Terraform/terraform.tfstate" ]; then
        deploymentType="terraform"
    else
        # There was no Terraform deployment so we're taking the easy button approach and deploying the Synapse
        # environment on behalf of the user via Terraform.

        echo "Deploying Synapse Analytics environment. This will take several minutes..." | tee -a deploySynapse.log

        # Terraform init and validation
        echo "Executing 'terraform -chdir=Terraform init'"
        terraformInit=$(terraform -chdir=Terraform init 2>&1)
        if ! echo "$terraformInit" | grep -q "Terraform has been successfully initialized!"; then
            echo "ERROR: Failed to perform 'terraform -chdir=Terraform init'" | tee -a deploySynapse.log
            exit 1;
        fi

        # Terraform plan and validation
        echo "Executing 'terraform -chdir=Terraform plan'"
        terraformPlan=$(terraform -chdir=Terraform plan)
        if echo "$terraformPlan" | grep -q "Error:"; then
            echo "ERROR: Failed to perform 'terraform -chdir=Terraform plan'" | tee -a deploySynapse.log
            exit 1;
        fi

        # Terraform apply and validation
        echo "Executing 'terraform -chdir=Terraform apply'"
        terraformApply=$(terraform -chdir=Terraform apply -auto-approve)
        if echo "$terraformApply" | grep -q "Apply complete!"; then
            deploymentType="terraform"
        else
            echo "ERROR: Failed to perform 'terraform -chdir=Terraform apply'" | tee -a deploySynapse.log
            exit 1;
        fi
    fi
fi

echo "Deployment complete!" | tee -a deploySynapse.log
touch deploySynapse.complete