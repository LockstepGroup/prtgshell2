
function New-PrtgDevice {
    Param (
        [Parameter(Mandatory=$True,Position=0)]
        [PrtgShell.PrtgDeviceCreator]$PrtgObject
    )

    BEGIN {
        if (!($PrtgServerObject.Server)) { Throw "Not connected to a server!" }
		$PrtgServerObject.OverrideValidation()
    }

    PROCESS {

        $Url = $PrtgServerObject.UrlBuilder("adddevice2.htm")

        HelperHTTPPostCommand $Url $PrtgObject.QueryString

    }
}