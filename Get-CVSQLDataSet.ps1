function Get-CVSQLDataSet
{
    [CmdletBinding()]
    [OutputType([system.Data.DataSet[]])]
    param (
        # System.Data.SqlClient.SQLConnection Object hosting the Commvault SQL connection
        [Parameter(Mandatory = $true,
                ValueFromPipeline = $true,
                Position = 0,
        ParameterSetName = 'SQLConnection')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias('conn')]
        [System.Data.SqlClient.SQLConnection]
        $Connection,
		
        # T-SQL query to pass to SQL server
        [Parameter(Position = 1,
        ParameterSetName = 'SQLConnection')]
        [string[]]$SQLQuery
		
    )#end param
	
	
	
    process
    {
		
        #Need to check if Connection is open already and if it matters
        if ($Connection.state -ne 'Open')
        {
            $Connection.open()
        }
		
		
		
        ##################################################
        ##Foreach is needed in case multple sql queries are provided
        ##################################################
        foreach ($Query in $SQLQuery)
        {
            #Create command contexts
            $cmd = New-Object -TypeName system.Data.SqlClient.SqlCommand -ArgumentList ($Query, $Connection)
            $cmd.CommandTimeout = $QueryTimeout
			
            #create the DataAdapter to fill our dataset
            $DataSet = New-Object -TypeName system.Data.DataSet
			
            #Add Connection and Query to the dataAdapter
            $da = New-Object -TypeName system.Data.SqlClient.SqlDataAdapter -ArgumentList ($cmd)
			
            #Populate dataSet to sent to pipe line
            [void]$da.fill($DataSet)
			
            #Put DataSet into Pipeline
            $DataSet
        }#end foreach process block
		
		
    }#end process block
	
    end
    {
		
        #close out SQL Connection
        $Connection.close()
		
    }#End end block
}