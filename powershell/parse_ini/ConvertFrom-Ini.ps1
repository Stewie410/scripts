<#
.SYNOPSIS
Parse INI file to PSObject

.DESCRIPTION
Parse INI ifle to PSObject

.PARAMETER Path
Path to the INI file

#>

[CmdletBinding(DefaultParameterSetName = 'Default')]
param(
	[ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
	[Parameter(Mandatory)]
	[string]
	$Path
)

function Invoke-Main {
	$ini = @{}

	switch -regex -file $Path {
		# Section Header
		'^\s*\[(.+)\]\s*$' {
			$section = $Matches[1]
			$ini[$section] = [PSCustomObject]@{
				Comments = @()
			}
		}

		# Comment
		'\s*;+(.+)$' {
			$ini[$section].Comments += $Matches[1].Trim()
		}

		# Key-Value Pair
		'^([^=]+?)=(.*)$' {
			$member = @{
				InputObject = $ini[$section]
				MemberType = 'NoteProperty'
				Name = $Matches[1].Trim()
				Value = $Matches[2].Trim()
				Force = $True
			}

			Add-Member @member
		}
	}

	return $ini
}

Invoke-Main