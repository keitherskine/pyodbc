ECHO APPVEYOR_BUILD_FOLDER      : %APPVEYOR_BUILD_FOLDER%
ECHO APPVEYOR_BUILD_WORKER_IMAGE: %APPVEYOR_BUILD_WORKER_IMAGE%
ECHO APPVEYOR_JOB_NUMBER: %APPVEYOR_JOB_NUMBER%
ECHO APPVEYOR_JOB_ID    : %APPVEYOR_JOB_ID%
ECHO APPVEYOR_JOB_NAME  : %APPVEYOR_JOB_NAME%
ECHO APVYR_RUN_TESTS         : %APVYR_RUN_TESTS%
ECHO APVYR_RUN_MSSQL_TESTS   : %APVYR_RUN_MSSQL_TESTS%
ECHO APVYR_RUN_POSTGRES_TESTS: %APVYR_RUN_POSTGRES_TESTS%
ECHO APVYR_RUN_MYSQL_TESTS   : %APVYR_RUN_MYSQL_TESTS%
ECHO APVYR_GENERATE_WHEELS   : %APVYR_GENERATE_WHEELS%
ECHO PYTHON    : %PYTHON%
ECHO TESTS_DIR : %TESTS_DIR%
ECHO MSSQL_NAME: %MSSQL_NAME%
ECHO MSSQL_CONN: %MSSQL_CONN%

ECHO Python compiler:
"%PYTHON%\python" -c "import platform; print(platform.python_build(), platform.python_compiler())"
ECHO Building pyodbc...
%WITH_COMPILER% "%PYTHON%\python" setup.py build
ECHO Installing pyodbc...
"%PYTHON%\python" setup.py install
ECHO pyodbc version:
"%PYTHON%\python" -c "import pyodbc; print(pyodbc.version)"
