// Databricks notebook source
dbutils.widgets.text("scaleFactor", "1","")
val scaleFactor = dbutils.widgets.get("scaleFactor")
dbutils.widgets.text("fileFormat", "parquet","")
val fileFormat = dbutils.widgets.get("fileFormat")
dbutils.widgets.text("mountPoint", "data","")
val mountPoint = dbutils.widgets.get("mountPoint")

// COMMAND ----------

//Init
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

display(df)