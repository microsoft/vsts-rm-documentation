Set-ExecutionPolicy Unrestricted

if(Get-Website -Name "Default Web Site")
{
    Remove-WebSite -Name "Default Web Site"
}

if(Get-Website -Name "NodeApp")
{
	Remove-WebSite -Name "NodeApp"
}

if(Test-Path "IIS:\AppPools\NodeAppPool")
{
  Remove-WebAppPool "NodeAppPool"
}

New-WebAppPool NodeAppPool -Force
Start-WebAppPool -Name NodeAppPool

New-WebSite -Name NodeApp -Port 80 -PhysicalPath "$env:systemdrive\NVM" -ApplicationPool NodeAppPool  -Force
Start-WebSite -Name "NodeApp"