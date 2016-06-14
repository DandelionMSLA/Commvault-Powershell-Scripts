function Get-CVDataInterFacePair
{
    [CmdletBinding()]
    [OutputType([System.Data.DataRow])]
    param (
        # Param1 help description
        [Parameter(Mandatory = $true,
                
        Position = 0)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias('conn')]
        [System.Data.SqlClient.SQLConnection]
        $Connection,
        
        [Parameter(Mandatory = $true,
                ValueFromPipeline = $true,
                Position = 0
        , ParameterSetName = 'ClientName')]
        [Parameter(Mandatory = $false,
                ValueFromPipeline = $true,
                Position = 0
        , ParameterSetName = 'ClientID')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias('cn')]
        [String[]]
        $ClientName,
             
        [Parameter(Mandatory = $true,
                ValueFromPipeline = $true,
                Position = 0
        , ParameterSetName = 'ClientID')]
        [Parameter(Mandatory = $false,
                ValueFromPipeline = $true,
                Position = 0
        , ParameterSetName = 'ClientName')]
        
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias('ci')]
        [int[]]
        $ClientID  
        
		
    )#end param

    Begin
    {
  
        [System.Collections.ArrayList]$QuerySource = @()
    
    }
    Process
    {
        
        if($ClientName)
        {
            foreach($client in $ClientName)
            {
                $null = $QuerySource.add($client)
            }
        }
        
        if($ClientID)
        {
            foreach($ID in $ClientID)
            {
                $null = $QuerySource.add($ID)
            }
        }
      
        
        
                
                
    }#end foreach $Source in $QuerySource
        
        

    End
    {

        $InString = '(' + ($QuerySource -replace '\A|\z', "'" -join ',') + ')'
        
        if($QuerySource[0].gettype() -eq [int32])
        {
            $DIPQuery = 
            @"
select 
	
	(select displayname from app_client where id = srcClientId) as srcClient
	,srcInterface
	,(select displayname from app_client where id = destClientId) as destClient
	,destInterface
    ,isActive
from archPipeline 

where archpipeline.srcClientId in $InString
"@
        }
        elseif($QuerySource[0].gettype() -eq [string])
        {
            $DIPQuery = @"
select 
	
	(select displayname from app_client where id = srcClientId) as srcClient
	,srcInterface
	,(select displayname from app_client where id = destClientId) as destClient
	,destInterface
    ,isActive
from archPipeline 
inner join mmhost
on ClientId = destClientId
or clientid = srcClientId
where (select displayname from app_client where id = srcClientId) in $InString
"@
        }

        $ds = Get-CVSQLDataSet -Connection $Connection -SQLQuery $DIPQuery
        $ds = $ds.tables.rows
        $ds
    }
}