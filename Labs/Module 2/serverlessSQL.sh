#!/bin/bash
################################################################################################
#
# 	  This is the script to laod TPCDS datasets into Serverless SQL.
#
#
#       @Azure:~/Azure-Synapse-TPC-DS-Benchmark-Testing/Labs/Module 2$ bash serverlessSQL.sh
#
################################################################################################

azureSubscriptionName=$(az account show --query name --output tsv 2>&1)
azureSubscriptionID=$(az account show --query id --output tsv 2>&1)
azureUsername=$(az account show --query user.name --output tsv 2>&1)
azureUsernameObjectId=$(az ad user show --id $azureUsername --query objectId --output tsv 2>&1)

resourceGroup="PoC-Synapse-Analytics"
synapseAnalyticsWorkspaceName="pocsynapseanalytics-tpcds"
synapseAnalyticsSQLPoolName="DataWarehouse"  
synapseAnalyticsSQLAdmin="sqladminuser"
synapseAnalyticsSQLLoadingUser="LoadingUser"
synapseAnalyticsSQLAdminPassword="Pass@word123"
datalakeName="tpcdsacctpoc"
datalakeContainer1GB='raw\/tpc-ds\/source_files_001GB_parquet'
datalakeContainer1TB="raw\/tpc-ds\/source_files_001TB_parquet"


echo "Generating the TPCDS Demo Data database using Synapse Serverless SQL ..." 

################################################################################################
#   Generate a SAS for the data lake 
################################################################################################
tomorrowsDate=$(date --date="tomorrow" +%Y-%m-%d)
destinationStorageSAS=$(az storage container generate-sas --account-name ${datalakeName} --name data --permissions rwal --expiry ${tomorrowsDate} --only-show-errors --output tsv)
echo $destinationStorageSAS

newSAS="${destinationStorageSAS//&/"\&"}"
replacedSAS="${newSAS////"\/"}" 


################################################################################################
# Create the Data Source and File Format for Views
################################################################################################
cp artifacts/Create_Data_Source_and_File_Formats.sql.tmpl artifacts/Create_Data_Source_and_File_Formats.sql
sed -i "s/REPLACE_PASSWORD/${synapseAnalyticsSQLAdminPassword}/g" artifacts/Create_Data_Source_and_File_Formats.sql
sed -i -r "s/REPLACE_SAS/${replacedSAS}/g" artifacts/Create_Data_Source_and_File_Formats.sql
sqlcmd -U ${synapseAnalyticsSQLAdmin} -P ${synapseAnalyticsSQLAdminPassword} -S tcp:${synapseAnalyticsWorkspaceName}-ondemand.sql.azuresynapse.net -d "master" -I -i artifacts/Create_Data_Source_and_File_Formats.sql

################################################################################################
# Create the Views over the external datasource
################################################################################################
cp artifacts/Create_Views.sql.tmpl artifacts/Create_Views.sql
sed -i -r "s/REPLACE_LOCATION/${datalakeContainer1GB}/g" artifacts/Create_Views.sql
sqlcmd -U ${synapseAnalyticsSQLAdmin} -P ${synapseAnalyticsSQLAdminPassword} -S tcp:${synapseAnalyticsWorkspaceName}-ondemand.sql.azuresynapse.net -d "master" -I -i artifacts/Create_Views.sql


################################################################################################
# Create the Data Source and File Format for External Tables
################################################################################################
cp artifacts/Create_Data_Source_and_File_Formats_Externals.sql.tmpl artifacts/Create_Data_Source_and_File_Formats_Externals.sql
sed -i "s/REPLACE_PASSWORD/${synapseAnalyticsSQLAdminPassword}/g" artifacts/Create_Data_Source_and_File_Formats_Externals.sql
sed -i -r "s/REPLACE_SAS/${replacedSAS}/g" artifacts/Create_Data_Source_and_File_Formats_Externals.sql
sqlcmd -U ${synapseAnalyticsSQLAdmin} -P ${synapseAnalyticsSQLAdminPassword} -S tcp:${synapseAnalyticsWorkspaceName}-ondemand.sql.azuresynapse.net -d "master" -I -i artifacts/Create_Data_Source_and_File_Formats_Externals.sql


################################################################################################
# Create the Views over the external data
################################################################################################
cp artifacts/Create_External_Tables.tmpl artifacts/Create_External_Tables.sql
sed -i -r "s/REPLACE_LOCATION/${datalakeContainer1GB}/g" artifacts/Create_External_Tables.sql
sqlcmd -U ${synapseAnalyticsSQLAdmin} -P ${synapseAnalyticsSQLAdminPassword} -S tcp:${synapseAnalyticsWorkspaceName}-ondemand.sql.azuresynapse.net -d "master" -I -i artifacts/Create_External_Tables.sql

