function Get-CVCurrentJobInfo
{
    [CmdletBinding()]
    [OutputType([system.Data.DataSet[]])]
    param (
        # Param1 help description
        [Parameter(Mandatory = $true,
                ValueFromPipeline = $true,
                Position = 0,
        ParameterSetName = 'SQLConnection')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias('conn')]
        [System.Data.SqlClient.SQLConnection]
        $Connection
		
    )#end param
	
	
	
    begin
    {
		
        ###############################################################
        #JobInfo Query
        ###############################################################
		
        $JobInfoQuery = @"
							SELECT 	ccjc.jobid,
								ccjc.operation,
								ccjc.clientcomputer,
								ccjc.agenttype,
								ccjc.subclient,
								ccjc.mediaAgent,
								ccjc.storagePolicy,
								ccjc.instanceName,
								ccjc.status,
                                ccjc.phase,
                                ccjc.progress,
                                ccjc.delayreason,
								ji.restartable,
								ji.preemptable,
								(Select name from app_client where app_client.id = 2) csname 
                                from CommCellJobController ccjc
					            INNER JOIN JMJobInfo ji
								ON
								ccjc.jobID = ji.jobId
"@
		
		
    }#end Begin block
	
    process
    {
		
		
        ###############################################################
        #Get our dataset
        ###############################################################
        $CVDS = Get-CVSQLDataSet -Connection $Connection -SQLQuery $JobInfoQuery
		
		
        ###############################################################
        #Create new-object per JobID
        #Returns the object to the pipeline
        ###############################################################
		
        $HashString = ($CVDS.Tables.rows |
            Get-Member -MemberType Property |
            Select-Object -ExpandProperty name |
        Out-String -Stream)




        ######################################################
        ##Perform the darkest of sorceries


        #Replacement takes the property member names and replaces them
        # with the following pattern 'Property' = $_.property
        #allowing for dynamic pscustomeobject generation without having
        #to rewrite the code if the sql query changes fields

        $HashString = $HashString -replace '^((?:\w+)+)$', @'
'${1}' = $$_.${1}

'@
        #Now that the string has been built with our hashtable properties,
        #we add the command to invoke for crating new custom objects followed by
        #a hashtable built with our hashstring regex replacmenet process.
        $HashString = "New-Object -TypeName PSCustomObject -Property @{ `n$($HashString)`n}"




        $CVDS.tables.rows | ForEach-Object -Process {
            ##Invoke the secret mysteries
            Invoke-Expression -Command $HashString
        }
		
		
		
    }#End process block
}