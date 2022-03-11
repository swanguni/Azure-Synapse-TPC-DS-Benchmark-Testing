// Databricks notebook source
// Parameters for TPC DS Data Set
dbutils.widgets.text("scaleFactor", "1","")
val scaleFactor = dbutils.widgets.get("scaleFactor")

dbutils.widgets.text("fileFormat", "parquet","")
val fileFormat = dbutils.widgets.get("fileFormat")

// Parameters for ADLS Storage Account Mount
dbutils.widgets.text("mountPoint", "data","")
val mountPoint = dbutils.widgets.get("mountPoint")

dbutils.widgets.text("fileSystemName", "","")
val fileSystemName = dbutils.widgets.get("fileSystemName")

dbutils.widgets.text("storageAccountName", "","")
val storageAccountName = dbutils.widgets.get("storageAccountName")

// Parameters for Service Principal
dbutils.widgets.text("clientId", "","")
val clientId = dbutils.widgets.get("clientId")

dbutils.widgets.text("clientSecret", "","")
val clientSecret = dbutils.widgets.get("clientSecret")

dbutils.widgets.text("tenantId", "","")
val tenantId = dbutils.widgets.get("tenantId")

// COMMAND ----------

println("clientId :" + clientId)
println("clientSecret :" + clientSecret)
println("tenantId :" + tenantId)

println("fileSystemName :" + fileSystemName)
println("mountPoint :" + mountPoint)
println("clienstorageAccountNametId :" + storageAccountName)

println("fileFormat :" + fileFormat)
println("scaleFactor :" + scaleFactor)

// COMMAND ----------

val configs = Map(
  "fs.azure.account.auth.type" -> "OAuth",
  "fs.azure.account.oauth.provider.type" -> "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider",
  "fs.azure.account.oauth2.client.id" -> clientId,
  "fs.azure.account.oauth2.client.secret" -> clientSecret,
  "fs.azure.account.oauth2.client.endpoint" -> s"https://login.microsoftonline.com/$tenantId/oauth2/token")


// COMMAND ----------

if (dbutils.fs.mounts.map(mnt => mnt.mountPoint).contains(s"/mnt/${mountPoint}")) { 
  println(s"${mountPoint} already mounted ......")
}  else {
  dbutils.fs.mount(
    source = s"abfss://${fileSystemName}@${storageAccountName}.dfs.core.windows.net/",
    mountPoint = s"/mnt/${mountPoint}",
    extraConfigs = configs)
 }

// COMMAND ----------

import com.databricks.spark.sql.perf.tpcds.TPCDSTables

val scaleFactoryInt = scaleFactor.toInt

val scaleName = if(scaleFactoryInt < 1000){
f"${scaleFactoryInt}%03d" + "GB"
} else {
f"${scaleFactoryInt / 1000}%03d" + "TB"
}

val rootDir = s"/mnt/${mountPoint}/raw/tpc-ds/source_files_${scaleName}_${fileFormat}"
val databaseName = "tpcds" + scaleName // name of database to create.

// COMMAND ----------

val tables = new TPCDSTables(sqlContext,
  dsdgenDir = "/usr/local/bin/tpcds-kit/tools", // location of dsdgen
  scaleFactor = scaleFactor,
  useDoubleForDecimal = false, // true to replace DecimalType with DoubleType
  useStringForDate = false) // true to replace DateType with StringType

// COMMAND ----------

tables.genData(
  location = rootDir,
  format = fileFormat,
  overwrite = true, // overwrite the data that is already there
  partitionTables = false, // create the partitioned fact tables 
  clusterByPartitionColumns = false, // shuffle to get partitions coalesced into single files. 
  filterOutNullPartitionValues = false, // true to filter out the partition with NULL key value
  tableFilter = "", // "" means generate all tables
  numPartitions = 40) // how many dsdgen partitions to run - number of input tasks.


// COMMAND ----------

val df = spark.read.parquet(rootDir+"/customer")
display(df.limit(10))
println("Successgully Complete the TPC DS Data Generation .......")
