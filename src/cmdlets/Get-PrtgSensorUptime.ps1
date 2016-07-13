
# optional thing to add here:
# make it so we can define a target month in this report, rather than manually specifying the start and end date.


function Get-PrtgSensorUptime {
	<#
	.SYNOPSIS
		Returns five-nines-style uptime for a specified time period from a sensor object.
	.DESCRIPTION
		Returns five-nines-style uptime for a specified time period from a sensor object.
	.PARAMETER SensorId
		The sensor to retrieve data for.
	.PARAMETER RangeStart
		DateTime object specifying the start of the history range.
	.PARAMETER RangeEnd
		DateTime object specifying the End of the history range.
	.EXAMPLE
		 Get-PrtgSensorUptime 2321 (Get-Date "2016-06-23 12:15") (Get-Date "2016-06-23 16:15")
	#>

	[CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,Position=0)]
        [int] $SensorId,

		[Parameter(Mandatory=$true,Position=1)]
		[datetime] $RangeStart,
		
		[Parameter(Mandatory=$false,Position=2)]
		[datetime] $RangeEnd		
    )

    BEGIN {
		$PrtgServerObject = $Global:PrtgServerObject
		
		if (!$RangeEnd) {
			$RangeStart = Get-Date ($RangeStart.ToString('MMMM yyyy'))
			$RangeEnd = $RangeStart.AddMonths(1).AddSeconds(-1)
		}
    }

    PROCESS {
		$ObjectInterval = Get-PrtgObject $SensorId | Select-Object -ExpandProperty interval
		
		$HistoricData = Get-PrtgSensorHistoricData $SensorId $RangeStart $RangeEnd 0
		
		$APropertyName = (($HistoricData | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name) -notmatch "Coverage") -notmatch "Date Time" | Select-Object -First 1
		
		# maybe this is valid?
		$UpEntries = $HistoricData.$APropertyName | ? { $_ -ne "" }
		
	}
	
	END {
		$returnobject = "" | select SensorId,RangeStart,RangeEnd,TotalDatapoints,UpDatapoints,DownDatapoints,Interval,UptimePercentage
		$returnobject.SensorId = $SensorId
		$returnobject.RangeStart = $RangeStart
		$returnobject.RangeEnd = $RangeEnd
		$returnobject.TotalDatapoints = $HistoricData.Count
		$returnobject.UpDatapoints = $UpEntries.Count
		$returnobject.DownDatapoints = $HistoricData.Count - $UpEntries.Count
		$returnobject.Interval = $ObjectInterval
		if ($HistoricData.Count) {
			$returnobject.UptimePercentage = ($UpEntries.Count / $HistoricData.Count) * 100
		} else { 
			$returnobject.UptimePercentage = 0
		}
		
		return $returnobject
    }
}
