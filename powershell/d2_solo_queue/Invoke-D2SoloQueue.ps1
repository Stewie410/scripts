<#
.SYNOPSIS
Toggle matchmaking port access for Destiny 2

.DESCRIPTION
Get, set or toggle matchmaking port access for Destiny 2

.PARAMETER Enable
Ensure matchmaking is enabled

.PARAMETER Disable
Ensure matchmaking is disabled

.PARAMETER Toggle
Toggle matchmaking state

.PARAMETER GamePath
Specify the absolute path to "destiny2.exe

#>

#Requires -RunAsAdministrator

[CmdletBinding(DefaultParameterSetName = 'Default')]
param(
	[Parameter(Mandatory, ParameterSetName = 'Enable')]
	[switch]
	$Enable,

	[Parameter(Mandatory, ParameterSetName = 'Disable')]
	[swtich]
	$Disable,

	[Parameter(Mandatory, ParameterSetName = 'Toggle')]
	[switch]
	$Toggle,

	[ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
	[Parameter(Mandatory)]
	[string]
	$GamePath
)

function Get-DestinyRules {
	$list = @(Get-NetFirewallRule | Where-Object {
		$_.DisplayName -match 'D2SoloQueue'
	})

	foreach ($i in @('Out', 'In')) {
		foreach ($j in @('TCP', 'UDP')) {
			$rule = @{
				DisplayName = "D2SoloQueue-$i-$j"
				Description = "Block Destiny's matchmaking connection(s) ($i`: $j)"
				Program = $GamePath
				Direction = $i
				RemotePort = @('27000-27200', '3097')
				Protocol = $j
				Action = 'Allow'
				Enabled = 'False'
			}

			if (!($list.Displayname -contains $rule.DisplayName)) {
				$list += New-NetFirewallRule @rule
			}
		}
	}

	return $list
}

function Test-ToEnable {
	param($list)

	if (($Enable) -or (($Toggle) -and ($list[0].Enabled -eq 'False'))) {
		return $True
	}

	return $False
}

function Test-ToDisable {
	param($list)

	if (($Disable) -or (($Toggle) -and ($list[0].Enabled -eq 'True'))) {
		return $True
	}

	return $False
}

function Invoke-Main {
	$rules = Get-DestinyRules

	if (Test-ToEnable $rules) {
		$rules = $rules | Enable-NetFirewallRule
	} elseif (Test-ToDisable $rules) {
		$rules = $rules | Disable-NetFirewallRule
	}

	return $rules
}

Invoke-Main