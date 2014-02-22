###############################################################################
#
# PrtgShell
# Josh Sanders, Brian Addicks
# 2014 Lockstep Technology Group
#
# version 2
#
###############################################################################


#Add-Type -ReferencedAssemblies @(([System.Reflection.Assembly]::LoadWithPartialName("System.Web")).Location) -TypeDefinition @"
Add-Type -ReferencedAssemblies @(
	([System.Reflection.Assembly]::LoadWithPartialName("System.Xml")).Location,
	([System.Reflection.Assembly]::LoadWithPartialName("System.Web")).Location,
	([System.Reflection.Assembly]::LoadWithPartialName("System.Xml.Linq")).Location
	) -TypeDefinition ((gc .\prtgshell.cs) -join "`n")

###############################################################################

<#
		public string UrlBuilder (string Action) {
		
			if (Action.StartsWith("/")) Action = Action.Substring(1);
			
			string[] Pieces = new string[4];
			Pieces[0] = this.ApiUrl;
			Pieces[1] = Action;
			Pieces[2] = "?";
			Pieces[3] = this.AuthString;
			
			string CompletedString = string.Join ("",Pieces);
			this.urlhistory.Push(CompletedString);
			return CompletedString;
		}
		
		public string UrlBuilder (string Action, string[] QueryParameters) {
		
			if (Action.StartsWith("/")) Action = Action.Substring(1);
			
			string[] Pieces = new string[4];
			Pieces[0] = this.ApiUrl;
			Pieces[1] = Action;
			Pieces[2] = "?";
			Pieces[3] = this.AuthString;
			
			var FullString = new string[Pieces.Length + QueryParameters.Length];
			Pieces.CopyTo(FullString, 0);
			QueryParameters.CopyTo(FullString, Pieces.Length);
			
			string CompletedString = string.Join ("",FullString);
			this.urlhistory.Push(CompletedString);
			return CompletedString;
		}
#>



function Get-PrtgServer {
	<#
	.SYNOPSIS
		Establishes initial connection to PRTG API.
		
	.DESCRIPTION
		The Get-PrtgServer cmdlet establishes and validates connection parameters to allow further communications to the PRTG API. The cmdlet needs at least three parameters:
		 - The server name (without the protocol)
		 - An authenticated username
		 - A passhash that can be retrieved from the PRTG user's "My Account" page.
		
		
		The cmdlet returns an object containing details of the connection, but this can be discarded or saved as desired; the returned object is not necessary to provide to further calls to the API.
	
	.EXAMPLE
		Get-PrtgServer "prtg.company.com" "jsmith" 1234567890
		
		Connects to PRTG using the default port (443) over SSL (HTTPS) using the username "jsmith" and the passhash 1234567890.
		
	.EXAMPLE
		Get-PrtgServer "prtg.company.com" "jsmith" 1234567890 -HttpOnly
		
		Connects to PRTG using the default port (80) over SSL (HTTP) using the username "jsmith" and the passhash 1234567890.
		
	.EXAMPLE
		Get-PrtgServer -Server "monitoring.domain.local" -UserName "prtgadmin" -PassHash 1234567890 -Port 8080 -HttpOnly
		
		Connects to PRTG using port 8080 over HTTP using the username "prtgadmin" and the passhash 1234567890.
		
	.PARAMETER Server
		Fully-qualified domain name for the PRTG server. Don't include the protocol part ("https://" or "http://").
		
	.PARAMETER UserName
		PRTG username to use for authentication to the API.
		
	.PARAMETER PassHash
		PassHash for the PRTG username. This can be retrieved from the PRTG user's "My Account" page.
	
	.PARAMETER Port
		The port that PRTG is running on. This defaults to port 443 over HTTPS, and port 80 over HTTP.
	
	.PARAMETER HttpOnly
		When specified, configures the API connection to run over HTTP rather than the default HTTPS.
		
	.PARAMETER Quiet
		When specified, the cmdlet returns nothing on success.
	#>

	Param (
		[Parameter(Mandatory=$True,Position=0)]
		[ValidatePattern("\d+\.\d+\.\d+\.\d+|(\w\.)+\w")]
		[string]$Server,

		[Parameter(Mandatory=$True,Position=1)]
		[string]$UserName,

		[Parameter(Mandatory=$True,Position=2)]
		[string]$PassHash,

		[Parameter(Mandatory=$False,Position=3)]
		[int]$Port = $null,

		[Parameter(Mandatory=$False)]
		[alias('http')]
		[switch]$HttpOnly,
		
		[Parameter(Mandatory=$False)]
		[alias('q')]
		[switch]$Quiet
	)

    BEGIN {
		if ($HttpOnly) {
			$Protocol = "http"
			if (!$Port) { $Port = 80 }
		} else {
			$Protocol = "https"
			if (!$Port) { $Port = 443 }
			
			$PrtgServerObject = New-Object PrtgShell.PrtgServer
			
			$PrtgServerObject.Protocol = $Protocol
			$PrtgServerObject.Port     = $Port
			$PrtgServerObject.Server   = $Server
			$PrtgServerObject.UserName = $UserName
			$PrtgServerObject.PassHash = $PassHash
			
			$PrtgServerObject.OverrideValidation()
		}
    }

    PROCESS {
		$url = $PrtgServerObject.UrlBuilder("api/getstatus.xml")

		try {
			$QueryObject = HelperHTTPQuery $url -AsXML
		} catch {
			throw "Error performing HTTP query"
		}
		
		$Data = $QueryObject.Data

		$data.status.ChildNodes | % {
			if ($_.Name -ne "IsAdminUser") {
				$PrtgServerObject.$($_.Name) = $_.InnerText
			} else {
				# TODO
				# there's at least four properties that need to be treated this way
				# this is because this property returns a text "true" or "false", which powershell always evaluates as "true"
				$PrtgServerObject.$($_.Name) = [System.Convert]::ToBoolean($_.InnerText)
			}
		}
		
        $global:PrtgServerObject = $PrtgServerObject

		#HelperFormatTest ###### need to add this back in
		
		if (!$Quiet) {
			return $PrtgServerObject | Select-Object @{n='Connection';e={$_.ApiUrl}},UserName,Version
		}
    }
}


###############################################################################


function Get-PrtgTableData {
	<#
		.SYNOPSIS
			Returns a PowerShell object containing data from the specified object in PRTG.
			
		.DESCRIPTION
			The Get-PrtgTableData cmdlet can return data of various different content types using the specified parent object, as well as specify the return columns or filtering options. The input formats generally coincide with the Live Data demo from the PRTG API documentation, but there are some content types that the cmdlet does not yet support, such as "sensortree".
		
		.PARAMETER Content
			The type of data to return about the specified object. Valid values are "devices", "groups", "sensors", "todos", "messages", "values", "channels", and "history". Note that all content types are not valid for all object types; for example, a device object can contain no groups or channels.
			
		.PARAMETER ObjectId
			An object ID from PRTG. Objects include probes, groups, devices, and sensors, as well as reports, maps, and todos.
		
		.PARAMETER Columns
			A string array of named column values to return. In general the default return values for a given content type will return all of the available columns; this parameter can be used to change the order of columns or specify which columns to include or ignore.
			
		.PARAMETER FilterTags
			A string array of sensor tags. This parameter only has any effect if the content type is "sensor". Output will only include sensors with the specified tags. Note that specifying multiple tags performs a logical OR of tags.
			
		.PARAMETER Count
			Number of records to return. PRTG's internal default for this is 500. Valid values are 1-50000.
			
		.PARAMETER Raw
			If this switch is set, the cmdlet will return the raw XML data rather than a PowerShell object.
		
		.EXAMPLE
			Get-PrtgTableData groups 1
			
			Returns the groups under the object ID 1, which is typically the Core Server's Local Probe.
		
		.EXAMPLE
			Get-PrtgTableData sensors -FilterTags corestatesensor,probesensor
			
			Returns a filtered list of sensors tagged with "corestatesensor" or "probesensor".
			
		.EXAMPLE
			Get-PrtgTableData messages 1002
			
			Returns the messages log for device 1002.
	#>

	Param (		
		[Parameter(Mandatory=$True,Position=0)]
		[ValidateSet("probes","groups","devices","sensors","todos","messages","values","channels","history")]
		[string]$Content,

		[Parameter(Mandatory=$false,Position=1)]
		[int]$ObjectId = 0,

		[Parameter(Mandatory=$False)]
		[string[]]$Columns,

		[Parameter(Mandatory=$False)]
		[string[]]$FilterTags,

		[Parameter(Mandatory=$False)]
		[int]$Count,

		[Parameter(Mandatory=$False)]
		[switch]$Raw
	)

	<# things to add
	
		filter_drel (content = messages only) today, yesterday, 7days, 30days, 12months, 6months - filters messages by timespan
		filter_status (content = sensors only) Unknown=1, Collecting=2, Up=3, Warning=4, Down=5, NoProbe=6, PausedbyUser=7, PausedbyDependency=8, PausedbySchedule=9, Unusual=10, PausedbyLicense=11, PausedUntil=12, DownAcknowledged=13, DownPartial=14 - filters messages by status
		sortby = sorts on named column, ascending (or decending with a leading "-")
		filter_xyz - fulltext filtering. this is a feature in its own right
	
	#>

	BEGIN {
		$PRTG = $Global:PrtgServerObject
		if ($PRTG.Protocol -eq "https") { $PRTG.OverrideValidation() }

		
		$CountProperty = @{}
		$FilterProperty = @{}
		
		if ($Count) {
			$CountProperty =  @{ "count" = $Count }
		}

		
		if ($FilterTags -and (!($Content -eq "sensors"))) {
			throw "Get-PrtgTableData: Parameter FilterTags requires content type sensors"
		} elseif ($Content -eq "sensors" -and $FilterTags) {
			$FilterProperty =  @{ "filter_tags" = $FilterTags }
		}

		if (!$Columns) {
			# this function currently doesn't work with "sensortree" or "maps"

			$TableLookups = @{
				"probes" = @("objid","type","name","tags","active","probe","notifiesx","intervalx","access","dependency","probegroupdevice","status","message","priority","upsens","downsens","downacksens","partialdownsens","warnsens","pausedsens","unusualsens","undefinedsens","totalsens","favorite","schedule","comments","condition","basetype","baselink","parentid","fold","groupnum","devicenum")
				
				"groups" = @("objid","type","name","tags","active","group","probe","notifiesx","intervalx","access","dependency","probegroupdevice","status","message","priority","upsens","downsens","downacksens","partialdownsens","warnsens","pausedsens","unusualsens","undefinedsens","totalsens","favorite","schedule","comments","condition","basetype","baselink","parentid","location","fold","groupnum","devicenum")
				
				"devices" = @("objid","type","name","tags","active","device","group","probe","grpdev","notifiesx","intervalx","access","dependency","probegroupdevice","status","message","priority","upsens","downsens","downacksens","partialdownsens","warnsens","pausedsens","unusualsens","undefinedsens","totalsens","favorite","schedule","deviceicon","comments","host","basetype","baselink","icon","parentid","location")
				
				"sensors" = @("objid","type","name","tags","active","downtime","downtimetime","downtimesince","uptime","uptimetime","uptimesince","knowntime","cumsince","sensor","interval","lastcheck","lastup","lastdown","device","group","probe","grpdev","notifiesx","intervalx","access","dependency","probegroupdevice","status","message","priority","lastvalue","lastvalue_raw","upsens","downsens","downacksens","partialdownsens","warnsens","pausedsens","unusualsens","undefinedsens","totalsens","favorite","schedule","minigraph","comments","basetype","baselink","parentid")
				
				"channels" = @("objid","name","lastvalue","lastvalue_raw")
				
				"todos" = @("objid","datetime","name","status","priority","message","active")
				
				"messages" = @("objid","datetime","parent","type","name","status","message")
				
				"values" = @("datetime","value_","coverage")
				
				"history" = @("datetime","dateonly","timeonly","user","message")
				
				"storedreports" = @("objid","name","datetime","size")
				
				"reports" = @("objid","name","template","period","schedule","email","lastrun","nextrun")
			}
	
			$SelectedColumns = $TableLookups.$Content
		} else {
			$SelectedColumns = $Columns
		}

		$SelectedColumnsString = $SelectedColumns -join ","

		$HTMLColumns = @("downsens","partialdownsens","downacksens","upsens","warnsens","pausedsens","unusualsens","undefinedsens","message","favorite")
	}

	PROCESS {

		$Parameters = @{
			"content" = $Content
			"columns" = $SelectedColumnsString
			"id" = $ObjectId
		} ################################################# needs to handle filters!
		
		$Parameters += $CountProperty
		$Parameters += $FilterProperty
		
		$url = $PrtgServerObject.UrlBuilder("api/table.xml",$Parameters)

		##### data returned; do!

		if ($Raw) {
			$QueryObject = HelperHTTPQuery $url
			return $QueryObject.Data
		}

		$QueryObject = HelperHTTPQuery $url -AsXML
		$Data = $QueryObject.Data

		$ReturnData = @()
		
		<#
		
		HOW THIS WILL LIKELY NEED TO WORK
		---
		
		build a switch statement that uses $Content to determine which types of objects we're going to create
		foreach item, assign all properties to the object
		attach the object to $ReturnData
		
		#>
		
		$PrtgObjectType = switch ($Content) {
			"probes"	{ "PrtgShell.PrtgProbe" }
			"groups"	{ "PrtgShell.PrtgGroup" }
			"devices"	{ "PrtgShell.PrtgDevice" }
			"sensors"	{ "PrtgShell.PrtgSensor" }
			"todos"		{ "PrtgShell.PrtgTodo" }
			"messages"	{ "PrtgShell.PrtgMessage" }
			"values"	{ "PrtgShell.PrtgValue" }
			"channels"	{ "PrtgShell.PrtgChannel" }
			"history"	{ "PrtgShell.PrtgHistory" }
		}
		
		
		

		foreach ($item in $Data.$Content.item) {
			$ThisObject = New-Object $PrtgObjectType
			#$ThisRow = "" | Select-Object $SelectedColumns
			foreach ($Prop in $SelectedColumns) {
				if ($Content -eq "channels" -and $Prop -eq "lastvalue_raw") {
					# fix a bizarre formatting bug
					#$ThisObject.$Prop = HelperFormatHandler $item.$Prop
					$ThisObject.$Prop = $item.$Prop
				} elseif ($HTMLColumns -contains $Prop) {
					# strip HTML, leave bare text
					$ThisObject.$Prop =  $item.$Prop -replace "<[^>]*?>|<[^>]*>", ""
				} else {
					$ThisObject.$Prop = $item.$Prop
				}
			}
			$ReturnData += $ThisObject
		}

		if ($ReturnData.name -eq "Item" -or (!($ReturnData.ToString()))) {
			$DeterminedObjectType = Get-PrtgObjectType $ObjectId

			$ValidQueriesTable = @{
				group=@("devices","groups","sensors","todos","messages","values","history")
				probenode=@("devices","groups","sensors","todos","messages","values","history")
				device=@("sensors","todos","messages","values","history")
				sensor=@("messages","values","channels","history")
				report=@("Currently unsupported")
				map=@("Currently unsupported")
				storedreport=@("Currently unsupported")
			}

			Write-Host "No $Content; Object $ObjectId is type $DeterminedObjectType"
			Write-Host (" Valid query types: " + ($ValidQueriesTable.$DeterminedObjectType -join ", "))
		} else {
			return $ReturnData
		}
	}
}




function Get-PrtgObject {

	Param (
		[Parameter(Mandatory=$false,Position=0)]
		[int]$ObjectId = 0
	)

	BEGIN {
		if ($PRTG.Protocol -eq "https") { $PRTG.OverrideValidation() }
	}

	PROCESS {

		$Parameters = @{
			"content" = "sensortree"
			"id" = $ObjectId
		}
		
		$url = $PrtgServerObject.UrlBuilder("api/table.xml",$Parameters)

		##### data returned; do!

		if ($Raw) {
			$QueryObject = HelperHTTPQuery $url
			return $QueryObject.Data
		}

		$QueryObject = HelperHTTPQuery $url -AsXML
		$Data = $QueryObject.Data

		$DeviceType = $Data.prtg.sensortree.nodes.SelectNodes("*[1]").LocalName
		
		return $Data.prtg.sensortree.nodes.SelectNodes("*[1]")
		
		$ReturnData = @()
		
		<#
		
		HOW THIS WILL LIKELY NEED TO WORK
		---
		
		build a switch statement that uses $Content to determine which types of objects we're going to create
		foreach item, assign all properties to the object
		attach the object to $ReturnData
		
		#>
		
		$PrtgObjectType = switch ($Content) {
			"probes"	{ "PrtgShell.PrtgProbe" }
			"groups"	{ "PrtgShell.PrtgGroup" }
			"devices"	{ "PrtgShell.PrtgDevice" }
			"sensors"	{ "PrtgShell.PrtgSensor" }
			"todos"		{ "PrtgShell.PrtgTodo" }
			"messages"	{ "PrtgShell.PrtgMessage" }
			"values"	{ "PrtgShell.PrtgValue" }
			"channels"	{ "PrtgShell.PrtgChannel" }
			"history"	{ "PrtgShell.PrtgHistory" }
		}
		
		
		

		foreach ($item in $Data.$Content.item) {
			$ThisObject = New-Object $PrtgObjectType
			#$ThisRow = "" | Select-Object $SelectedColumns
			foreach ($Prop in $SelectedColumns) {
				if ($Content -eq "channels" -and $Prop -eq "lastvalue_raw") {
					# fix a bizarre formatting bug
					#$ThisObject.$Prop = HelperFormatHandler $item.$Prop
					$ThisObject.$Prop = $item.$Prop
				} elseif ($HTMLColumns -contains $Prop) {
					# strip HTML, leave bare text
					$ThisObject.$Prop =  $item.$Prop -replace "<[^>]*?>|<[^>]*>", ""
				} else {
					$ThisObject.$Prop = $item.$Prop
				}
			}
			$ReturnData += $ThisObject
		}

		if ($ReturnData.name -eq "Item" -or (!($ReturnData.ToString()))) {
			$DeterminedObjectType = Get-PrtgObjectType $ObjectId

			$ValidQueriesTable = @{
				group=@("devices","groups","sensors","todos","messages","values","history")
				probenode=@("devices","groups","sensors","todos","messages","values","history")
				device=@("sensors","todos","messages","values","history")
				sensor=@("messages","values","channels","history")
				report=@("Currently unsupported")
				map=@("Currently unsupported")
				storedreport=@("Currently unsupported")
			}

			Write-Host "No $Content; Object $ObjectId is type $DeterminedObjectType"
			Write-Host (" Valid query types: " + ($ValidQueriesTable.$DeterminedObjectType -join ", "))
		} else {
			return $ReturnData
		}
	}
}

###############################################################################

function New-PrtgSensor {
    Param (
        [Parameter(Mandatory=$True,Position=0)]
        [PrtgShell.PrtgSensorCreator]$PrtgObject
    )

    BEGIN {
        if (!($PrtgServerObject.Server)) { Throw "Not connected to a server!" }
		$PrtgServerObject.OverrideValidation()
    }

    PROCESS {

        $Url = $PrtgServerObject.UrlBuilder("addsensor5.htm")

        HelperHTTPPostCommand $Url $PrtgObject.QueryString | Out-Null

    }
}

###############################################################################

function New-PrtgResult {
    <#
		.SYNOPSIS
			Creates a PrtgShell.XmlResult object for use in ExeXml output.
			
		.DESCRIPTION
			Creates a PrtgShell.XmlResult object for use in ExeXml output.
		
		.PARAMETER Channel
			Name of the channel.
			
		.PARAMETER Value
            Integer value of the channel.
		
		.PARAMETER Unit
			Unit of the value.
			
		.PARAMETER SpeedSize
			Size of the value given, used for speed measurements.
			
		.PARAMETER VolumeSize
			Size of the value given, used for disk/file measurements.
			
		.PARAMETER SpeedTime
			Interval for displaying a speed measurement.

		.PARAMETER Difference
            Set the value as a difference value, as opposed to absolute.

        .PARAMETER DecimalMode
            Set the decimal display mode.

        .PARAMETER Warning
            Enable warning state for channel.

        .PARAMETER IsFloat
            Specify the value is a float, instead of integer.

        .PARAMETER ShowChart
            Show the channel in the charts section of the web ui.

        .PARAMETER ShowTable
            Show the channel in the table section of the web ui.

        .PARAMETER LimitMaxError
            Set the maximum value before a channel goes into an error state.  Only applies the first time a channel is reported to as sensor.

        .PARAMETER LimitMinError
            Set the minimum value before a channel goes into an error state.  Only applies the first time a channel is reported to as sensor.

        .PARAMETER LimitMaxWarning
            Set the maximum value before a channel goes into a warning state.  Only applies the first time a channel is reported to as sensor.

        .PARAMETER LimitMinWarning
            Set the minimum value before a channel goes into a warning state.  Only applies the first time a channel is reported to as sensor.

        .PARAMETER LimitErrorMsg
            Set the message reported when the channel goes into an error state.  Only applies the first time a channel is reported to as sensor.

        .PARAMETER LimitMaxError
            Set the message reported when the channel goes into a warning state.  Only applies the first time a channel is reported to as sensor.

        .PARAMETER LimitMode
            Set if the Limits defined are active.

        .PARAMETER ValueLookup
            Set a custom lookup file for the channel.
	#>
    PARAM (
        [Parameter(Mandatory=$True,Position=0)]
        [string]$Channel,

        [Parameter(Mandatory=$True,Position=1)]
        [decimal]$Value,

        [Parameter(Mandatory=$False)]
        [string]$Unit,

        [Parameter(Mandatory=$False)]
        [Alias('ss')]
        [ValidateSet("one","kilo","mega","giga","tera","byte","kilobyte","megabyte","gigabyte","terabyte","bit","kilobit","megabit","gigabit","terabit")]
        [string]$SpeedSize,

        [Parameter(Mandatory=$False)]
        [Alias('vs')]
        [ValidateSet("one","kilo","mega","giga","tera","byte","kilobyte","megabyte","gigabyte","terabyte","bit","kilobit","megabit","gigabit","terabit")]
        [string]$VolumeSize,

        [Parameter(Mandatory=$False)]
        [Alias('st')]
        [ValidateSet("second","minute","hour","day")]
        [string]$SpeedTime,

        [Parameter(Mandatory=$False)]
        [switch]$Difference,

        [Parameter(Mandatory=$False)]
        [Alias('dm')]
        [ValidateSet("auto","all")]
        [string]$DecimalMode,

        [Parameter(Mandatory=$False)]
        [switch]$Warning,

        [Parameter(Mandatory=$False)]
        [switch]$IsFloat,

        [Parameter(Mandatory=$False)]
        [Alias('sc')]
        [switch]$ShowChart,

        [Parameter(Mandatory=$False)]
        #[Alias('st')] # also the alias to "speedtime"
        [switch]$ShowTable,

        [Parameter(Mandatory=$False)]
        [int]$LimitMaxError,

        [Parameter(Mandatory=$False)]
        [int]$LimitMinError,

        [Parameter(Mandatory=$False)]
        [int]$LimitMaxWarning,

        [Parameter(Mandatory=$False)]
        [int]$LimitMinWarning,

        [Parameter(Mandatory=$False)]
        [string]$LimitErrorMsg,

        [Parameter(Mandatory=$False)]
        [string]$LimitWarningMsg,

        [Parameter(Mandatory=$False)]
        [Alias('lm')]
        [switch]$LimitMode,

        [Parameter(Mandatory=$False)]
        [Alias('vl')]
        [string]$ValueLookup
    )

    BEGIN {
    }

    PROCESS {
        $ReturnObject = New-Object PrtgShell.XmlResult

        $ReturnObject.channel         = $Channel
        $ReturnObject.resultvalue     = $Value
        $ReturnObject.unit            = $Unit
        $ReturnObject.speedsize       = $SpeedSize
        $ReturnObject.volumesize      = $VolumeSize
        $ReturnObject.speedtime       = $SpeedTime
        $ReturnObject.mode            = $Mode
        $ReturnObject.decimalmode     = $DecimalMode
        $ReturnObject.Warning         = $Warning
        $ReturnObject.isfloat         = $IsFloat
        $ReturnObject.showchart       = $ShowChart
        $ReturnObject.showtable       = $ShowTable
        $ReturnObject.limitmaxerror   = $LimitMaxError
        $ReturnObject.limitminerror   = $LimitMinError
        $ReturnObject.limitmaxwarning = $LimitMaxWarning
        $ReturnObject.limitminwarning = $LimitMinWarning
        $ReturnObject.limiterrormsg   = $LimitErrorMsg
        $ReturnObject.limitwarningmsg = $LimitWarningMsg
        $ReturnObject.limitmode       = $LimitMode
        $ReturnObject.valuelookup     = $ValueLookup

        return $ReturnObject
    }
}

###############################################################################



function HelperHTTPQuery {
	Param (
		[Parameter(Mandatory=$True,Position=0)]
		[string]$URL,

		[Parameter(Mandatory=$False)]
		[alias('xml')]
		[switch]$AsXML
	)

	try {
		$Response = $null
		$Request = [System.Net.HttpWebRequest]::Create($URL)
		$Response = $Request.GetResponse()
		if ($Response) {
			$StatusCode = $Response.StatusCode.value__
			$DetailedError = $Response.GetResponseHeader("X-Detailed-Error")
		}
	}
	catch {
		$ErrorMessage = $Error[0].Exception.ErrorRecord.Exception.Message
		$Matched = ($ErrorMessage -match '[0-9]{3}')
		if ($Matched) {
			throw ('HTTP status code was {0} ({1})' -f $HttpStatusCode, $matches[0])
		}
		else {
			throw $ErrorMessage
		}

		#$Response = $Error[0].Exception.InnerException.Response
		#$Response.GetResponseHeader("X-Detailed-Error")
	}

	if ($Response.StatusCode -eq "OK") {
		$Stream    = $Response.GetResponseStream()
		$Reader    = New-Object IO.StreamReader($Stream)
		$FullPage  = $Reader.ReadToEnd()

		if ($AsXML) {
			$Data = [xml]$FullPage
		} else {
			$Data = $FullPage
		}

		$Global:LastResponse = $Data

		$Reader.Close()
		$Stream.Close()
		$Response.Close()
	} else {
		Throw "Error Accessing Page $FullPage"
	}

	$ReturnObject = "" | Select-Object StatusCode,DetailedError,Data
	$ReturnObject.StatusCode = $StatusCode
	$ReturnObject.DetailedError = $DetailedError
	$ReturnObject.Data = $Data

	return $ReturnObject
}

function HelperHTTPPostCommand() {
	param(
		[string] $url = $null,
		[string] $data = $null,
		[System.Net.NetworkCredential]$credentials = $null,
		[string] $contentType = "application/x-www-form-urlencoded",
		[string] $codePageName = "UTF-8",
		[string] $userAgent = $null
	);

	if ( $url -and $data ) {
		[System.Net.WebRequest]$webRequest = [System.Net.WebRequest]::Create($url);
		$webRequest.ServicePoint.Expect100Continue = $false;
		if ( $credentials ) {
			$webRequest.Credentials = $credentials;
			$webRequest.PreAuthenticate = $true;
		}
		$webRequest.ContentType = $contentType;
		$webRequest.Method = "POST";
		if ( $userAgent ) {
			$webRequest.UserAgent = $userAgent;
		}

		$enc = [System.Text.Encoding]::GetEncoding($codePageName);
		[byte[]]$bytes = $enc.GetBytes($data);
		$webRequest.ContentLength = $bytes.Length;
		[System.IO.Stream]$reqStream = $webRequest.GetRequestStream();
		$reqStream.Write($bytes, 0, $bytes.Length);
		$reqStream.Flush();

		$resp = $webRequest.GetResponse();
		$rs = $resp.GetResponseStream();
		[System.IO.StreamReader]$sr = New-Object System.IO.StreamReader -argumentList $rs;
		$sr.ReadToEnd();
	}
}

function HelperFormatTest {
	$URLKeeper = $global:lasturl

	$CoreHealthChannels = Get-PrtgSensorChannels 1002
	$HealthPercentage = $CoreHealthChannels | ? {$_.name -eq "Health" }
	$ValuePretty = [int]$HealthPercentage.lastvalue.Replace("%","")
	$ValueRaw = [int]$HealthPercentage.lastvalue_raw

	if ($ValueRaw -eq $ValuePretty) {
		$RawFormatError = $false
	} else {
		$RawFormatError = $true
	}

	$global:lasturl = $URLKeeper

	$StoredConfiguration = $Global:PrtgServerObject | Select-Object *,RawFormatError
	$StoredConfiguration.RawFormatError = $RawFormatError

	$global:PrtgServerObject = $StoredConfiguration
}

function HelperFormatHandler {
    Param (
        [Parameter(Mandatory=$False,Position=0)]
        $InputData
	)

	if (!$InputData) { return }

	if ($Global:PrtgServerObject.RawFormatError) {
		# format includes the quirk
		return [double]$InputData.Replace("0.",".")
	} else {
		# format doesn't include the quirk, pass it back
		return [double]$InputData
	}
}

###############################################################################
## PowerShell Module Functions
###############################################################################

Export-ModuleMember *-*