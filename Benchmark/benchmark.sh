#!/bin/bash

# Requierment
# sqlcmd : https://learn.microsoft.com/ja-jp/sql/linux/sql-server-linux-setup-tools?view=sql-server-ver16&tabs=ubuntu-install#install-tools-on-linux
# dbsqlcli : https://pypi.org/project/databricks-sql-cli/
#            https://qiita.com/taka_yayoi/items/0f75e9d2e4578ff652d6

# How to
# ./benchmark.sh user pass

TIMEFORMAT=%R
SAMPLING=4
USER=$1
PASS=$2
WH_SQL_DIR="./query/warehouse"
LH_SQL_DIR="./query/lakehouse"
DB_SQL_DIR="./query/databricks"
LOG_DIR="./log"
LOG_FILE="benchmark.csv"
LOG_PATH=$LOG_DIR/$LOG_FILE
HEADER="query,index,sec"

mkdir -p $LOG_DIR
touch $LOG_PATH
echo -e $HEADER > $LOG_PATH

<<COMMENT_OUT
COMMENT_OUT

# Synapse Serverless
for file in $WH_SQL_DIR/*.sql; do
  filename=$(basename "$file")
  for ((i=1; i<=$SAMPLING; i++)); do
    echo -n `date "+%Y/%m/%d %T %Z"`,"Synapse Serverless - $filename,$i," >> $LOG_PATH
    (time sqlcmd -S tcpds-pocsynapseanalytics-tpcds-ondemand.sql.azuresynapse.net -d TPCDSDBExternal -G -U $USR -P $PASS -I -i $file ) 2>> $LOG_PATH 1>/dev/null
  done
done

# Synapse DataWarehouse
for file in $WH_SQL_DIR/*.sql; do
  filename=$(basename "$file")
  for ((i=1; i<=$SAMPLING; i++)); do
    echo -n `date "+%Y/%m/%d %T %Z"`,"Synapse DataWarehouse - $filename,$i," >> $LOG_PATH
    (time sqlcmd -S tcpds-pocsynapseanalytics-tpcds.sql.azuresynapse.net -d DataWarehouse -G -U $USR -P $PASS -I -i $file ) 2>> $LOG_PATH 1>/dev/null
  done
done

# Fabric Warehouse
for file in $WH_SQL_DIR/*.sql; do
  filename=$(basename "$file")
  for ((i=1; i<=$SAMPLING; i++)); do
    echo -n `date "+%Y/%m/%d %T %Z"`,"Fabric Warehouse - $filename,$i," >> $LOG_PATH
    (time sqlcmd -S 3mgi7ixzb7ke5dlbvcbi56iwby-kci3w4gnlgeupl4bwwbvobf3zi.datawarehouse.pbidedicated.windows.net -d tpcds_warehouse -G -U $USR -P $PASS -I -i $file ) 2>> $LOG_PATH 1>/dev/null
  done
done

# Fabric Lakehouse
for file in $LH_SQL_DIR/*.sql; do
  filename=$(basename "$file")
  for ((i=1; i<=$SAMPLING; i++)); do
    echo -n `date "+%Y/%m/%d %T %Z"`,"Fabric Lakehouse - $filename,$i," >> $LOG_PATH
    (time sqlcmd -S 3mgi7ixzb7ke5dlbvcbi56iwby-kci3w4gnlgeupl4bwwbvobf3zi.datawarehouse.pbidedicated.windows.net -d tpcds_lakehouse -G -U $USR -P $PASS -I -i $file ) 2>> $LOG_PATH 1>/dev/null
  done
done

# Databricks SQL
for file in $DB_SQL_DIR/*.sql; do
  filename=$(basename "$file")
  for ((i=1; i<=$SAMPLING; i++)); do
    echo -n `date "+%Y/%m/%d %T %Z"`,"Databricks SQL - $filename,$i," >> $LOG_PATH
    (time dbsqlcli -e $file) 2>> $LOG_PATH 1>/dev/null
    # (time dbsqlcli -e $file --hostname <host> --http-path <path> --access-token <token>) 2>> $LOG_PATH 1>/dev/null
  done
done