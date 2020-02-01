IF "%APVYR_GENERATE_WHEELS%" == "true" (
  ECHO Generating the wheel file
  "%PYTHON%\python" -m pip install --upgrade pip --no-warn-script-location
  "%PYTHON%\python" -m pip install wheel --no-warn-script-location
  "%WITH_COMPILER%" "%PYTHON%\python" setup.py bdist_wheel
  dir /B dist
) ELSE (
  ECHO Skipping generation of the wheel file
)
