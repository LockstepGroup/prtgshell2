
function Set-PrtgObjectProperty {
        <#
        .SYNOPSIS
                
        .DESCRIPTION
                
        .EXAMPLE
                
        #>

    Param (
		[Parameter(Mandatory=$True,Position=0)]
		[int]$ObjectId,

		[Parameter(Mandatory=$True,Position=1)]
		[string]$Property,

		[Parameter(Mandatory=$True,Position=2)]
		[string]$Value
    )

	BEGIN {
		if (!($PrtgServerObject.Server)) { Throw "Not connected to a server!" }
	}

    PROCESS {
		$Url = $PrtgServerObject.UrlBuilder("api/setobjectproperty.htm",@{
			"id"		= $ObjectId
			"name" 		= $Property
			"value" 	= $Value
		})
		
		$Data = $PrtgServerObject.HttpQuery($Url,$false)
		
		return $Data.RawData -replace "<[^>]*?>|<[^>]*>", ""
	}
}
