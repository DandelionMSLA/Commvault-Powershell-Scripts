function Get-CVEncryptionInfo
{
    [CmdletBinding()]
    [OutputType([System.Data.DataRow])]
    param (
        # Provide System.Data.SqlClient.SQLConnection Object for the Commvault DataBase
        [Parameter(Mandatory = $true,
                ValueFromPipeline = $true,
                Position = 0,
        ParameterSetName = 'SQLConnection')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias('conn')]
        [System.Data.SqlClient.SQLConnection]
        $Connection,
		
        #Standard CommCellHWEncInfo View With StoragePolicy, CopyName, MediaAgentName, UseHWEncryptino, and DirectMediaAccess Columns
        [switch]
        $HCrypt,
		
        #Same as HCrypt, but adds CopyPrecedence, drivepool, LibraryId, librarytype, and HWEncryptionEligible columns
        [switch]
        $HCryptExt,
		
        #Standard CVEncryptionInfo Stored Procdure call with ClientName, SubClientName, and Encryption Type columns
        [switch]
        $SCrypt,
		
        #The motherload - Pulls 18 columns: ClientName, AppId, SubclientName,
        #StoragePolicy, CopyName, CopyID, CopyPrecedence, MediaAgent, DrivePool,
        #Library, LibraryID, LibraryType, DataPathID, HardwareCompression,
        #ClientSWEncryption, UseHardwareEncryption, DirectMediaAccess HWEncryptionEligible
        [Switch]
        $MCrypt
		
    )#end param
	
    begin
    {
		
        #region SQLQueries
		
        #Collection of Queries with varying levels of detail
		
        $HCryptQuery = 'USE [commserv]
            SELECT [StoragePolicy]
            ,[CopyName]
            ,[MediaAgentName]
            ,[UseHWEncryption]
            ,[DirectMediaAccess]
        FROM [dbo].[CommCellHWEncInfo]'
		
		
        $HCryptExtQuery = @'

SELECT Distinct
	 storagepolicy = ARG.name
    ,CopyName= ARP.name 
	,CopyPrecedence = arp.copy
    ,drivepool = MP.DrivepoolName 
    ,library = ML.AliasName
	,LibraryID = ml.LibraryId 
	,LibraryType = (select librarytypename from mmlibrarytype where librarytypeid = ml.librarytypeid)
	,mdp.DataPathId
	,hardwarecompression =
		CASE (select IsHardwareCompressed from MMDataPath where MG.DataPathId = DataPathId)
		WHEN 1 THEN 'Yes'
		WHEN 0 THEN 'No'
		ELSE 'Unknown'
		END
	
	,UseHardwareEncryption = 
		case mdp.UseHardwareEncryption
		when 0 then 'No'
		when 1 then 'Yes'
		when 2 then 'Yes'
		end
	,HWEncryptionEligible = 
		case 
		when ml.LibraryTypeId <> 3 and ml.Libraryid  > 0 then 'Yes'
		else 'No'
		end
	
	
FROM	ArchGroup ARG 
LEFT JOIN
		ArchGroupCopy ARP 
		ON ARG.id = ARP.archGroupId  
        AND ARG.id > 0
        AND ARP.COPY >0
LEFT JOIN ArchStream ARS 
		ON ARP.id = ARS.archGroupCopyId 
		AND 
		ARG.id = ARS.archGroupId 
		and 
		ARS.stream = 1  
LEFT JOIN MMMediaGroup MG 
		ON ARS.mediagroupid = MG.mediagroupid 
LEFT JOIN MMDrivePool MP 
		ON MG.DrivePoolId = MP.DrivePoolId 
JOIN MMMasterPool MMP 
	    ON MMP.MasterPoolId = MP.MasterPoolId 
LEFT JOIN MMLibrary ML 
		ON MMP.LibraryId = ML.LibraryId 
LEFT JOIN APP_Application AP 
		ON ARG.id = AP.dataArchGrpId 
LEFT JOIN APP_Client C 
		ON AP.clientid = C.id 
LEFT JOIN MMDataPath AS MDP 
		ON ARP.id = MDP.CopyId 
		AND MG.DataPathId = MDP.DataPathId 
		AND MP.DrivePoolId = MDP.DrivePoolId


'@
		
		
		
		
        $SCryptQuery = "
            SELECT	C.name AS ClientName,
            A.subclientName AS SubClientName,
            EncryptionType=
            CASE SP.attrVal
            WHEN 0 THEN 'None'
            WHEN 1 THEN 'Media Only (Media Agent Side)'
            WHEN 2 THEN 'Network and Media (Agent Side)'
            WHEN 3 THEN 'Network Only (Agent Encrypts, Media Agent Decrypts)'
            ELSE 'unknown'
            END
            FROM    APP_Application A
            INNER JOIN App_Client AS C ON C.id = A.clientId
            INNER JOIN App_SubClientProp AS SP ON A.id = SP.componentNameId
            WHERE SP.attrName = 'Encrypt: encryption' AND SP.attrType = 10 AND SP.modified = 0
            OR
            (SP.attrName = 'Encrypt: encryption' AND SP.attrType = 10 AND SP.modified = 0
            AND A.id IN		
            (
            SELECT attrVal AS id FROM App_SubClientProp
            WHERE AttrName = 'Associated subclient Policy' AND Modified = 0
            AND componentNameId IN 
            (SELECT id FROM APP_Application)))
        "
		
		
        $MCryptQuery = "
            
          
       
           
            if OBJECT_ID('tempdb.dbo.#SubclientDataPath') is not null
            drop table #SubclientDataPath

            CREATE TABLE #SubclientDataPath (
            AppId INT
            , AppTypeId INT
            , IncrSP INT 
            --,OpType VARCHAR(8)
            , BackupType INT
            , DataType INT
            , DataPathId INT
            , OverrideDP INT) 

            DECLARE @TACPROP				TABLE ( AttrVal Integer,
            attrName nvarchar(250),
            componentnameid integer )

            insert @TACPROP	
            select max(CAST(cp.attrval as int)) as AttrVal
            ,cp.attrName
            ,cp.componentNameId
            from APP_ClientProp cp 
            where cp.attrName in  (N'Encrypt: encryption',N'Encrypt: Type',N'Encrypt: Key Length')
            and cp.modified = 0
            group by cp.attrname
            ,cp.componentnameid
 
            INSERT	INTO #SubclientDataPath 
            SELECT	A.id, A.appTypeId, AG.IncrSP  
            --,CASE WHEN CopyId = AG.defaultCopy THEN (CASE WHEN ISNULL(I.isDMAppType, 0) = 1 THEN 'Archive' ELSE 'Backup' END) ELSE 'Snap' END, 
            ,CASE WHEN AG.IncrSP > 1 THEN 1 ELSE 0 END, 
            CASE WHEN A.dataArchGrpId = A.logArchGrpId THEN 0 WHEN A.dataArchGrpId > 1 THEN 1 ELSE 4 END, 
            DP.DataPathId, 0 
            FROM	APP_Application A WITH (NOLOCK) 
            INNER JOIN archGroup AG WITH (NOLOCK) ON AG.id IN (A.dataArchGrpId, A.logArchGrpId) 
            INNER JOIN MMDataPath DP WITH (NOLOCK) ON CopyId IN (
	  
            select distinct
            agc.id as copyId 

            from archgroupcopy agc
            inner join archgroup ag
            on agc.archGroupId = ag.id
            and ag.id > 1
            inner join APP_Application ap
            on ag.id = ap.dataArchGrpID
            and ap.clientId not in (select clientid from mmhost)

            --WON'T WORK ON OLDER VMWARE CLIENTS CONFIGURED AS VSA SUBCLIENTS DIRECTLY UNDER A MEDIA AGENT
            ) AND DP.Flag & 1 = 1 
            LEFT OUTER JOIN APP_iDATypeHandlingInfo I WITH (NOLOCK) ON A.appTypeId = I.appTypeId 
            WHERE 	(A.dataArchGrpId > 1 OR A.logArchGrpId > 1) AND (A.subclientStatus & (2|4)) = 0 

            AND	dbo.IsSubClientValid(A.appTypeId, A.subclientStatus, 0) = 1 
            AND A.id NOT IN (SELECT componentNameId FROM APP_subclientProp WITH (NOLOCK) WHERE attrName = 'DDB Backup' AND attrVal <> '0' AND modified = 0) 
            AND A.backupSet NOT IN (SELECT componentNameId FROM APP_BackupSetProp WITH (NOLOCK) WHERE attrName = 'SILO Copy ID') 
            AND A.clientId NOT IN (SELECT componentNameId FROM APP_ClientProp WITH (NOLOCK) WHERE attrName = 'Content Index Server' AND attrVal = '1') 
 
            INSERT	INTO #SubclientDataPath 
            SELECT	T.AppId
            , T.AppTypeId
            , 0
            --, 'Backup'
            , 2
            , 1
            , DP.DataPathId
            , 0 
            FROM	#SubclientDataPath T 
            INNER JOIN archGroup AG WITH (NOLOCK) ON T.IncrSP = AG.id 
            INNER JOIN MMDataPath DP WITH (NOLOCK) ON DP.CopyId = AG.defaultCopy AND DP.Flag & 1 = 1 
            WHERE	T.AppTypeId NOT IN (3,22,37,59,61,62,71,77,79,80,81,103,104) 
	   
 
            UPDATE	#SubclientDataPath 
            SET		DataPathId = ADP.DataPathId, OverrideDP = 1 
            FROM	#SubclientDataPath T 
            INNER JOIN APP_AppToDataPath ADP WITH (NOLOCK) 
            ON T.AppId = ADP.componentNameId 
            WHERE	ADP.precedence = 1 
            --AND T.opType <> 'Snap' 
 
            SELECT	CL.name AS 'Client', 
            IDA.name AS 'Agent', 
            dbo.FixInstanceName(INS.name, A.appTypeId) AS 'Instance', 
            BS.name AS 'Backupset', 
            A.SubclientName AS 'Subclient', 
            --S.OpType AS 'Operation', 
            CASE WHEN S.DataType = 4 THEN 'Transaction Log' WHEN S.BackupType = 1 THEN 'Full' WHEN S.BackupType = 2 THEN 'Incr/Diff' 
            ELSE 'Any' END AS 'JobType', 
            CASE WHEN S.OverrideDP > 0 THEN 'Yes' ELSE 'No' END AS 'Override DataPath', 
            (SELECT name FROM APP_Client WITH (NOLOCK) WHERE id = DP.HostClientId) AS 'MediaAgent', 
            L.AliasName AS 'Library', 
            L.LibraryId  as LibraryId,
            SG.SpareGroupName AS 'ScratchPool', 
            MPL.MasterPoolName AS 'MasterPool', 
            DPL.DrivePoolName AS 'DrivePool', 
            dbo.GetClientEncryption(Cl.id) as ClientEncryption
            ,ClientEncryptionType = isnull((select 
            case 
            when attrval  = 2 then 'BlowFish'
            when attrval = 3 then 'AES'
            when attrval = 5 then 'Two Fish'
            when attrval = 6 then '3-DES'
            when attrval = 4 then 'SERPENT'
            when attrval = 8 then 'GOST'
            end
            from @TACPROP
            where componentnameid = CL.id 
            and attrname = N'Encrypt: Type'),'N/A')
            ,ClientEncryptionKeyLength = isnull((Select cast(attrval as nvarchar) 
            from @TACPROP 
            where componentNameId = CL.id 
            and attrname = 'Encrypt: Key Length'),'N/A')
            ,CASE WHEN DP.IsHardwareCompressed > 0 THEN 'Yes' ELSE 'No' END AS 'Hardware Compressed', 
            CASE WHEN DP.UseHardwareEncryption > 0 THEN 'Yes' ELSE 'No' END AS 'HardwareEncryption', 
            HWEncryptionEligible = case
            WHEN l.librarytypeid <> 3
            AND l.libraryid > 0 
            THEN 'Yes'
            ELSE 'No'
            END	
            ,AG.name AS 'StoragePolicy', 
            AGC.name AS 'Copy' 
            FROM	#SubclientDataPath S 
            INNER JOIN MMDataPath DP WITH (NOLOCK) ON S.DataPathId = DP.DataPathId 
            INNER JOIN MMDrivePool DPL WITH (NOLOCK) ON DP.DrivePoolId = DPL.DrivePoolId 
            INNER JOIN MMMasterPool MPL WITH (NOLOCK) ON DPL.MasterPoolId = MPL.MasterPoolId 
            INNER JOIN MMLibrary L WITH (NOLOCK) ON MPL.LibraryId = L.LibraryId 
            INNER JOIN MMSpareGroup SG WITH (NOLOCK) ON DP.SpareGroupId = SG.SpareGroupId 
            INNER JOIN APP_Application A WITH (NOLOCK) ON S.AppId = A.id 
            INNER JOIN APP_Client CL WITH (NOLOCK) ON A.clientId = CL.id 
            INNER JOIN APP_iDAType IDA WITH (NOLOCK) ON A.appTypeId = IDA.type 
            INNER JOIN APP_InstanceName INS WITH (NOLOCK) ON A.instance = INS.id 
            INNER JOIN APP_BackupsetName BS WITH (NOLOCK) ON A.backupset = BS.id 
            INNER JOIN archGroupCopy AGC WITH (NOLOCK) ON DP.CopyId = AGC.id 
            INNER JOIN archGroup AG WITH (NOLOCK) ON AG.id = AGC.archGroupId 
            ORDER BY storagepolicy
            , Client
            , Agent
            , Instance
            , Backupset
            , Subclient
            --, Operation
            , BackupType 
 
            DROP TABLE #SubclientDataPath 








        "
        #endregion
		
        #region SwitchQualification
		
		
		
		
        #Select appropriate query based on switch slection
		
		
        $SQLQuery = if ($HCrypt)
        {
            $HCryptQuery
        }
        elseif ($HCryptExt)
        {
            $HCryptExtQuery
        }
        elseif ($SCrypt)
        {
            $SCryptQuery
        }
        elseif ($MCrypt)
        {
            $MCryptQuery
        }
        else
        {
            $HCryptExt
        }
		
		
        #endregion
		
		
    }#end begin
	
	
	
    process
    {
		
		
        #Need to check if Connection is open already
        if ($Connection.state -ne 'Open')
        {
            $null = $Connection.open()
        }
		
		
		
        ##################################################
        ##Create a dataSet and return a colletion of datarows
        ##################################################
		
		
        $DataPath = Get-CVSQLDataSet -Connection $Connection -SQLQuery $SQLQuery
		
        #Generate new object with properties of dataset columns
		
        #For convenience, change DataTable to a stream of dataRow objects
		
        $DataRow = $DataPath.tables.rows
        $DataRow
		
    }#end process block
	
    end
    {
		
        #close out SQL Connection
        $Connection.close()
		
    }#End end block
}