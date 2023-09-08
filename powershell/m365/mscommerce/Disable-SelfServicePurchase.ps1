<#
.SYNOPSIS
Locate & Disable all self-service-purchase products in MSCommerce
.Description
Locate & Disable all self-service-purchase products in MSCommerce
#>

#Requires -Modules MSCommerce

function Get-Policies {
    $raw = Get-MSCommerceProductPolicies -PolicyId 'AllowSelfServicePurchase'
    $arr = ($raw | Out-String) -split '\r\n' | Where-Object {
        $_ -match '^\s*((Dis|En)abled|OnlyTrials)'
    }

    foreach ($entry in $arr) {
        $fields = $entry -split '\s+', 4
        [PSCustomObject]@{
            PolicyValue = $fields[0]
            ProductId = $fields[1]
            PolicyId = $fields[2]
            ProductName = $fields[3]
        }
    }
}

function Test-PSVersionMajor {
    if ($PSVersionTable.PSVersion.Major -gt 5) {
        throw "PSVersion must be 5.1 or older"
    }
}

filter Disable-Policy {
    $opts = @{
        PolicyId = 'AllowSelfServicePurchase'
        ProductId = $_.ProductId
        Value = 'Disabled'
    }

    Update-MSCommerceProductPolicy @opts
}

Test-PSVersionMajor

Import-Module -Name 'MSCommerce'
Connect-MSCommerce -ErrorAction Stop

Get-Policies | Where-Object {
    $_.PolicyValue -ne 'Disabled'
} | Disable-Policy
