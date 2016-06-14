function Set-CVMAOfflineForMaintenance
{
    [CmdletBinding()]
    [OutputType([int])]
    param
    (
		
		
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('conn')]
        [System.Data.SqlClient.SQLConnection]
        $SQLConnection,
		
        # <!<SnippetParam1Help>!>
        [Parameter(Mandatory = $true,
                ValueFromPipeline = $true,
        Position = 0)]
        [Alias('cn')]
        [string[]]
        $ComputerName,
		
        # <!<SnippetParam2Help>!>
        [Parameter(Mandatory = $true)]
        [ValidateSet('enable', 'disable')]
        [Alias('opt')]
        [string]
        $MaintenanceOpt
    )
	
	
    begin
    {
		
		
        #convert operation type to 1 or 0 for QS_setMediaAgentProperty SP.
        #param2 = 8 is the option to set media agent offline for maintenance
        [int]$MaintenanceOptInt = if ($MaintenanceOpt -eq 'enable')
        {
            1
        }
        else
        {
            0
        }
		
    }#end begin block
	
    process
    {
		
		
        $QS_SetMediaAgentProperty = @"

							USE [$Database]
						
							DECLARE @RC int
							DECLARE @PARAM1 varchar(1024)
							DECLARE @PARAM2 varchar(1024)
							DECLARE @PARAM3 varchar(1024)

							Set @PARAM1 = `'$ComputerName`'
							SET @PARAM2 = 8
							SET @PARAM3 = $MaintenanceOptInt

							EXECUTE @RC = [dbo].[QS_setMediaAgentProperty]
							   @PARAM1
							  ,@PARAM2
							  ,@PARAM3 
"@
		
		
        $null = Get-CVSQLDataSet -Connection $SQLConnection -SQLQuery $QS_SetMediaAgentProperty
		
		
    }#end process block
}