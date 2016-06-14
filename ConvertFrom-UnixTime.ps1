function ConvertFrom-UnixTime 
{
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Int32]
        $UnixTime
    )
    begin {
        $startdate = Get-Date -Date '01/01/1970' 
    }
    process {
        $timespan = New-TimeSpan -Seconds $UnixTime
        $startdate + $timespan
    }
}