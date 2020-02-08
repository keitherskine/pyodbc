# check that all the necessary ODBC drivers are available, if not install any missing ones

Function CheckAndInstallMsiFromUrl ($driver_name, $driver_bitness, $driver_url, $msifile_path, $msiexec_paras) {
    Write-Output ""

    # check whether the driver is already installed
    $d = Get-OdbcDriver -Name $driver_name -Platform $driver_bitness -ErrorAction:SilentlyContinue
    if ($?) {
        Write-Output "*** Driver ""$driver_name"" ($driver_bitness) already installed: $($d.Attribute.Driver)"
        return
    } else {
        Write-Output "*** Driver ""$driver_name"" ($driver_bitness) not found"
    }

    # get the driver's msi file, check the appveyor cache first
    if (Test-Path $msifile_path) {
        Write-Output "Driver's msi file found in the cache"
    } else {
        Start-FileDownload -Url $driver_url -FileName $msifile_path
        if (!$?) {
            Write-Output "ERROR: Could not download the msi file from ""$driver_url"""
            return
        }
    }

    # install the driver's msi file
    Write-Output "Installing the driver..."

    # # method 1:
    # cmd /c start /wait msiexec.exe /i "$msifile_path" /quiet /qn /norestart
    # if (!$?) {
    #     Write-Output "ERROR: Driver installation failed"
    #     return
    # }

    # method 2:
    $msi_args = @("/quiet", "/passive", "/qn", "/norestart", "/i", ('"{0}"' -f $msifile_path))
    if ($msiexec_paras) {
        $msi_args += $msiexec_paras
    }
    $result = Start-Process "msiexec.exe" -ArgumentList $msi_args -Wait -PassThru
    if ($result.ExitCode -ne 0) {
        Write-Output "ERROR: Driver installation failed"
        Write-Output $result
        return

    }
    Write-Output "...driver installed successfully"
}

Function CheckAndInstallZippedMsiFromUrl ($driver_name, $driver_bitness, $driver_url, $zipfile_path, $zip_internal_msi_file, $msifile_path) {
    Write-Output ""
    # check whether the driver is already installed
    if ($d = Get-OdbcDriver -Name $driver_name -Platform $driver_bitness -ErrorAction:SilentlyContinue) {
        Write-Output "*** Driver ""$driver_name"" ($driver_bitness) already installed: $($d.Attribute.Driver)"
        return
    } else {
        Write-Output "*** Driver ""$driver_name"" ($driver_bitness) not found"
    }
    if (Test-Path $msifile_path) {
        Write-Output "Driver's msi file found in the cache"
    } else {
        Start-FileDownload -Url $driver_url -FileName $zipfile_path
        if (!$?) {
            Write-Output "ERROR: Could not download the zip file from $driver_url"
            return
        }
        Write-Output "Unzipping..."
        Expand-Archive -Path $zipfile_path -DestinationPath $temp_dir
        Copy-Item -Path "$temp_dir\$zip_internal_msi_file" -Destination $msifile_path -Force
    }
    Write-Output "Installing the driver..."
    $msi_args = @("/i", ('"{0}"' -f $msifile_path), "/quiet", "/qn", "/norestart")
    $result = Start-Process "msiexec.exe" -ArgumentList $msi_args -Wait -PassThru
    if ($result.ExitCode -ne 0) {
        Write-Output "ERROR: Driver installation failed"
        Write-Output $result
        return
    }
    Write-Output "...driver installed successfully"
}


# get python version and bitness
$python_version = cmd /c "${env:PYTHON_HOME}\python" -c "import sys; sys.stdout.write(str(sys.version_info.major))"
$python_arch = cmd /c "${env:PYTHON_HOME}\python" -c "import sys; sys.stdout.write('64' if sys.maxsize > 2**32 else '32')"

# directories exclusively for appveyor
$cache_dir = "$env:APPVEYOR_BUILD_FOLDER\apvyr_cache"
If (Test-Path $cache_dir) {
    Write-Output "*** Contents of the cache directory: $cache_dir"
    Get-ChildItem $cache_dir
} else {
    Write-Output "*** Creating directory ""$cache_dir""..."
    New-Item -ItemType Directory -Path $cache_dir | out-null
}
$temp_dir = "$env:APPVEYOR_BUILD_FOLDER\apvyr_tmp"
If (-Not (Test-Path $temp_dir)) {
    Write-Output "*** Creating directory ""$temp_dir""..."
    New-Item -ItemType Directory -Path $temp_dir | out-null
}



# temp!!!
Write-Host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -ForegroundColor Magenta
Write-Host "ODBC drivers:" -ForegroundColor Magenta
Get-OdbcDriver
Write-Host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -ForegroundColor Magenta



# Appveyor build servers are always 64-bit and only the 64-bit SQL Server ODBC
# msi files can be installed on them.  However, the 64-bit msi file includes
# both 32-bit and 64-bit drivers.
CheckAndInstallMsiFromUrl `
    -driver_name "ODBC Driver 13 for SQL Server" `
    -driver_bitness "64-bit" `
    -driver_url "https://download.microsoft.com/download/1/E/7/1E7B1181-3974-4B29-9A47-CC857B271AA2/English/X64/msodbcsql.msi" `
    -msifile_path "$cache_dir\msodbcsql_13.0.0.0_x64.msi" `
    -msiexec_paras @("IACCEPTMSODBCSQLLICENSETERMS=YES", "ADDLOCAL=ALL");

CheckAndInstallMsiFromUrl `
    -driver_name "ODBC Driver 17 for SQL Server" `
    -driver_bitness "64-bit" `
    -driver_url "https://download.microsoft.com/download/E/6/B/E6BFDC7A-5BCD-4C51-9912-635646DA801E/en-US/msodbcsql_17.5.1.1_x64.msi" `
    -msifile_path "$cache_dir\msodbcsql_17.5.1.1_x64.msi" `
    -msiexec_paras @("IACCEPTMSODBCSQLLICENSETERMS=YES", "ADDLOCAL=ALL");
    
if ($python_arch -eq "64") {

    CheckAndInstallZippedMsiFromUrl `
        -driver_name "PostgreSQL Unicode(x64)" `
        -driver_bitness "64-bit" `
        -driver_url "https://ftp.postgresql.org/pub/odbc/versions/msi/psqlodbc_09_06_0500-x64.zip" `
        -zipfile_path "$temp_dir\psqlodbc_09_06_0500-x64.zip" `
        -zip_internal_msi_file "psqlodbc_x64.msi" `
        -msifile_path "$cache_dir\psqlodbc_09_06_0500-x64.msi";

    # MySQL 8.0 drivers apparently don't work on Python 2.7 ("system error 126").
    # Note, installing MySQL 8.0 ODBC drivers causes the 5.3 drivers to be uninstalled.
    if ($python_version -eq "2") {
        CheckAndInstallMsiFromUrl `
            -driver_name "MySQL ODBC 5.3 ANSI Driver" `
            -driver_bitness "64-bit" `
            -driver_url "https://dev.mysql.com/get/Downloads/Connector-ODBC/5.3/mysql-connector-odbc-5.3.14-winx64.msi" `
            -msifile_path "$cache_dir\mysql-connector-odbc-5.3.14-winx64.msi";
    } else {
        CheckAndInstallMsiFromUrl `
            -driver_name "MySQL ODBC 8.0 ANSI Driver" `
            -driver_bitness "64-bit" `
            -driver_url "https://dev.mysql.com/get/Downloads/Connector-ODBC/8.0/mysql-connector-odbc-8.0.19-winx64.msi" `
            -msifile_path "$cache_dir\mysql-connector-odbc-8.0.19-winx64.msi";
    }

} elseif ($python_arch -eq "32") {

    CheckAndInstallZippedMsiFromUrl `
        -driver_name "PostgreSQL Unicode" `
        -driver_bitness "32-bit" `
        -driver_url "https://ftp.postgresql.org/pub/odbc/versions/msi/psqlodbc_09_06_0500-x86.zip" `
        -zipfile_path "$temp_dir\psqlodbc_09_06_0500-x86.zip" `
        -zip_internal_msi_file "psqlodbc_x86.msi" `
        -msifile_path "$cache_dir\psqlodbc_09_06_0500-x86.msi";

    # MySQL 8.0 drivers apparently don't work on Python 2.7 ("system error 126").
    # Note, installing MySQL 8.0 ODBC drivers causes the 5.3 drivers to be uninstalled.
    if ($python_version -eq 2) {
        CheckAndInstallMsiFromUrl `
            -driver_name "MySQL ODBC 5.3 ANSI Driver" `
            -driver_bitness "32-bit" `
            -driver_url "https://dev.mysql.com/get/Downloads/Connector-ODBC/5.3/mysql-connector-odbc-5.3.14-win32.msi" `
            -msifile_path "$cache_dir\mysql-connector-odbc-5.3.14-win32.msi";
    } else {
            CheckAndInstallMsiFromUrl `
            -driver_name "MySQL ODBC 8.0 ANSI Driver" `
            -driver_bitness "32-bit" `
            -driver_url "https://dev.mysql.com/get/Downloads/Connector-ODBC/8.0/mysql-connector-odbc-8.0.19-win32.msi" `
            -msifile_path "$cache_dir\mysql-connector-odbc-8.0.19-win32.msi";
    }
} else {
    Write-Output "ERROR: Unexpected Python architecture:"
    Write-Output $python_arch
}



# temp!!!
Write-Host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -ForegroundColor Magenta
Write-Host "Contents of the cache directory: $cache_dir" -ForegroundColor Magenta
Get-ChildItem $cache_dir
Write-Host "Contents of the cache directory: $temp_dir" -ForegroundColor Magenta
Get-ChildItem $temp_dir
Write-Host "Get-Help Start-FileDownload:" -ForegroundColor Magenta
Get-Help Start-FileDownload
Write-Host "ODBC drivers:" -ForegroundColor Magenta
Get-OdbcDriver
Write-Host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -ForegroundColor Magenta
