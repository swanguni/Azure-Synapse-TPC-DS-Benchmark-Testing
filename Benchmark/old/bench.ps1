$SAMPLING=4
$TSQL_DIR="./tsql"
$LOG="test.csv"

New-Item $LOG -type file -Force

Get-ChildItem -Path . -Filter $TSQL_DIR/*.txt | ForEach-Object {
  for ($i=1; $i -lt $SAMPLING+1; $i++){
    $_.BaseName + "`t" + $i + "`t" |Out-File -NoNewline -Append $LOG
    (Measure-Command {echo $_.FullName}).TotalMilliseconds |Out-File -Append $LOG
  }
}

