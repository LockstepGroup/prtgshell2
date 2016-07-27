
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

	[CmdletBinding()]
	Param (		
		[Parameter(Mandatory=$True,Position=0)]
		[ValidateSet("probes","groups","devices","sensors","todos","messages","values","channels","history","maps")]
		[string]$Content,

		[Parameter(Mandatory=$false,Position=1)]
		[int]$ObjectId = 0,

		[Parameter(Mandatory=$False)]
		[string[]]$Columns,

		[Parameter(Mandatory=$False)]
		[string[]]$FilterTags,
		
		[Parameter(Mandatory=$False)]
		[ValidateSet("Unknown","Collecting","Up","Warning","Down","NoProbe","PausedbyUser","PausedbyDependency","PausedbySchedule","Unusual","PausedbyLicense","PausedUntil","DownAcknowledged","DownPartial")]
		[string[]]$FilterStatus,
		
		[Parameter(Mandatory=$False)]
		[string]$FilterTarget,
		
		[Parameter(Mandatory=$False)]
		[string]$FilterValue,

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
		
		$CountProperty = @{}
		$FilterProperty = @{}
		
		if ($Count) {
			$CountProperty =  @{ "count" = $Count }
		}

		
		if ($FilterTags -and (!($Content -eq "sensors"))) {
			throw "Get-PrtgTableData: Parameter FilterTags requires content type sensors"
		} elseif ($Content -eq "sensors" -and $FilterTags) {
			$FilterProperty += @{ "filter_tags" = $FilterTags }
		}
		
		$StatusFilterCodes = @{
			"Unknown" = 1
			"Collecting" = 2
			"Up" = 3
			"Warning" = 4
			"Down" = 5
			"NoProbe" = 6
			"PausedbyUser" = 7
			"PausedbyDependency" = 8
			"PausedbySchedule" = 9
			"Unusual" = 10
			"PausedbyLicense" = 11
			"PausedUntil" = 12
			"DownAcknowledged" = 13
			"DownPartial" = 14
		}
		
		if ($FilterStatus -and (!($Content -eq "sensors"))) {
			throw "Get-PrtgTableData: Parameter FilterStatus requires content type sensors"
		} elseif ($Content -eq "sensors" -and $FilterStatus) {
			# I apparently wrote some code that gracefully
			# handles this (multiple properties w/ same name) two years ago.
			# good job, past josh
			$FilterProperty += @{ "filter_status" = $StatusFilterCodes[$FilterStatus] }
		}
		
		if ($FilterTarget) {
			if (!$FilterValue) {
				throw "Get-PrtgTableData: Parameter FilterTarget requires parameter FilterValue also"
			}
			$FilterName = "filter_" + $FilterTarget
			$FilterProperty += @{ $FilterName = $FilterValue }
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
				
				"maps" = @("objid","name")
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
			$QueryObject = $PrtgServerObject.HttpQuery($url,$false)
			return $QueryObject.Data
		}

		$QueryObject = $PrtgServerObject.HttpQuery($url)
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
		
		if ($Data.$Content.item.childnodes.count) { # this will return zero if there's an empty set
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
		} else {
			$ErrorString = "Object" + $ObjectId + " contains no objects of type" + $Content
			if ($FilterProperty.Count) {
				$ErrorString += " matching specified filter parameters"
			}
			
			Write-Host $ErrorString
		}

		<#
		# this section needs to be revisited
		# if the filter ends up returning an empty set, we need to say so, or return said empty said
		# and we also need to make the "get-prtgobjecttype" cmdlet that this depends on
		
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
		
		#>
		
		return $ReturnData
	}
}
