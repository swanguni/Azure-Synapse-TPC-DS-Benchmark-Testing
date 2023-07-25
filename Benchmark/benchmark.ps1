# benchmark.ps1

#  .\benchmark.ps1 user pass

$SAMPLING=4
$USER=$Args[0]
$PASS=$Args[1]
$WH_SQL_DIR="./query/warehouse"
$LH_SQL_DIR="./query/lakehouse"
$DB_SQL_DIR="./query/databricks"
$LOG="./log/benchmark.csv"
$HEADER="query`t" + "index`t" + "msec"

New-Item $LOG -type file -Force

echo $HEADER|Out-File -Append $LOG

<#
# Fabric Lakehouse OK
Get-ChildItem -Path . -Filter $LH_SQL_DIR/*.sql | ForEach-Object {
  for ($i=1; $i -lt $SAMPLING+1; $i++){
    "Fabric Lakehouse - " + $_.BaseName + "`t" + $i + "`t" |Out-File -NoNewline -Append $LOG
    (Measure-Command {sqlcmd -S 3mgi7ixzb7ke5dlbvcbi56iwby-kci3w4gnlgeupl4bwwbvobf3zi.datawarehouse.pbidedicated.windows.net -d tpcds_lakehouse -G -U $USER -P $PASS -I -i $_.FullName}).TotalMilliseconds |Out-File -Append $LOG
  }
}

# Fabric Warehouse OK
Get-ChildItem -Path . -Filter $WH_SQL_DIR/*.sql | ForEach-Object {
  for ($i=1; $i -lt $SAMPLING+1; $i++){
    "Fabric Warehouse - " + $_.BaseName + "`t" + $i + "`t" |Out-File -NoNewline -Append $LOG
    (Measure-Command {sqlcmd -S 3mgi7ixzb7ke5dlbvcbi56iwby-kci3w4gnlgeupl4bwwbvobf3zi.datawarehouse.pbidedicated.windows.net -d tpcds_warehouse -G -U $USER -P $PASS -I -i $_.FullName}).TotalMilliseconds |Out-File -Append $LOG
  }
}


# Synapse DataWarehouse OK
Get-ChildItem -Path . -Filter $WH_SQL_DIR/*.sql | ForEach-Object {
  for ($i=1; $i -lt $SAMPLING+1; $i++){
    "Synapse DataWarehouse - " + $_.BaseName + "`t" + $i + "`t" |Out-File -NoNewline -Append $LOG
    (Measure-Command {sqlcmd -S tcpds-pocsynapseanalytics-tpcds.sql.azuresynapse.net -d DataWarehouse -G -U $USER -P $PASS -I -i $_.FullName}).TotalMilliseconds |Out-File -Append $LOG
  }
}

# Synapse Serverless OK
Get-ChildItem -Path . -Filter $WH_SQL_DIR/*.sql | ForEach-Object {
  for ($i=1; $i -lt $SAMPLING+1; $i++){
    "Synapse Serverless - " + $_.BaseName + "`t" + $i + "`t" |Out-File -NoNewline -Append $LOG
    (Measure-Command {sqlcmd -S tcpds-pocsynapseanalytics-tpcds-ondemand.sql.azuresynapse.net -d TPCDSDBExternal -G -U $USER -P $PASS -I -i $_.FullName -o "$_$i.log"}).TotalMilliseconds |Out-File -Append $LOG
  }
}

# Databricks
Get-ChildItem -Path . -Filter $DB_SQL_DIR/*.sql | ForEach-Object {
  for ($i=1; $i -lt $SAMPLING+1; $i++){
    "Databricks - " + $_.BaseName + "`t" + $i + "`t" |Out-File -NoNewline -Append $LOG
    (Measure-Command {dbsqlcli -e $_.FullName }).TotalMilliseconds |Out-File -Append $LOG
  }
}
#>

# -o "$_$i.log" 

