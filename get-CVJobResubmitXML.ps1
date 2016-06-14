function get-CVJobResubmitXML
{
    [CmdletBinding()]
    [OutputType([System.Xml.XmlDocument])]
    param (
		
        [Parameter(Mandatory = $true,
                ValueFromPipeline = $true,
        Position = 0)]
        [string[]]
        $JobID
		
		
		
    )#end param
	
	
	
    begin
    {
		
		
		
		
    }#end begin block
	
    process
    {
		
		
        $JobID | ForEach-Object -Process {
            #Create XML Document
            [System.Xml.XmlDocument]$JobResubmitXML = @"
	<TMMsg_TaskOperationReq opType="RESUBMIT_JOB" jobId="$_">
	</TMMsg_TaskOperationReq>
"@
			
			
			
            #Create XML Declaration XML.save method defaults to the encodoing specifified in the XML Declaration
            #Commvault expects encoding to be UTF-8 and will throw an error
			
            Write-Verbose -Message 'Creating XMLDeclaration 1.0, UTF-8, Standalone'
            $CVXMLDec = $JobResubmitXML.CreateXmlDeclaration('1.0', 'UTF-8', 'yes')
            $root = $JobResubmitXML.DocumentElement
			
            Write-Verbose -Message 'Inerting XMLDeclaration'
            $null = $JobResubmitXML.insertBefore($CVXMLDec, $root)
			
            Write-Verbose -Message "Outputting XML: $JobResubmitXML.outerXML" 			
			

            #return 1 XML document to the pipeline per job = resubmiting jobs must be done one at a time.
            $JobResubmitXML
			
			
			
            Write-Verbose -Message "Adding JobID $JobID"
        }
		
    }#end process block
	
    end
    {
		
    }#end end block
}