
function New-PrtgGroup {
    Param (
        [Parameter(Mandatory=$True,Position=0)]
        [PrtgShell.PrtgGroupCreator]$PrtgObject
    )

    BEGIN {
        if (!($PrtgServerObject.Server)) { Throw "Not connected to a server!" }
		$PrtgServerObject.OverrideValidation()
    }

    PROCESS {

        $Url = $PrtgServerObject.UrlBuilder("addgroup2.htm")

        HelperHTTPPostCommand $Url $PrtgObject.QueryString | Out-Null

    }
}