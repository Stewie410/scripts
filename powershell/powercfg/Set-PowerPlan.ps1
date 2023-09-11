<#
.SYNOPSIS
Change the active power plan

.Description
Change active power plan by Name, Alias, Guid or selecting from available plans.

.PARAMETER Name
Select and apply a power plan by the localized name (regex)

.PARAMETER Alias
Select and apply a power plan by the alias (regex)

.PARAMETER Guid
Select and apply a power plan by the Guid (exact)

.NOTE
Heavily inspired by:

    - https://stackoverflow.com/a/61121407
    - https://www.reddit.com/r/windows/comments/16ewnpq/script_quickly_change_power_plan_with_1_press_of/
#>

using namespace System.Management.Automation.Host

[CmdletBinding(DefaultParameterSetName = 'Default')]
param (
    [Parameter(Mandatory, ParameterSetName = 'ByName')]
    [string]
    $Name,

    [Parameter(Mandatory, ParameterSetName = 'ByAlias')]
    [string]
    $Alias,

    [Parameter(Mandatory, ParameterSetName = 'ByGuid')]
    [string]
    $Guid
)

function Get-PowerAliases {
    $map = @{}

    powercfg.exe -Aliases | Where-Object {
        $_ -like '*SCHEME_*'
    } | ForEach-Object {
        $guid,$alias = ($_ -split '\s+', 2).Trim()
        $map[$guid] = $alias
    }

    return $map
}

function Get-PowerSchemes {
    $aliases = Get-PowerAliases

    powercfg.exe -List | Where-Object {
        $_ -match '^Power Scheme'
    } | ForEach-Object {
        $guid,$name = (($_ -replace '^[^:]*?:\s*') -split '\s+', 2).Trim()

        [PSCustomObject]@{
            Name = $name.Trim('*') -replace '^\((.*)\)$', '$1'
            Alias = $aliases[$guid]
            Guid = $guid
            IsActive = $_ -match '\*\s*$'
        }
    }
}

function Get-SchemeChoice {
    param($list)

    $choices = @()

    for ($i = 0; $i -lt $list.Count; $i++) {
        $choices += @([ChoiceDescription]::new(
            '&' + $i + ' ' + $list[$i].Name,
            $list[$i].Name
        ))
    }

    $result = $HOST.UI.PromptForChoice(
        "Power Plan",
        "Select power plan to apply:",
        $choices,
        -1
    )

    if ($result -eq -1) {
        throw "No scheme selected"
    }

    return $list[$result]
}

function Set-PowerScheme {
    param($scheme)

    powercfg.exe -SetActive $scheme.Guid
    $current = ((powercfg.exe -GetActiveScheme) -split '\s+')[3]

    if ($scheme.Guid -ne $current) {
        throw "Failed to apply scheme: $($scheme.Name) ($($Scheme.Guid))"
    }
}

function Invoke-Main {
    $schemes = Get-PowerSchemes

    if ($Name) {
        $plan = $schemes | Where-Object {
            $_.Name -match $Name
        } | Select-Object -First 1
    } elseif ($Alias) {
        $plan = $schemes | Where-Object {
            $_.Alias -match $Alias
        } | Select-Object -First 1
    } elseif ($Guid) {
        $plan = $schemes | Where-Object {
            $_.Guid -eq $Guid
        }
    } else {
        $plan = Get-SchemeChoice $schemes
    }

    if (!($plan)) {
        throw "Unable to determine desired plan"
    }

    Set-PowerScheme $plan
}

Invoke-Main
