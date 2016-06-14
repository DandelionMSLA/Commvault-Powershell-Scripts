function Get-CVCreatePseudoClientRequestXML
{
    [CmdletBinding()]
    [OutputType([System.Xml.XmlDocument])]
    param (
		
        [Parameter(Mandatory = $true,
        Position = 0)]
        [ValidateSet('RAC', 'DB2_DPF', 'EXCHANGE_2010_DAG_CLIENT',
                'CONTENT_STORE_CLIENT', 'WINDOWS_CLUSTER_CLIENT',
                'UNIX_CLUSTER_CLIENT', 'VIRTUAL_SERVER_CLIENT',
                'OPEN_VMS_CLIENT', 'REFERENCE_COPY_CLIENT',
                'CLOUD_CONNECTOR_CLIENT', 'DISTRIBUTED_DATABASE_CLIENT',
                'IBM_ISERIES_CLIENT', 'MSSQL_AG', 'EXCHANGE_ONEPASS',
        'NOTES_ONEPASS', 'SHAREPOINT_FARM')]
        [string]
        $CVPseudoCLientType,
		
        [Parameter(Mandatory = $true,
                ValueFromPipeline = $false,
        Position = 1)]
        [string]
        $CVPseudoClientName,
		
        [Parameter(Mandatory = $false,
                ValueFromPipeline = $false,
        Position = 2)]
        [string]
        $CVPseudoHostName = $CVPseudoClientName
		
		
    )#end param
	
	
	
    begin
    {
		
        ###############################################################
        #Begin Block blank
        ###############################################################
		
    }#end begin block
	
    process
    {
		
		
		
		
		
        ###############################################################
        #Create XML Document
        ###############################################################
        [System.Xml.XmlDocument]$PseudoClientRequestXML = @"
	<App_CreatePseudoClientRequest>

  <clientInfo>
    <clientType>$CVPseudoCLientType</clientType>
    <openVMSProperties>
      <cvdPort>0</cvdPort>
      <userAccount>
        <userName></userName>
      </userAccount>
    </openVMSProperties>
  </clientInfo>

  <entity>
    <clientName>$CVPseudoClientName</clientName>
    <hostName>$CVPseudoHostName</hostName>
  </entity>

  <registerClient>false</registerClient>

</App_CreatePseudoClientRequest>
"@
		
        ###############################################################
        #Create XML Declaration XML.save method defaults to the encodoing
        #specifified in the XML Declaration - Commvault expects encoding
        #to be UTF-8 and will throw an error
        ###############################################################
		
		
        $null = Write-Verbose -Message 'Creating XMLDeclaration 1.0, UTF-8, Standalone'
        $CVXMLDec = $PseudoClientRequestXML.CreateXmlDeclaration('1.0', 'UTF-8', 'yes')
        $root = $PseudoClientRequestXML.DocumentElement
		
        $null = Write-Verbose -Message 'Inerting XMLDeclaration'
        $null = $PseudoClientRequestXML.insertBefore($CVXMLDec, $root)
		
        Write-Verbose  -Message "Outputting XML: $PseudoClientRequestXML.outerXML" 
		
		
        $PseudoClientRequestXML
		
		
		
        $null = Write-Verbose -Message "Adding PseudoClientType $CVPseudoCLientType"
		
		
    }#end process block
	
    end
    {
		
        ###############################################################
        #End block empty
        ###############################################################
		
    }#end end block
}