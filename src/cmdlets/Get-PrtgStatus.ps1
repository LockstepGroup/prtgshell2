
function Get-PrtgStatus {

	# this is nowhere near complete or useful. the data returned by this control is tagged HTML with untagged, unlabelled, unidentified data, which could be immensely useful. if it was structured.
	
	BEGIN {
		if ($PRTG.Protocol -eq "https") { $PRTG.OverrideValidation() }
	}

	PROCESS {

		$Parameters = @{
			"content" = "sensortree"
			"id" = $ObjectId
		}
		
		$url = $PrtgServerObject.UrlBuilder("controls/systemstatus.htm")
		$QueryObject = HelperHTTPQuery $url
		return $QueryObject.Data
	}
}