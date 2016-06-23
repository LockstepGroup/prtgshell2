
# remove-prtgobject
# needs to accept: an ID (the old way)
# a string of IDs (will this work?)
# a single prtgshell object object
# or an array of prtgshell object objects


# for handling objects
# needs to string together the objids from the objects received
# and then in the END block, execute the actual DO

function Remove-PrtgObject {
	<#
	.SYNOPSIS
		
	.DESCRIPTION
		
	.EXAMPLE
		
	#>

	Param (
		[Parameter(Mandatory=$True,Position=0)]
		[int[]]$ObjectId
		#TODO: document this; $ObjectID for this cmdlet can either be a single integer or a comma-separated string of integers to handle multiples
	)

    BEGIN {
        if (!($PrtgServerObject.Server)) { Throw "Not connected to a server!" }
    }

    PROCESS {
		[string]$ObjectId = $ObjectId -join ","
	
		$Url = $PrtgServerObject.UrlBuilder("deleteobject.htm",@{
			"id" = $ObjectId
			"approve" = 1
		})
		
		$Data = $PrtgServerObject.HttpQuery($Url,$false)
		
		return $Data | select HttpStatusCode,Statuscode
    }
}
