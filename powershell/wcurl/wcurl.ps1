<#
.SYNOPSIS
A simple wrapper around curl to easily download files

.DESCRIPTION
A powershell port of curl's "wcurl" script

.PARAMETER CurlOptions
Specify extra options to be passed when invoking curl. Any option supported by
wcurl can be set here.

See curl.exe --help for more information

.PARAMETER Output
Use the provided output path instead of getting it from the URL.
If multiple URLs are provided, resulting files share the same name with a number
appended to the end (curl >= 7.83.0).

.PARAMETER NoDecodeFilename
Don't percent-decode the output filename, even if the percent-encoding in the
URL was done by wcurl, e.g.: The URL contained whitespace

.PARAMETER URL
URL to be downloaded. Anything that is not a parameter is considered a URL.
Whitespaces are percent-encoded and the URL is passed to curl, which then
performs the parsing.

.EXAMPLE
PS> wcurl.ps1 'https://some/file.txt'
PS> 'https://some/file.txt' | wcurl.ps1
Download the file hosted at "https://some/file.txt", write to ".\file.txt"

.EXAMPLE
PS> wcurl.ps1 @('https://site/a.txt','https://site/b.txt')
PS> wcurl.ps1 'https://site/a.txt' 'https://site/b.txt'
PS> 'https://site/a.txt','https://site/b.txt' | wcurl.ps1
Download the "a.txt" & "b.txt" files hosted at "https://site" to ".\a.txt" & ".\b.txt"

.EXAMPLE
PS> wcurl.ps1 $urls -Output 'foo.txt'
Download the files in $urls, saving as '.\foo.txt'.  If curl.exe at least
v7.83.0, append 'N' to the filename, indicating index of each url->file

.INPUTS
System.String[]

.NOTES
Version:        0.0.1
BasedOn:        wcurl-2025.05.05+dev
Author:         stewie410
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
    [string[]]
    $UrlList,

    [Parameter()]
    [string[]]
    $CurlOptions = @(),

    [Alias("O")]
    [Parameter()]
    [AllowEmptyString]
    [AllowNull]
    [string]
    $Output,

    [Parameter()]
    [switch]
    $NoDecodeFilename,

    [Parameter(ValueFromRemainingArguments)]
    [string[]]
    $Remaining
)

BEGIN {
    function Get-OptionSupport {
        $version = [version] (& curl.exe --version).Split('\n')[0].Split(' ')[1]
        return @{
            NoClobber = $version -ge ([version] '7.83.0')
            Parallel  = $version -ge ([version] '7.66.0')
        }
    }

    $arglist = @()

    Write-Debug "Append Remaining arguments to UrlList"
    $UrlList += $Remaining

    $supports = Get-OptionSupport
    Write-Debug "curl.exe --parallel: $($supports.Parallel)"
    Write-Debug "curl.exe --no-clobber: $($supports.NoClobber)"

    $user_output = (-not [string]::IsNullOrEmpty($Output))

    $per_url = @(
        "--fail",
        "--globoff",
        "--location",
        "--proto-default", "https",
        "--remote-time",
        "--retry", "5"
    )

    if ($supports.NoClobber) {
        $per_url += @( "--no-clobber" )
    }

    Write-Debug "Per-URL options: $($per_url -join ' ')"

    $url_count = 0
}

PROCESS {
    function Get-UrlFilename {
        param([string] $link)

        try {
            $name = ([uri] $link).Segments[-1]
        }
        catch {
            Write-Warning "Cannot determine filename for URL: $link"
            Write-Verbose "Using default filename: $link -> index.html"
            $name = 'index.html'
        }

        if ([string]::IsNullOrEmpty($name) -or ('/' -eq $name)) {
            Write-Warning "Failed to determine filename for URL: $link"
            Write-Verbose "Using default filename: $link -> index.html"
            $name = 'index.html'
        }

        if ($NoDecodeFilename) {
            Write-Verbose "Use Percent-Encoded Filename: $name"
            return $name
        }

        return [System.Web.HttpUtility]::UrlDecode($name)
    }

    foreach ($item in $UrlList) {
        if ($url_count -gt 0) {
            $arglist += @( "--next" )
        }

        $outfile = if ($user_output) { $Output } else { Get-UrlFilename $item }

        $item_opts = $per_url + $CurlOptions + @( "--output", $outfile, $item )
        Write-Verbose "Add to arguments: $item -> $outfile"
        Write-Debug "Add Options: $($item_opts -join ' ')"

        $arglist += $item_opts
        $url_count++
    }
}

END {
    if ($url_count -gt 1 -and $supports.Parallel) {
        Write-Debug "Prepend --parallel to arguments"
        $arglist = @( "--parallel" ) + $arglist
    }

    $opts = @{
        FilePath     = "$env:WINDIR\System32\curl.exe"
        ArgumentList = $arglist
        Wait         = $True
        NoNewWindow  = $True
        ErrorAction  = $ErrorActionPreference
    }

    if ($PSCmdlet.ShouldProcess("curl.exe $($opts.ArgumentList -join ' ')")) {
        Start-Process @opts
    }
}
