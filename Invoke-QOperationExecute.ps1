function Invoke-QOperationExecute
{
    [CmdletBinding()]
	
    Param
    (
        # Path to commvault base directory
        [Parameter(Mandatory = $true,
				   
        Position = 0)]
        [string]
        $Path = $(if (!(Test-Path ($Path = "$env:ProgramFiles\Commvault\Simpana\Base")))
            {
                do
                {
                    "Unable to validate $Path. Please enter a valid path to Commvault's Base directory" | Out-Default
                    $Result = Read-Host -Prompt 'Commvault Base Path:'
                }
                while (!(Test-Path $Result))
                $Path = $Result
                $Path
            }
            else
            {
                $Path
            }
        ),
		
        # Param2 help description
        [Parameter(Mandatory = $true,
                valuefrompipeline = $true,
        Position = 1)]
        [System.Xml.XmlDocument[]]
        $CVXML,
		
        # Param3 help description
        [Parameter(Mandatory = $true,
				   
        Position = 2)]
        [string]
        $CVToken
		
		
    )
	
    Begin
    {
		
		
    }
    Process
    {
		
        $Tempfile = New-Item -Name CVXMLTemp.xml -Path $env:temp -ItemType file
        $CVXML.save($Tempfile)
		
        & "$Path\Qoperation.exe" execute -af $Tempfile -tk $CVToken
		
		
		
		
		
    }
    End
    {
		
        $null = $Tempfile |
        Remove-Item -Force
    }
}