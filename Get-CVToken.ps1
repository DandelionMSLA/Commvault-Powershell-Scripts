function Get-CVToken
{
    [CmdletBinding()]
	
    param (
		
		
		
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Data.SqlClient.SQLConnection]
        $SQLConnection,
		
        # Param1 help description
		
        [string]
        $Path = "$env:ProgramFiles\commvault\Simpana\Base",
		
		
		
		
        [string]
        $CVUser,
		
		
        [switch]
        $SSO
		
		
		
		
    )#end param
	
    begin
    {
        $CSHostName = $SQLConnection.DataSource.Substring(0, $SQLConnection.Datasource.IndexOf('\'))
		
    }
	
	
    process
    {
		
        if (Test-Path $Path)
        {
            if ($SSO)
            {
                #If sso is in use, then glogin will use the currentusers's credentials
                & "$Path\qlogin.exe" -sso  -cs $CSHostName -gt
            }#end if($sso)
			
            else
            {
                #Grab the database name from the sql connection to pass to the SQL Query
                $Database = $SQLConnection.Database
				
				
				
                #SQL Query to pull the password hash for the username supplied
                $UMUserQuery = "SELECT umu.password
                    FROM [$Database].[dbo].[UMUsers] umu
                where umu.login =`'$CVUser`'"
				
                #SQL query returns a dataset
                $ds = Get-CVSQLDataSet -Connection $CVConn -SQLQuery $UMUserQuery
				
                #extract the password and pass it to Qlogin to obtain a token
                $CVPass = $ds.Tables[0] | Select-Object -ExpandProperty password
				
				
                & "$Path\qlogin.exe" -cs "$CSHostName" -u "$CVUser" -ps "$CVPass" -gt
            }#end else
        }#end if testpath $path
    }
}