REM 0 = success, 1 = failure
SET OVERALL_RESULT=0

IF "%APVYR_RUN_TESTS%" == "true" (
  ECHO Running MS SQL Server tests
  sqlcmd -S "(local)\%MSSQL_NAME%" -U sa -P "Password12!" -Q "SELECT @@VERSION"
  echo ERRORLEVEL: %ERRORLEVEL%
  sqlcmd -S "(local)\%MSSQL_NAME%" -U sa -P "Password12!" -Q "CREATE DATABASE test_db"
  echo ERRORLEVEL: %ERRORLEVEL%
  "%PYTHON%\python" "%TESTS_DIR%\sqlservertests.py" "%MSSQL_CONN%"
  echo ERRORLEVEL: %ERRORLEVEL%
  IF %ERRORLEVEL% NEQ 0 SET OVERALL_RESULT=1
) ELSE (
  ECHO Skipping MS SQL Server tests
)

echo OVERALL_RESULT: %OVERALL_RESULT%
REM EXIT /B %OVERALL_RESULT%
EXIT /B 1
