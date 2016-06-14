function Get-CVJobUpdateXML
{
    [CmdletBinding()]
    [OutputType([System.Xml.XmlDocument])]
    param (
		
        [Parameter(Mandatory = $true,
                ValueFromPipeline = $true,
        Position = 0)]
        [string[]]
        $JobID,
		
        [Parameter(Mandatory = $true)]
        [ValidateSet('suspend', 'resume', 'kill')]
        [string]
        $OpType,
		
		
        [string]
        $OpDescription
		
		
    )#end param
	
	
	
    begin
    {
		
        $OpType = $OpType.ToUpper()
		
        [System.Xml.XmlDocument]$JobUpdateXML = @"
		<JobManager_PerformMultiCellJobOpReq message="ALL_SELECTED_JOBS" operationDescription="">
		<jobOpReq operationType="JOB_$OpType">

		</jobOpReq>
		</JobManager_PerformMultiCellJobOpReq>
"@
		
        if ($OpDescription -ne $null)
        {
            $null = Write-Verbose -Message "Adding OperationDescription as `'$OpDescription`'"
            $JobUpdateXML.JobManager_PerformMultiCellJobOpReq.operationDescription = $OpDescription
        }#if ($OpDescription -ne $null)
		
		
    }#end begin block
	
    process
    {
		
        $JobID | ForEach-Object -Process {
            [System.Xml.XmlElement]$job = $JobUpdateXML.createElement('jobs')
            $job.setAttribute('jobId', $_)
		
            $null = $JobUpdateXML.JobManager_PerformMultiCellJobOpReq.jobOpReq.appendChild($job)
        }

		
		
    }#end process block
	
    end
    {
		
        #returns the XML document to the pipeline
        $null = Write-Verbose -Message 'Creating XMLDeclaration 1.0, UTF-8, Standalone'
        $CVXMLDec = $JobUpdateXML.CreateXmlDeclaration('1.0', 'UTF-8', 'yes')
		
        $root = $JobUpdateXML.DocumentElement
        $null = Write-Verbose -Message 'Inserting XMLDeclaration'
		
        $null = $JobUpdateXML.insertBefore($CVXMLDec, $root)
		
        Write-Verbose -Message "Outputting XML: $JobUpdateXML.outerXML" 
		
        $JobUpdateXML
		
    }#end end block
}