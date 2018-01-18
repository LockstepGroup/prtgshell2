
<#

actions.

resume
pause indefinitely (with message)
pause for a duration of minutes (with message)
or - pause until a datetime
set maintenance window (start/stop)


#>


function Set-PrtgObjectPause {
	<#
		.SYNOPSIS
			Pauses or resumes the specified PRTG object.
			
		.DESCRIPTION
			The Set-PrtgObjectPause cmdlet can be used to pause or resume an object, optionally with a message, for a specified duration, until a specified time, or as a one-time maintenance window.
		
		.PARAMETER PrtgObjectId
			An integer representing the target IDs to modify.
			
		.PARAMETER Resume
			Switch to resume the specified object and remove the paused state.
		
		.PARAMETER Message
			The string message to note on the object as the pause reason.
			
		.PARAMETER DurationInMins
			An integer specifying the duration of the paused state.
			
		.PARAMETER Until
			A datetime specifying the end of the paused state.
			
		.PARAMETER MaintenanceStart
			A datetime specifying the start of the one-time maintenance window.
			
		.PARAMETER MaintenanceStop
			A datetime specifying the end of the one-time maintenance window.
			
		.EXAMPLE
			Set-PrtgObjectPause 12345 -DurationInMins 10
			
			Pauses the object with ID 12345 for a duration of 10 minutes.
			
		.EXAMPLE
			Set-PrtgObjectPause 12345 -Until (Get-Date "4pm") -Message "Application recovery"
			
			Pauses the object with ID 12345 until 4:00 PM with the message "Application recovery".

		.EXAMPLE
			Set-PrtgObjectPause 12345 -MaintenanceStart (Get-Date "4pm") -MaintenanceStop (Get-Date "5pm")
			
			Reconfigures the object with ID 12345 for a maintenance window of 4:00 PM to 5:00 PM.
		
		.EXAMPLE
			Set-PrtgObjectPause 12345 -Resume
			
			Resumes the object with ID 12345, clearing the paused state and associated message.
		
	#>
	
	[CmdletBinding(DefaultParameterSetName="indefinite")]
    Param (
		[Parameter(Position = 0, Mandatory = $true)]
		[alias("id")]
		[int[]]$PrtgObjectId,
		
		[Parameter(ParameterSetName = "resume")]
		[switch]$Resume,
		
		[Parameter(Mandatory = $false, ParameterSetName = "indefinite")]
		[Parameter(Mandatory = $false, ParameterSetName = "duration")]
		[Parameter(Mandatory = $false, ParameterSetName = "until")]
		[string]$Message,
		
		[Parameter(Mandatory = $true, ParameterSetName = "duration")]
		[alias("duration")]
		[int]$DurationInMins,
		
		[Parameter(Mandatory = $true, ParameterSetName = "until")]
		[datetime]$Until,
		
		[Parameter(Mandatory = $true, ParameterSetName = "maintenance")]
		[datetime]$MaintenanceStart,
		
		[Parameter(Mandatory = $true, ParameterSetName = "maintenance")]
		[datetime]$MaintenanceStop
    )

    BEGIN {
        if (!($PrtgServerObject.Server)) { Throw "Not connected to a server!" }
		$PrtgServerObject.OverrideValidation()
    }

    PROCESS {
		
		switch ($PSCmdlet.ParameterSetName) {
			"resume" {
				$Url = $PrtgServerObject.UrlBuilder("api/pause.htm")
				
				$QueryStringTable = @{
					"id" 		= $PrtgObjectId
					"action"	= 1
				}
			}
			
			"indefinite" {
				$Url = $PrtgServerObject.UrlBuilder("api/pause.htm")
				
				$QueryStringTable = @{
					"id" 		= $PrtgObjectId
					"action"	= 0
				}
				
				if ($Message) { $QueryStringTable['pausemsg'] = $Message }
			}
			
			"duration" {
				$Url = $PrtgServerObject.UrlBuilder("api/pauseobjectfor.htm")
				
				$QueryStringTable = @{
					"id" 		= $PrtgObjectId
					"action"	= 0
					"duration"	= $DurationInMins
				}
				
				if ($Message) { $QueryStringTable['pausemsg'] = $Message }
			}
			
			"until" {
				$Url = $PrtgServerObject.UrlBuilder("api/pauseobjectfor.htm")
				
				$QueryStringTable = @{
					"id" 		= $PrtgObjectId
					"action"	= 0
					"duration"	= [int]($Until - (Get-Date)).TotalMinutes
				}
				
				if ($Message) { $QueryStringTable['pausemsg'] = $Message }
			}
			
			"maintenance" {
				$Url = $PrtgServerObject.UrlBuilder("editsettings")
				
				$QueryStringTable = @{
					"id" 			= $PrtgObjectId
					"maintstart_"	= (Get-Date $MaintenanceStart -Format "yyyy-MM-dd-HH-mm-ss")
					"maintend_"		= (Get-Date $MaintenanceStop -Format "yyyy-MM-dd-HH-mm-ss")
					"maintenable_"	= 1
				}
			}
		}
	
		# create a blank, writable HttpValueCollection object
		$QueryString = [System.Web.httputility]::ParseQueryString("")

		# iterate through the hashtable and add the values to the HttpValueCollection
		foreach ($Pair in $QueryStringTable.GetEnumerator()) {
			$QueryString[$($Pair.Name)] = $($Pair.Value)
		}

		$QueryString = $QueryString.ToString()

		HelperHTTPPostCommand $Url $QueryString | Out-Null
    }
}
