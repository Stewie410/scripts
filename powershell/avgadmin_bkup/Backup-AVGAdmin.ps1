<#
.SYNOPSIS
Backup AVG Admin Server
.Description
Locate and transmit automatic AVG Data Expot files to an archive server (scp)
If no backup for the current date is located, exit with a failure-state
.PARAMETER Date
Specify the date of backups to look for
.PARAMETER SourceDir
Absolute path to AVG's Data Export parent directory
(default: $env:PROGRAMDATA\AVG\Admin Server Data\AutoDatabaseBackup)
.PARAMETER SSHConnection
Specify the the 'user@host' SSH Connection string for destination server
.PARAMETER SSHPath
Specify the backup location on the archive server
#>

[CmdletBinding(DefaultParameterSetName = 'Default')]
param (
    [Parameter()][DateTime]$Date = (Get-Date),
    [Parameter()][string]$SourceDir = "$env:PROGRAMDATA\AVG\Admin Server Data\AutoDatabaseBackup",
    [Parameter(Mandatory)][string]$SSHConnection,
    [Parameter(Mandatory)][string]$SSHPath
)

function Write-Log {
    [CmdletBinding(DefaultParameterSetName = 'Options')]
    param(
        [Parameter(Mandatory = $True, ParameterSetName = "Info")]
        [switch]$Info,

        [Parameter(Mandatory = $True, ParameterSetName = "Warn")]
        [switch]$Warn,

        [Parameter(Mandatory = $True, ParameterSetName = "Error")]
        [switch]$Error,

        [Parameter(Mandatory = $False, ParameterSetName = "Error")]
        [switch]$Throw,

        [Parameter(Mandatory = $True, ParameterSetName = "Debug")]
        [switch]$Debug,

        [Parameter(Mandatory = $True, ParameterSetName = "Verb")]
        [switch]$Verb,

        [Parameter(Mandatory = $True, ValueFromPipeline = $True, Position = 0)]
        [string]$Message,

        [Parameter(Mandatory = $False)]
        [switch]$Append
    )

    BEGIN {
        $parts = @{
            Time = Get-Date -UFormat '+%FT%T%Z'
            Level = (
                if ($Info) {
                    'info'
                } elseif ($Warn) {
                    'warn'
                } elseif ($Error) {
                    'error'
                } elseif ($Debug) {
                    'debug'
                } elseif ($Verb) {
                    'verbose'
                } else {
                    ""
                }
            )
            Caller = (Get-PSCallStack[1])
        }

        if ($parts.Caller -match 'ScriptBlock') {
            $parts.Caller = Split-Path -Path $PSCommandPath -Leaf
        }

        if (!(Get-Variable -Name 'LogFile' -ErrorAction SilentlyContinue)) {
            $LogFile = $null
        }
    }

    PROCESS {
        $full = ($parts.Values -join '|') + '|' + $Message
        $short = ($full -split '|' | Select-Object -Last 3) -join '|'

        if ($Append) {
            Add-Content -Path $LogFile -Value $full
        }

        switch ($parts.Level) {
            'info' {
                Write-Host $short
            }
            'warn' {
                Write-Warning -Message $short
            }
            'error' {
                Write-Error -Message $short -ErrorAction Continue
                if ($Throw) {
                    throw $short
                }
            }
            'debug' {
                Write-Debug -Message $short
            }
            'verbose' {
                Write-Verbose -Message $short
            }
        }
    }

    END {}
}

function New-LogFile {
    $basename = (Split-Path -Path $PSCommandPath -Leaf) -Replace '\.ps1$', ''
    $params = @{
        Path = Join-Path -Path $env:SYSTEMDRIVE -ChildPath 'logs'
        ItemType = 'File'
        Name = "$basename.log"
        Force = $True
        ErrorAction = 'Ignore'
    }
    New-Item @params
}

function Test-Environment {
    if (!(Test-Path -Path $SourceDir)) {
        Write-Log "Cannot locate source path: $SourceDir" -Error -Throw -Append
    }

    for ($exe in @('ssh.exe', 'scp.exe')) {
        if (!(Get-Command -Name $exe -ErrorAction SilentlyContinue)) {
            Write-Log "Missing required application: $exe" -Error -Throw -Append
        }
    }

    $cname = $SSHConnection.Substring($SSHConnection.LastIndexOf("@") + 1)
    if (!(Test-Connection -ComputerName $cname -Quiet -Count 1)) {
        Write-Log "Cannot ping remote host: $cname" -Warn -Append
    }

    ssh -o 'PreferredAuthentications=publickey' $SSHConnection "true" 2>&1 | Out-Null
    if ([System.Convert]::ToBoolean($LASTEXITCODE)) {
        Write-Log "Unable to authenticate (pubkey) to remote host: $SSHConnection" -Error -Throw -Append
    }

    ssh $SSHConnection "mkdir --parents '$SSHPath'" 2>&1 | Out-Null
}

function Backup-AVGExports {
    $exports = Get-ChildItem -Path "$SourceDir" -Filter "$Date*" -Directory
    $prefix = $SSHConnection + ':' + $SSHPath + '/' + $Date
    $err = 0

    for ($i = 0; $i -lt $exports.Length; $i++) {
        $local = (Get-ChildItem -Path $exports[$i].FullName -File)[0].FullName
        $remote = "$prefix.$i.$($local.Substring($local.LastIndexOf('.') + 1))"

        scp -v -p -q "$local" "$remote" 2>&1 >> "$LogFile"
        if ([System.Convert]::ToBoolean($LASTEXITCODE)) {
            Write-Log "Failed to archive file: $local -> $remote" -Error -Append
            $err++
        }
    }

    if ($err -gt 0) {
        throw "Failed to archive one or more files: $SourceDir\$Date*\*.dce"
    }
}

function Invoke-Main {
    if ($SSHPath.LastIndexOf('/') -eq ($SSHPath.Length - 1)) {
        $SSHPath = $SSHPath -replace '/$', ''
    }

    try {
        Test-Environment
    } catch {
        return 1
    }

    return 0
}

[string] $LogFile = (New-LogFile).FullName

Invoke-Main
