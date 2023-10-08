<#
.SYNOPSIS
Download & Install Winget

.DESCRIPTION
If "winget.exe" is not in $PATH, downloads & install the latest version & its dependencies

.NOTES
See "WingetSandbox.ps1" if you want to permanently add WingetCLI to Windows-Sandbox
https://gist.github.com/Trenly/3e8ba9a9498c6cc12a9bb25e4179a98c

Additionally, to test a manifest in Windows-Sandbox, please see "SandboxTest.ps1" from winget-pkgs
https://github.com/microsoft/winget-pkgs/blob/master/Tools/SandboxTest.ps1

#>

function New-TemporaryDirectory {
	parent = [System.IO.Path]::GetTempPath()
	name = [System.Guid]::NewGuid().Guid
	New-Item -ItemType 'Directory' -Path (Join-Path -Path parent -ChildPath name)
}

function Write-ProgressUpdate {
	param([string]$Message)
	Write-Progress -Activity 'Installing Winget CLI' -Status $Message
	Set-Variable -Name 'ProgressPreference' -Value 'SilentlyContinue'
}

function Test-WingetAvailable {
	if (Get-Command -Name 'winget.exe' -ErrorAction SilentlyContinue) {
		return $True
	}

	return $False
}

function Test-IsOnline {
	if (Test-Connection -ComputerName '8.8.8.8' -Quiet) {
		return $True
	}

	return $False
}

function Get-LatestWingetUri {
	$uri_opts = @{
		Method = 'Get'
		Uri = 'https://api.github.com/repos/microsoft/winget-cli/releases/latest'
		ErrorAction = 'Stop'
	}

	(Invoke-RestMethod @uri_opts).assets.browser_download_url | Where-Object {
		$_.EndsWith('.msixbundle')
	}
}

function Get-AppxFile {
	param([string]$Uri, [string]$Path = "")

	$stage = New-TemporaryDirectory
	Push-Location -Path $Stage.FullName

	$file = '.\' + $Uri.Split('/')[-1]
	Invoke-WebRequest -Uri $Uri -OutFile $file
	$item = Get-Item -Path $file

	if (!([string]::IsNullOrEmpty($Path))) {
		Move-Item -Path $file -Destination "$file.zip"
		Expand-Archive -Path $file -Force
		$item = Get-ChildItem -Path "$file\$Path" -Filter '*.appx' | Select-Object -First 1
		$item = Move-Item -Path $item -Destination (Join-Path -Path $Stage -ChildPath $item.Name) -PassThru
	}

	$item = Move-Item -Path $item.FullName -Destination (Split-Path -Path $stage -Parent | Join-Path -ChildPath $item.Name) -PassThru
	Pop-Location

	Remove-Item -Path $stage -Recurse -Force
	return $item
}

function Install-Dependencies {
	$dependencies = @(
		[PSCustomObject]@{
			name = 'Microsoft.UI.XAML'
			uri = 'https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml'
			path = 'tools\AppX\x64\Release'
			item = $null
		},
		[PSCustomObject]@{
			name = 'VCLibs x64 v14.00'
			uri = 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx'
			path = ""
			item = $null
		}
	)

	foreach ($d in $dependencies) {
		Write-ProgressUpdate ('Downloading Dependency: ' + $d.name)
		$d.item = Get-AppxFile $d.uri $d.path
	}

	foreach ($d in $dependencies) {
		Write-ProgressUpdate ('Installing Dependency: ' + $d.name)
		try {
			Add-AppxPackage -Path $d.item.FullName -ErrorAction Stop
		} catch {}
		Remove-Item -Path $d.item.FullName -Force
	}
}

function Install-WingetCli {
	Write-ProgressUpdate 'Downlading: Winget-CLI'
	$appx = Get-AppxFile (Get-LatestWingetUri)

	Write-ProgressUpdate "Installing: Winget-CLI"
	try {
		Add-AppxPackage -Path $appx.FullName -ErrorAction Stop
	} catch {}
	Remove-Item -Path $appx.FullName -Force
}

function Invoke-Main {
	if (Test-WingetAvailable) {
		return
	} elseif (!(Test-IsOnline)) {
		Write-Error -Message "Must be connected to the internet to download/install Winget-CLI" -ErrorAction Stop
	}

	Install-Dependencies
	Install-WingetCli
}

Invoke-Main