function Set-CVDataInterFacePair
{
    [CmdletBinding()]
    [OutputType([int])]
    param (
        # Param1 help description
        [Parameter(Mandatory = $true)]
              
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias('conn')]
        [System.Data.SqlClient.SQLConnection]
        $Connection,
        
        
        [Parameter(Mandatory = $false,
        ParameterSet = 'Single' )]
    
        [Parameter(Mandatory = $true,
        ParameterSet = 'Multi')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
   
    
        [hashtable]
        $SourceHash ,


        [Parameter(Mandatory = $false,
        ParameterSet = 'Single' )]
    
        [Parameter(Mandatory = $true,
        ParameterSet = 'Multi')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
   
    
        [hashtable]
        $DestHash ,
        



        [Parameter(Mandatory = $true,
        ParameterSet = 'Single' )]
    
        [Parameter(Mandatory = $false,
        ParameterSet = 'Multi')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
   
    
        [string]
        $SourceClient ,
        [Parameter(Mandatory = $true,
        ParameterSet = 'Single' )]
    
        [Parameter(Mandatory = $false,
        ParameterSet = 'Multi')]

        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
     
        [ValidateScript({
                    ($_.gettype() -eq [string] -and $_ -match `
                    '\b(?:(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\b')`
                    -or $_.gettype() -eq [ipaddress]
        })]
    
    
        [System.Object]
        $SourceInterface ,
  
        [Parameter(Mandatory = $true,
        ParameterSet = 'Single' )]
    
        [Parameter(Mandatory = $false,
        ParameterSet = 'Multi')]

        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
   
    
        [string]
        $DestinationClient ,
  
        [Parameter(Mandatory = $true,
        ParameterSet = 'Single' )]
    
        [Parameter(Mandatory = $false,
        ParameterSet = 'Multi')]

        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
     
        [ValidateScript({
                    ($_.gettype() -eq [string] -and $_ -match `
                    '\b(?:(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\b')`
                    -or $_.gettype() -eq [ipaddress]
        })]
    
    
        [System.Object]
        $DestinationInterface

    )#end param
        

    begin
    {
        if ($Sorcehash -and $DestHash)
        {
            # Content
        }
         
        
    }
        
    process
    {
        if ($SourceHash -and $DestHash)
        {
            foreach($Source in $SourceHash.keys)
            {
                $SourceClient = $Source
                $SourceInterface = $SourceHash.$Source
                
                foreach ($Dest in $DestHash.keys)
                {
                    $DestinationClient = $Dest
                    $DestinationInterface = $DestHash.$Dest
                    Set-CVDataInterFacePair -Connection $CVConn `
                    -SourceClient $SourceClient `
                    -SourceInterface $SourceInterface `
                    -DestinationClient $DestinationClient `
                    -DestinationInterface $DestinationInterface `
                    -Verbose $VerbosePreference
                }
            }
        }
        elseif($SourceClient -and $SourceInterface -and  $DestinationClient -and $DestinationInterface)
        {
            $AddDIPQuery = 

            @"
DECLARE @RC int
DECLARE @PARAM_1 varchar(1024)
DECLARE @PARAM_2 varchar(1024)
DECLARE @PARAM_3 varchar(1024)
DECLARE @PARAM_4 varchar(1024)
DECLARE @PARAM_5 varchar(1024)

set @Param_1 = 'Add'
set @Param_2 = `'$SourceClient`'
set @Param_3 = `'$SourceInterface`'
set @Param_4 = `'$DestinationClient`'
set @Param_5 = `'$DestinationInterface`'

EXECUTE @RC = [dbo].[QS_DataInterfacePairConfig] 
@PARAM_1
,@PARAM_2
,@PARAM_3
,@PARAM_4
,@PARAM_5
"@

            $Result = Invoke-CVSQLCMD -Connection $Connection -SQLQuery $AddDIPQuery
            $Result
        }
        else 
        {
            Write-Output -InputObject 'Incorrect number of arguments passed'
        }
        
    }
        


    End
    {
    #poop
 
       
    }
}