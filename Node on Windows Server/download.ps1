Set-ExecutionPolicy Unrestricted
$runtimeUrl = "http://az413943.vo.msecnd.net/node/0.10.21.exe;http://nodertncu.blob.core.windows.net/iisnode/0.1.21.exe"

$overrideUrl = $args[1]
$current = [string] (Get-Location -PSProvider FileSystem)
$client = New-Object System.Net.WebClient

function downloadWithRetry {
	param([string]$url, [string]$dest, [int]$retry) 
	
    trap {
    	
	    if ($retry -lt 5) {
	    	$retry=$retry+1
	    	
	    	Start-Sleep -s 5
	    	downloadWithRetry $url $dest $retry $client
	    }

	    else {
	    	throw "Max number of retries downloading [5] exceeded" 	
	    }
    }
    $client.downloadfile($url, $dest)
}

function download($url, $dest) {
	downloadWithRetry $url $dest 1
}

function copyOnVerify($file, $output) {
  $verify = Get-AuthenticodeSignature $file
  Out-Host -InputObject $verify
  if ($verify.Status -ne "Valid") {
     throw "Invalid signature for runtime package $file"
  }
  else {
    mv $file $output
  }
}

function installUrlRewrite() {
	$suffix = Get-Random
	$downloaddir = $current + "\sandbox" + $suffix
	mkdir $downloaddir

	$iisrewriteurl = "http://go.microsoft.com/fwlink/?LinkID=615137"
	$outputfileName = "$downloaddir\rewrite_amd64.msi"
	download $iisrewriteurl $outputfileName

	cd $downloaddir
	$Command = "msiexec -i ""rewrite_amd64.msi"" /qn /quiet"
	cmd.exe /c $Command
    
    cd $current
    if (Test-Path -LiteralPath $downloaddir)
    {
        Remove-Item -LiteralPath $downloaddir -Force -Recurse
    }
}

if ($overrideUrl) {
    $url = $overrideUrl
}
else {
	$url = $runtimeUrl
}

foreach($singleUrl in $url -split ";") 
{
    $suffix = Get-Random
    $downloaddir = $current + "\sandbox" + $suffix
    mkdir $downloaddir
    $dest = $downloaddir + "\sandbox.exe"
    download $singleUrl $dest
	
    $final = $downloaddir + "\runtime.exe"
    copyOnVerify $dest $final
    if (Test-Path -LiteralPath $final)
    {
      cd $downloaddir
      if ($host.Version.Major -eq 3)
      {
        .\runtime.exe -y | Out-Null
        .\setup.cmd
      }
      else
      {
        Start-Process -FilePath $final -ArgumentList -y -Wait 
        $cmd = $downloaddir + "\setup.cmd"
        Start-Process -FilePath $cmd -Wait
      }
    }
    else
    {
      throw "Unable to verify package"
    }



    cd $current
    if (Test-Path -LiteralPath $downloaddir)
    {
        Remove-Item -LiteralPath $downloaddir -Force -Recurse
    }
}

installUrlRewrite

