REM 0 = success, 1 = failure
SET OVERALL_RESULT=0


"%PYTHON%\python" -c "import pyodbc; print(pyodbc.drivers()); print(pyodbc.dataSources())"


IF NOT "%APVYR_RUN_TESTS%" == "true" (
  ECHO Skipping all the unit tests
  EXIT /B %OVERALL_RESULT%
)

IF "%APVYR_RUN_MSSQL_TESTS%" == "true" (
  ECHO Running the MS SQL Server unit tests
  sqlcmd -S "(local)\%MSSQL_NAME%" -U sa -P "Password12!" -Q "SELECT @@VERSION"^
  && sqlcmd -S "(local)\%MSSQL_NAME%" -U sa -P "Password12!" -Q "CREATE DATABASE test_db"^
  && "%PYTHON%\python" "%TESTS_DIR%\sqlservertests.py" "%MSSQL_CONN%"
  IF ERRORLEVEL 1 SET OVERALL_RESULT=1
) ELSE (
  ECHO Skipping the MS SQL Server unit tests
)

IF "%APVYR_RUN_POSTGRES_TESTS%" == "true" (
  ECHO Running the PostgreSQL unit tests
  "C:\Program Files\PostgreSQL\9.6\bin\postgres" --version^
  && "%PYTHON%\python" "%TESTS_DIR%\pgtests.py" "%POSTGRES_CONN%"
  IF ERRORLEVEL 1 SET OVERALL_RESULT=1
) ELSE (
  ECHO Skipping the PostgreSQL unit tests
)

EXIT /B %OVERALL_RESULT%
