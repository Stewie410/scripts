<#
.SYNOPSIS
Get a list of all mapped drives

.DESCRIPTION
Get a list of all mapped drives

.NOTES
See New-PSDrive & CredentialManager module to map drives
https://stackoverflow.com/a/67303653
https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/new-psdrive?view=powershell-7.3
#>

function Invoke-Main {
	Get-PSDrive | Where-Object {
		$_.Root.StartsWith('\\')
	}
}

Invoke-Main