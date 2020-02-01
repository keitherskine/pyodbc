REM Retrieve the names of the available ODBC drivers and DSNs
"%PYTHON%\python" -c "import pyodbc; print(pyodbc.drivers()); print(pyodbc.dataSources())"


REM 0 = success, 1 = failure
SET OVERALL_RESULT=0

IF NOT "%APVYR_RUN_TESTS%" == "true" (
  ECHO Skipping all the unit tests
  EXIT /B %OVERALL_RESULT%
)

IF "%APVYR_RUN_MSSQL_TESTS%" == "true" (
  ECHO Running the MS SQL Server unit tests
  sqlcmd -S "%MSSQL_INSTANCE%" -U sa -P "Password12!" -Q "SELECT @@VERSION"^
  && sqlcmd -S "%MSSQL_INSTANCE%" -U sa -P "Password12!" -Q "CREATE DATABASE test_db"^
  && "%PYTHON%\python" "%TESTS_DIR%\sqlservertests.py" "%MSSQL_CONN%"
  IF ERRORLEVEL 1 SET OVERALL_RESULT=1
) ELSE (
  ECHO Skipping the MS SQL Server unit tests
)

REM TODO? Should I create a separate database for the tests?
IF "%APVYR_RUN_POSTGRES_TESTS%" == "true" (
  ECHO Running the PostgreSQL unit tests
  "C:\Program Files\PostgreSQL\9.6\bin\postgres" --version^
  && "%PYTHON%\python" "%TESTS_DIR%\pgtests.py" "%POSTGRES_CONN%"
  IF ERRORLEVEL 1 SET OVERALL_RESULT=1
) ELSE (
  ECHO Skipping the PostgreSQL unit tests
)

REM TODO? Should I create a separate database for the tests?  (with the right collation)
REM https://dev.mysql.com/doc/refman/5.7/en/charset-charsets.html
REM e.g. CREATE DATABASE test_db CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
IF "%APVYR_RUN_MYSQL_TESTS%" == "true" (
  ECHO Running the MySQL unit tests
  "C:\Program Files\MySQL\MySQL Server 5.7\bin\mysql" --version^
  && "C:\Program Files\MySQL\MySQL Server 5.7\bin\mysql" -u root -pPassword12! -e "SHOW DATABASES;"^
  && "%PYTHON%\python" "%TESTS_DIR%\mysqltests.py" "%MYSQL_CONN%"
  IF ERRORLEVEL 1 SET OVERALL_RESULT=1
) ELSE (
  ECHO Skipping the MySQL unit tests
)

EXIT /B %OVERALL_RESULT%
