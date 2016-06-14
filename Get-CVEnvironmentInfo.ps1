function Get-CVEnvironmentInfo
{
    [CmdletBinding()]
	
	
    Param
    (
        # Param1 help description
        [Parameter(Position = 0)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias('cn')]
        [string]
        $CVHostname = $env:COMPUTERNAME,
		
		
        [Alias('KeyPath')]
        [string]
        $CVRegKeyInstancePath
		
    )
	
    Begin
    {
		
        #Do the things
        [uint32]$hDefKey = 2147483650
		
		
		
        #Populate our values
		
        #parameter is for instances of non-standard registry locations or multi-instance installs
        if (!$CVRegKeyInstancePath)
        {
            $CVRegKeyInstancePath = 'SOFTWARE\CommVault Systems\Galaxy\Instance001'
        }
		
        $CVBasekey = $CVRegKeyInstancePath + '\Base'
        $CVDataBaseKey = $CVRegKeyInstancePath + '\Database'
        $CVCommserveKey = $CVRegKeyInstancePath + '\CommServe'
		
        $CVGalaxyHome = 'dGALAXYHOME'
        $CVBaseHome = 'dBASEHOME'
        $CVInstance = 'sINSTANCE'
        $CVCSDBName = 'sCSDBNAME'
		
        $CVCSClientName = 'sCSCLIENTNAME'
        $CVCSHostName = 'sCSHostNAME'
		
        $type = [Microsoft.Win32.RegistryHive]::LocalMachine
    }
    Process
    {
		
		
		
		
		
        #Make our Registry Reader
        $StandardRegistryProvider = [wmiclass]"\\$($CVHostname)\root\cimv2:StdRegProv"
		
		
		
        #Properties of subkeys in \Base
        $CVInstallPath = $StandardRegistryProvider.GetStringValue($hDefKey, $CVBasekey, $CVGalaxyHome)
        $CVBasePath = $StandardRegistryProvider.GetStringValue($hDefKey, $CVBasekey, $CVBaseHome)
		
		
        #Properties of subkeys in \Database
        $CVSQLServer = $StandardRegistryProvider.GetStringValue($hDefKey, $CVDataBaseKey, $CVInstance)
        $CVDatabase = $StandardRegistryProvider.GetStringValue($hDefKey, $CVDataBaseKey, $CVCSDBName)
		
		
        #Properties of subkeys in \Commserve
        $CVCSClientName = $StandardRegistryProvider.GetStringValue($hDefKey, $CVCommserveKey, $CVCSClientName)
        $CVCSHostName = $StandardRegistryProvider.GetStringValue($hDefKey, $CVCommserveKey, $CVCSHostName)
		
		
		
    }
    End
    {
		
		
        #Create hashtable of values for use with other modules
		
        $CVEnvironment = @{
            'CVInstallPath' = $CVInstallPath.sValue
            'CVBasePath'  = $CVBasePath.sValue
            'CVSQLServer' = $CVSQLServer.sValue
            'CVDatabase'  = $CVDatabase.sValue
            'CVClientName' = $CVCSClientName.sValue
            'CVHostName'  = $CVCSHostName.sValue
        }
		
        $CVEnvironment
		
		
    }
}