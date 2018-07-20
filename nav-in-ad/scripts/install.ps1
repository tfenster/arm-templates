param
(
    [Parameter(Mandatory)]
    [String]$PerfshareKey,

    [Parameter(Mandatory)]
    [String]$IsServer
)

# mount share with install and update files
net use X: \\perfshare.file.core.cloudapi.de\share /user:perfshare $PerfshareKey

# copy files and extract DVD
mkdir d:\install_newsystem
Copy-Item x:\install\* d:\install_newsystem
start-process -FilePath "D:\install_newsystem\NAV*DVD.exe" -ArgumentList "-y" -NoNewWindow -Wait

# install .NET 3.5
Enable-WindowsOptionalFeature -FeatureName NetFx3 -All -Online -Source D:\install_newsystem

# install newsystem
Set-Location D:\install_newsystem\NAV*DVD
$install = ".\setup.exe "
$ConfigFileName = "Config_Client.xml"
$MspFilter = "*RTC*.msp"
if ($IsServer -eq 'True') {
    $ConfigFileName = "Config_Server.xml"
    $MspFilter = "*.msp"
}
start-process -FilePath $install -ArgumentList "/config d:\install_newsystem\$ConfigFileName /quiet" -NoNewWindow -Wait

# update newsystem
if ($IsServer -eq 'True') {
    Import-Module 'C:\Program Files\Microsoft Dynamics NAV\100\Service\Microsoft.Dynamics.Nav.Management.psm1'
    Set-NAVServerInstance DynamicsNAV100 -Stop
}
Get-ChildItem "D:\install_newsystem" -Filter $MspFilter | Sort-Object -Property Name | ForEach-Object {
    $msp = $_.FullName
    Start-Process "msiexec" -ArgumentList "/update `"$msp`" /quiet" -NoNewWindow -Wait
}
