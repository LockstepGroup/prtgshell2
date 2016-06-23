
function Set-PrtgSetting {
	<#
		.SYNOPSIS
			Sets the specified parameter(s) to the provided value(s) on the specified PRTG object(s).
			
		.DESCRIPTION
			The Set-PrtgSetting cmdlet can be used to set any reachable setting in any reachable object, or multiple settings on multiple objects. The only explicitly required parameter is the "id" parameter, which specifies one or more target objects to configure. Different object types accept different parameters.
		
		.PARAMETER PrtgObjectId
			An integer (or array of integers) representing the target IDs to modify.
			
		.PARAMETER PrtgObjectProperty
			The name of the parameter to modify. Note that many parameter names in PRTG have trailing underscores; this cmdlet currently does no validation on input.
		
		.PARAMETER PrtgObjectPropertyValue
			The value to set the PrtgObjectProperty to.
			
		.PARAMETER PrtgSettingHashtable
			A hashtable containing the IDs and properties you wish to configure. Ensure that the hashtable contains an "id" property.
			
		.EXAMPLE
			Set-PrtgSetting 1 name_ "Core Server" 
			
			Renames the local probe object (ID = 1) to "Core Server".
		
		.EXAMPLE
			$table = @{ "id" = 2076,2077,2070; "priority_" = 3; "tags_" = "newsensortag"}
			Set-PrtgSetting -table $table
			
			Sets the priority of sensors 2076, 2077, and 2070 to "3" and overwrites the current tag settings with "newsensortag".
	#>

    Param (
		[Parameter(Position = 0, Mandatory = $true)]
		[alias("id")]
		[int[]]$PrtgObjectId,
		
		[Parameter(Position = 1, Mandatory = $true, ParameterSetName = "singleproperty")]
		[alias("property")]
		[string]$PrtgObjectProperty,
		
		[Parameter(Position = 2, Mandatory = $true, ParameterSetName = "singleproperty")]
		[alias("value")]
		$PrtgObjectPropertyValue,
		
		[Parameter(Position = 1, ParameterSetName = "multipleproperties")]
		[alias("table")]
		[hashtable]$PrtgSettingHashtable
    )

    BEGIN {
        if (!($PrtgServerObject.Server)) { Throw "Not connected to a server!" }
		$PrtgServerObject.OverrideValidation()
    }

    PROCESS {

        $Url = $PrtgServerObject.UrlBuilder("editsettings")
		
		if ($PrtgObjectId) {
			if ($PrtgObjectId.Count -gt 1) {
				[string]$PrtgObjectId = $PrtgObjectId -join ","
			}
			
			$QueryStringTable = @{
				"id" 					= $PrtgObjectId
				$PrtgObjectProperty		= $PrtgObjectPropertyValue
			}
			
			if ($PrtgSettingHashtable) {
				$QueryStringTable += $PrtgSettingHashtable
			}
		} else {
			if ($PrtgSettingHashtable.id) {
				$QueryStringTable = $PrtgSettingHashtable
			} else {
				throw "Command requires Object ID!"
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
