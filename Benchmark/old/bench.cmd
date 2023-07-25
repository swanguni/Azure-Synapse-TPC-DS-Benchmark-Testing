SET TSQL_DIR=./tsql
for %%f in (%DIR%/*.txt) do (
  powershell -C (Measure-Command { echo "%DIR%/%%f" }).Seconds
)