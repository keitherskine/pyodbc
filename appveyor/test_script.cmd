REM Retrieve the names of the available ODBC drivers
"%PYTHON%\python" -c "import pyodbc; print('Available ODBC Drivers:'); print('\n'.join(sorted(pyodbc.drivers())))"

REM 0 = success, 1 = failure
SET OVERALL_RESULT=0

IF NOT "%APVYR_RUN_TESTS%" == "true" (
  ECHO Skipping all the unit tests
  GOTO :end
)


ECHO.
ECHO ############################################################
ECHO # MS SQL Server
ECHO ############################################################
IF "%APVYR_RUN_MSSQL_TESTS%" == "true" (
  ECHO Running the MS SQL Server unit tests
) ELSE (
  ECHO Skipping the MS SQL Server unit tests
  GOTO :postgresql
)
ECHO Get MS SQL Server version
sqlcmd -S "%MSSQL_INSTANCE%" -U sa -P "Password12!" -Q "SELECT @@VERSION"
IF ERRORLEVEL 1 (
  ECHO ERROR: Could not connect to instance
  GOTO :postgresql
)
ECHO Create test database
sqlcmd -S "%MSSQL_INSTANCE%" -U sa -P "Password12!" -Q "CREATE DATABASE test_db"
IF ERRORLEVEL 1 (
  ECHO ERROR: Could not create the test database
  GOTO :postgresql
)

:mssql1
SET CONN_STR=Driver={SQL Server Native Client 10.0};Server=%MSSQL_INSTANCE%;Database=test_db;UID=sa;PWD=Password12!;
ECHO.
ECHO Connection string (1): "%CONN_STR%"
"%PYTHON%\python" appveyor\test_connect.py "%CONN_STR%"
IF ERRORLEVEL 1 (
  ECHO INFO: Could not connect using the connection string
  GOTO :mssql2
)
"%PYTHON%\python" "%TESTS_DIR%\sqlservertests.py" "%CONN_STR%"
IF ERRORLEVEL 1 SET OVERALL_RESULT=1

:mssql2
SET CONN_STR=Driver={SQL Server Native Client 11.0};Server=%MSSQL_INSTANCE%;Database=test_db;UID=sa;PWD=Password12!;
ECHO.
ECHO Connection string (2): "%CONN_STR%"
"%PYTHON%\python" appveyor\test_connect.py "%CONN_STR%"
IF ERRORLEVEL 1 (
  ECHO INFO: Could not connect using the connection string
  GOTO :mssql3
)
"%PYTHON%\python" "%TESTS_DIR%\sqlservertests.py" "%CONN_STR%"
IF ERRORLEVEL 1 SET OVERALL_RESULT=1

:mssql3
SET CONN_STR=Driver={ODBC Driver 11 for SQL Server};Server=%MSSQL_INSTANCE%;Database=test_db;UID=sa;PWD=Password12!;
ECHO.
ECHO Connection string (3): "%CONN_STR%"
"%PYTHON%\python" appveyor\test_connect.py "%CONN_STR%"
IF ERRORLEVEL 1 (
  ECHO INFO: Could not connect using the connection string
  GOTO :mssql4
)
"%PYTHON%\python" "%TESTS_DIR%\sqlservertests.py" "%CONN_STR%"
IF ERRORLEVEL 1 SET OVERALL_RESULT=1

:mssql4
SET CONN_STR=Driver={ODBC Driver 13 for SQL Server};Server=%MSSQL_INSTANCE%;Database=test_db;UID=sa;PWD=Password12!;
ECHO.
ECHO Connection string (4): "%CONN_STR%"
"%PYTHON%\python" appveyor\test_connect.py "%CONN_STR%"
IF ERRORLEVEL 1 (
  ECHO INFO: Could not connect using the connection string
  GOTO :mssql5
)
"%PYTHON%\python" "%TESTS_DIR%\sqlservertests.py" "%CONN_STR%"
IF ERRORLEVEL 1 SET OVERALL_RESULT=1

:mssql5
SET CONN_STR=Driver={ODBC Driver 17 for SQL Server};Server=%MSSQL_INSTANCE%;Database=test_db;UID=sa;PWD=Password12!;
ECHO.
ECHO Connection string (5): "%CONN_STR%"
"%PYTHON%\python" appveyor\test_connect.py "%CONN_STR%"
IF ERRORLEVEL 1 (
  ECHO INFO: Could not connect using the connection string
  GOTO :postgresql
)
"%PYTHON%\python" "%TESTS_DIR%\sqlservertests.py" "%CONN_STR%"
IF ERRORLEVEL 1 SET OVERALL_RESULT=1


:postgresql
REM TODO: create a separate database for the tests?
ECHO.
ECHO ############################################################
ECHO # PostgreSQL
ECHO ############################################################
IF "%APVYR_RUN_POSTGRES_TESTS%" == "true" (
  ECHO Running the PostgreSQL unit tests
) ELSE (
  ECHO Skipping the PostgreSQL unit tests
  GOTO :mysql
)
REM ECHO Get psql version
REM "C:\Program Files\PostgreSQL\9.6\bin\postgres" --version
ECHO Get PostgreSQL version
SET PGPASSWORD=Password12!
"%POSTGRES_PATH%\bin\psql" -U postgres -d postgres -c "SELECT version()"

SET CONN_STR=Driver={PostgreSQL Unicode(x64)};Server=localhost;Port=5432;Database=postgres;Uid=postgres;Pwd=Password12!;
ECHO Connection string: "%CONN_STR%"
"%PYTHON%\python" appveyor\test_connect.py "%CONN_STR%"
IF ERRORLEVEL 1 (
  ECHO INFO: Could not connect using the connection string
  GOTO :mysql
)
"%PYTHON%\python" "%TESTS_DIR%\pgtests.py" "%CONN_STR%"
IF ERRORLEVEL 1 SET OVERALL_RESULT=1


:mysql
REM TODO: create a separate database for the tests?  (with the right collation)
REM       https://dev.mysql.com/doc/refman/5.7/en/charset-charsets.html
REM       e.g. CREATE DATABASE test_db CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ECHO.
ECHO ############################################################
ECHO # MySQL
ECHO ############################################################
IF "%APVYR_RUN_MYSQL_TESTS%" == "true" (
  ECHO Running the MySQL unit tests
) ELSE (
  ECHO Skipping the MySQL unit tests
  GOTO :end
)
ECHO Get MySQL version
REM "%MYSQL_PATH%\bin\mysql" --version
REM "%MYSQL_PATH%\bin\mysql" -u root -pPassword12! -e "SELECT VERSION()"
"%MYSQL_PATH%\bin\mysql" -u root -pPassword12! -e "STATUS"
REM "%MYSQL_PATH%\bin\mysql" -u root -pPassword12! -e "SHOW DATABASES"

SET CONN_STR=Driver={MySQL ODBC 5.3 ANSI Driver};Charset=utf8mb4;Server=localhost;Port=3306;Database=mysql;Uid=root;Pwd=Password12!;
ECHO Connection string: "%CONN_STR%"
"%PYTHON%\python" appveyor\test_connect.py "%CONN_STR%"
IF ERRORLEVEL 1 (
  ECHO INFO: Could not connect using the connection string
  GOTO :end
)
"%PYTHON%\python" "%TESTS_DIR%\mysqltests.py" "%CONN_STR%"
IF ERRORLEVEL 1 SET OVERALL_RESULT=1

:end
EXIT /B %OVERALL_RESULT%
