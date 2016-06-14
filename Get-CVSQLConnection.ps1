function Get-CVSQLConnection
{
    <#
            

    #>
	
	
    [CmdletBinding()]
    [OutputType([System.Data.SqlClient.SQLConnection])]
    param (
        [Parameter(Position = 0,
        Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLServer,
		
        [Parameter(Position = 1)]
        [ValidateNotNull()]
        [String]
        $Database = 'Commserv',
		
        [Parameter(Position = 2)]
        [switch]
        $IntegratedSecurity,
		
		
        [Parameter(Position = 3)]
        [ValidateNotNull()]
        [System.Object]
        $User,
		
		
        [Parameter(Position = 4)]
        [ValidateNotNull()]
        [String]
        $ConnectionTimeout = 30
    )
	
    process
    {
		
        #################################################
        #Start putting together connection string based on user input
        #################################################
		
		
        if (!($IntegratedSecurity))
        {
            if (!($User.gettype() -eq [System.Management.Automation.PSCredential]))
            {
                $SQLCred = Get-Credential -Credential $User
            }
            else
            {
                $SQLCred = $User
            }
            $SQLUser = $SQLCred.GetNetworkCredential().UserName
			
            $SQLPass = $SQLCred.getnetworkcredential().password
			
			
			
            #################################################
            #Create Connection String
            #################################################
			
            Write-Verbose -Message $('Server={0};Database={1};User Id={2};Password={3};Connect Timeout={4}' `
            -f $SQLServer, $Database, $SQLUser, $SQLPass, $ConnectionTimeout)
			
            $ConnectionString = 'Server={0};Database={1};User Id={2};Password={3};Connect Timeout={4}' `
            -f $SQLServer, $Database, $SQLUser, $SQLPass, $ConnectionTimeout
        }#end if($IntegratedSecurity -eq "False")
        else
        {
            $ConnectionString = 'Server={0};Database={1};Integrated Security=True;Connect Timeout={2}' `
            -f $SQLServer, $Database, $ConnectionTimeout
            Write-Verbose -Message $('ConnectionString created with values: Server={0};Database={1};Integrated Security=True;Connect Timeout={2}' `
            -f $SQLServer, $Database, $ConnectionTimeout)
        }#End Else
		
		
        #################################################
        #Create sqlconnection object and add connection string
        #################################################
		
		
        $conn = New-Object -TypeName System.Data.SqlClient.SQLConnection
        Write-Verbose -Message 'Creating new-object of Type: System.Data.SqlClient.SQLConnection'
		
		
        Write-Verbose -Message ' Adding ConnectionString to SQLConnection Object '
        $conn.ConnectionString = $ConnectionString
		
        #################################################
        #Return sQLConnection to the pipeline
        #################################################
		
		
        $conn
		
		
    }#end Process
	
	
    end
    {
		
		
		
		
		
    }# end end block
}