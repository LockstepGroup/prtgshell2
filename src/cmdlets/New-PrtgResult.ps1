
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

		# note that both showchart and showtable default to "TRUE" in the actual API
		# which is to say, if they're not defined, they're assumed to be true
		# this is also true in the c# object that generates the XML,
		# but it is NOT assumed to be true here.
		# This is the part of the code that always puts in the showchart and showtables tags with zeroes!
        [Parameter(Mandatory=$False)]
        [Alias('sc')]
        [switch]$ShowChart,

        [Parameter(Mandatory=$False)]
        #[Alias('st')] # also the alias to "speedtime"
        [switch]$ShowTable,

        [Parameter(Mandatory=$False)]
        [int]$LimitMaxError = -1,

        [Parameter(Mandatory=$False)]
        [int]$LimitMinError = -1,

        [Parameter(Mandatory=$False)]
        [int]$LimitMaxWarning = -1,

        [Parameter(Mandatory=$False)]
        [int]$LimitMinWarning = -1,

        [Parameter(Mandatory=$False)]
        [string]$LimitErrorMsg,

        [Parameter(Mandatory=$False)]
        [string]$LimitWarningMsg,

        #[Parameter(Mandatory=$False)]
        #[Alias('lm')]
        #[switch]$LimitMode,

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
        $ReturnObject.valuemode       = $Mode # had to rename the object property; needs revisiting
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
        #$ReturnObject.limitmode       = $LimitMode # read-only automatically-determined property. any reason we shouldn't do this?
        $ReturnObject.valuelookup     = $ValueLookup

        return $ReturnObject
    }
}