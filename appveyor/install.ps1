# check that all the necessary ODBC drivers are available, if not install any missing ones

Function CheckAndInstallMsiFromUrl ($driver_name, $driver_bitness, $driver_url, $msifile_path) {
    # check whether the driver is already installed
    if ($d = Get-OdbcDriver -Name $driver_name -Platform $driver_bitness -ErrorAction:SilentlyContinue) {
        Write-Output "*** Driver ""$driver_name"" ($driver_bitness) already installed: $($d.Attribute.Driver)"
        return
    } else {
        Write-Output "*** Driver ""$driver_name"" ($driver_bitness) not found"
    }
    Write-Output "Downloading the driver's msi file..."
    #if (-Not (Start-FileDownload $driver_url -FileName $msifile_path -ErrorAction:SilentlyContinue)) {
    Start-FileDownload $driver_url -FileName $msifile_path
    if (!$?) {
        Write-Output "ERROR: Could not download the msi file from $driver_url"
        return
    }
    Write-Output "Installing driver..."
    if (-Not (msiexec /i $msifile_path /qn -ErrorAction:SilentlyContinue)) {
        Write-Output "ERROR: Driver installation failed"
        return
    }
    Write-Output "...driver installed successfully"
}

Function CheckAndInstallZippedMsiFromUrl ($driver_name, $driver_bitness, $driver_url, $zipfile_path, $zip_internal_msi_file, $msifile_path) {
    # check whether the driver is already installed
    if ($d = Get-OdbcDriver -Name $driver_name -Platform $driver_bitness -ErrorAction:SilentlyContinue) {
        Write-Output "*** Driver ""$driver_name"" ($driver_bitness) already installed: $($d.Attribute.Driver)"
        return
    } else {
        Write-Output "*** Driver ""$driver_name"" ($driver_bitness) not found"
    }
    Write-Output "Downloading the driver's zip file..."
    #-ErrorAction:SilentlyContinue
    if (-Not (Start-FileDownload $driver_url -FileName $zipfile_path)) {
        Write-Output "ERROR: Could not download the zip file from $driver_url"
        return
    }
    Write-Output "Unzipping..."
    Expand-Archive -Path $zipfile_path -DestinationPath $temp_dir
    Copy-Item -Path $temp_dir\$zip_internal_msi_file -Destination $msifile_path -Force
    Write-Output "Installing driver..."
    if (-Not (msiexec /i $msifile_path /qn -ErrorAction:SilentlyContinue)) {
        Write-Output "ERROR: Driver installation failed"
        return
    }
    Write-Output "...driver installed successfully"
}


# create directories
$cache_dir = "$env:APPVEYOR_BUILD_FOLDER\apvyr_cache"
If (-Not (Test-Path $cache_dir)) {
    Write-Output "Creating directory ""$cache_dir""..."
    New-Item -ItemType Directory -Path $cache_dir | out-null
}
$temp_dir = "$env:APPVEYOR_BUILD_FOLDER\apvyr_tmp"
If (-Not (Test-Path $temp_dir)) {
    Write-Output "Creating directory ""$temp_dir""..."
    New-Item -ItemType Directory -Path $temp_dir | out-null
}


CheckAndInstallZippedMsiFromUrl `
    -driver_name "PostgreSQL Unicode" `
    -driver_bitness "32-bit" `
    -driver_url "https://ftp.postgresql.org/pub/odbc/versions/msi/psqlodbc_09_06_0500-x86.zip" `
    -zipfile_path "$temp_dir\psqlodbc_09_06_0500-x86.zip" `
    -zip_internal_msi_file "psqlodbc_x86.msi" `
    -msifile_path "$cache_dir\psqlodbc_09_06_0500-x86.msi";

CheckAndInstallZippedMsiFromUrl `
    -driver_name "PostgreSQL Unicode(x64)" `
    -driver_bitness "64-bit" `
    -driver_url "https://ftp.postgresql.org/pub/odbc/versions/msi/psqlodbc_09_06_0500-x64.zip" `
    -zipfile_path "$temp_dir\psqlodbc_09_06_0500-x64.zip" `
    -zip_internal_msi_file "psqlodbc_x64.msi" `
    -msifile_path "$cache_dir\psqlodbc_09_06_0500-x64.msi";

CheckAndInstallMsiFromUrl `
    -driver_name "MySQL ODBC 5.3 ANSI Driver" `
    -driver_bitness "32-bit" `
    -driver_url "https://dev.mysql.com/get/Downloads/Connector-ODBC/5.3/mysql-connector-odbc-5.3.14-win32.msi" `
    -msifile_path "$cache_dir\mysql-connector-odbc-5.3.14-win32.msi";

CheckAndInstallMsiFromUrl `
    -driver_name "MySQL ODBC 5.3 ANSI Driver" `
    -driver_bitness "64-bit" `
    -driver_url "https://dev.mysql.com/get/Downloads/Connector-ODBC/5.3/mysql-connector-odbc-5.3.14-winx64.msi" `
    -msifile_path "$cache_dir\mysql-connector-odbc-5.3.14-winx64.msi";

CheckAndInstallMsiFromUrl `
    -driver_name "MySQL ODBC 8.0 ANSI Driver" `
    -driver_bitness "32-bit" `
    -driver_url "https://dev.mysql.com/get/Downloads/Connector-ODBC/8.0/mysql-connector-odbc-8.0.19-win32.msi" `
    -msifile_path "$cache_dir\mysql-connector-odbc-8.0.19-win32.msi";

CheckAndInstallMsiFromUrl `
    -driver_name "MySQL ODBC 8.0 ANSI Driver" `
    -driver_bitness "64-bit" `
    -driver_url "https://dev.mysql.com/get/Downloads/Connector-ODBC/8.0/mysql-connector-odbc-8.0.19-winx64.msi" `
    -msifile_path "$cache_dir\mysql-connector-odbc-8.0.19-winx64.msi";


# temp!!!
Get-ChildItem $temp_dir
Get-ChildItem $cache_dir