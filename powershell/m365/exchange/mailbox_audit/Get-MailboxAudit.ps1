<#
.SYNOPSIS
Query E365 Mailbox Audit Logs

.DESCRIPTION
Query E365 Mailbox Audit Logs

.PARAMETER Identity
Specify the mailbox/identity to be queried

.PARAMETER StartDate
Include actions from this date

.PARAMETER EndDate
Exclude actions newer than this date (default: today)

.PARAMETER MaxCount
Maximum number of results to return from the log (1 to 250000)

.PARAMETER Subject
Filter results by subject field

.PARAMETER ExcludeFolderBind
Exclude folder-bind operations from results
#>

#Requires -Module ExchangeOnlineManagement

[CmdletBinding(DefaultParameterSetName = 'Default')]
param (
    [Parameter(Mandatory, ValueFromPipeline)] [string] $Identity,
    [Parameter(Mandatory)] [string] $StartDate,
    [Parameter()] [string] $EndDate = (Get-Date -UFormat '+%F'),
    [Parameter()] [string] $Subject,
    [Parameter()] [int] $MaxCount = 250000,
    [Parameter()] [switch] $ExcludeFolderBind
)

BEGIN {
    function Get-ExchangeConnection {
        Get-ConnectionInformation | Where-Object {
            $_.Name -match 'ExchangeOnline' -and $_.TokenStatus -eq 'Active'
        }
    }

    [string[]] $LogParameters = @(
        'Operation',
        'LogonUserDisplayName',
        'LastAccessed',
        'DestFolderPathname',
        'FolderPathName',
        'ClientInfoString',
        'ClientIPAddress',
        'ClientMachineName',
        'ClientProcessName',
        'ClientVersion',
        'LogonType',
        'MailboxResolivedOwnerName',
        'OperationResult'
    )

    if (!(Get-ExchangeConnection)) {
        Connect-ExchangeOnline -ErrorAction Stop
    }
}

PROCESS {
    function Get-ShortDate {
        param([string]$date)

        $datetime = [DateTime] $date
        $format = (Get-Culture).DateTimeFormat.ShortDatePattern

        Get-Date -Date $datetime -Format $format
    }

    function Get-AuditLogs {
        $opts = @{
            Identity = $Identity
            StartDate = Get-ShortDate $StartDate
            EndDate = Get-ShortDate $EndDate
            ShowDetails = $True
            ResultSize = $ResultSize
            LogonTypes = @('Owner', 'Admin', 'Delegate')
        }

        $results = @(Search-MailboxAuditLog @opts)

        if ($ExcludeFolderBind) {
            $results = @($results | Where-Object {
                $_.Operation -notlike 'FolderBind'
            })
        }

        return $results
    }

    function Select-AuditLogs {
        param($audits)

        $logs = @(
            $audits | Select-Object ($LogParameters + @{
                Name = 'Subject'
                e = {
                    if (($_.SourceItems.Count -eq 0) -or ($null -eq $_.SourceItems.Count)) {
                        $_.ItemSubject
                    } else {
                        ($_.SourceItems[0].SourceItemSubject).TrimStart(' ')
                    }
                }
            },
            @{
                Name = 'CrossMailboxOp'
                e = {
                    if (@('SendAs', 'Create' 'Update') -contains $_.Operation) {
                        ''
                    } else {
                        $_.CrossMailboxOperation
                    }
                }
            })
        )

        if (!([string]::IsNullOrEmpty($Subject))) {
            $logs = @($logs | Where-Object {
                $_.Subject -match $Subject
            })
        }

        return $logs
    }

    if (!(Get-Mailbox -Identity $Identity)) {
        Write-Error -Message "Cannot locate mailbox: $Identity"
    }

    $searchResults = Select-AuditLogs (Get-AuditLogs)
    $logParameters = @('Subject') + $LogParameters + @('CrossMailboxOp')
    $searchResults | Select-Object $LogParameters
}
