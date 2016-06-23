
function Get-PrtgSensorHistoricData {
	<#
	.SYNOPSIS
		Returns historic data from a specified time period from a sensor object.
	.DESCRIPTION
		Returns a table of data using the specified start and end dates and the specified interval.
	.PARAMETER SensorId
		The sensor to retrieve data for.
	.PARAMETER RangeStart
		DateTime object specifying the start of the history range.
	.PARAMETER RangeEnd
		DateTime object specifying the End of the history range.
	.PARAMETER IntervalInSeconds
		The minimum interval to include, in seconds. The default is one hour (3600 seconds). A value of zero (0) will return raw data. 
	.EXAMPLE
		Get-PrtgSensorHistoricData 2321 (Get-Date "2016-06-23 12:15") (Get-Date "2016-06-23 16:15") 60
	#>

	[CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True,Position=0)]
        [int] $SensorId,

		[Parameter(Mandatory=$True,Position=1)]
		[datetime] $RangeStart,
		
		[Parameter(Mandatory=$True,Position=2)]
		[datetime] $RangeEnd,
		
		[Parameter(Mandatory=$True,Position=3)]
		[int] $IntervalInSeconds = 3600
    )

    BEGIN {
		$PrtgServerObject = $Global:PrtgServerObject
    }

    PROCESS {
		$Parameters = @{
			"id" = $SensorId
			"sdate" = $RangeStart.ToString("yyyy-MM-dd-HH-mm-ss")
			"edate" = $RangeEnd.ToString("yyyy-MM-dd-HH-mm-ss")
			"avg" = $IntervalInSeconds
		}
		
		$url = $PrtgServerObject.UrlBuilder("api/historicdata.csv",$Parameters)
		
		$QueryObject = $PrtgServerObject.HttpQuery($url,$false)
		
		$DataPoints = $QueryObject.RawData | ConvertFrom-Csv | ? { $_.'Date Time' -ne 'Averages' }
		
		#$APropertyName = (($DataPoints | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name) -notmatch "Coverage") -notmatch "Date Time" | Select-Object -First 1
	}
	
	END {
		return $DataPoints
    }
}
