
function Move-PrtgObject {
	<#
	.SYNOPSIS
		
	.DESCRIPTION
		
	.EXAMPLE
		
	#>

	Param (
		[Parameter(Mandatory=$True,Position=0)]
		[int]$ObjectId,
        [Parameter(Mandatory=$True,Position=1)]
        [int]$TargetGroupId
	)

    BEGIN {
        if (!($PrtgServerObject.Server)) { Throw "Not connected to a server!" }
    }

    PROCESS {
	
		$Url = $PrtgServerObject.UrlBuilder("moveobjectnow.htm",@{
			"id" = $ObjectId
			"targetid" = $TargetGroupId
			"approve" = 1
		})
		
		$Data = $PrtgServerObject.HttpQuery($Url,$false)
		
		return $Data | select HttpStatusCode,Statuscode
    }
}
