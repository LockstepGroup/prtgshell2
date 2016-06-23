
function New-PrtgSensor {
    Param (
        [Parameter(Mandatory=$True,Position=0)]
        [PrtgShell.PrtgSensorCreator]$PrtgObject
    )

    BEGIN {
        if (!($PrtgServerObject.Server)) { Throw "Not connected to a server!" }
		$PrtgServerObject.OverrideValidation()
    }

    PROCESS {

        $Url = $PrtgServerObject.UrlBuilder("addsensor5.htm")

        HelperHTTPPostCommand $Url $PrtgObject.QueryString | Out-Null

    }
}