function Get-PrtgServer {
	<#
	.SYNOPSIS
		Establishes initial connection to PRTG API.
		
	.DESCRIPTION
		The Get-PrtgServer cmdlet establishes and validates connection parameters to allow further communications to the PRTG API. The cmdlet needs at least three parameters:
		 - The server name (without the protocol)
		 - An authenticated username
		 - A passhash that can be retrieved from the PRTG user's "My Account" page.
		
		
		The cmdlet returns an object containing details of the connection, but this can be discarded or saved as desired; the returned object is not necessary to provide to further calls to the API.
	
	.EXAMPLE
		Get-PrtgServer "prtg.company.com" "jsmith" 1234567890
		
		Connects to PRTG using the default port (443) over SSL (HTTPS) using the username "jsmith" and the passhash 1234567890.
		
	.EXAMPLE
		Get-PrtgServer "prtg.company.com" "jsmith" 1234567890 -HttpOnly
		
		Connects to PRTG using the default port (80) over SSL (HTTP) using the username "jsmith" and the passhash 1234567890.
		
	.EXAMPLE
		Get-PrtgServer -Server "monitoring.domain.local" -UserName "prtgadmin" -PassHash 1234567890 -Port 8080 -HttpOnly
		
		Connects to PRTG using port 8080 over HTTP using the username "prtgadmin" and the passhash 1234567890.
		
	.PARAMETER Server
		Fully-qualified domain name for the PRTG server. Don't include the protocol part ("https://" or "http://").
		
	.PARAMETER UserName
		PRTG username to use for authentication to the API.
		
	.PARAMETER PassHash
		PassHash for the PRTG username. This can be retrieved from the PRTG user's "My Account" page.
	
	.PARAMETER Port
		The port that PRTG is running on. This defaults to port 443 over HTTPS, and port 80 over HTTP.
	
	.PARAMETER HttpOnly
		When specified, configures the API connection to run over HTTP rather than the default HTTPS.
		
	.PARAMETER Quiet
		When specified, the cmdlet returns nothing on success.
	#>

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$True,Position=0)]
		[ValidatePattern("\d+\.\d+\.\d+\.\d+|(\w\.)+\w")]
		[string]$Server,

		[Parameter(Mandatory=$True,Position=1)]
		[string]$UserName,

		[Parameter(Mandatory=$True,Position=2)]
		[string]$PassHash,

		[Parameter(Mandatory=$False,Position=3)]
		[int]$Port = $null,

		[Parameter(Mandatory=$False)]
		[alias('http')]
		[switch]$HttpOnly,
		
		[Parameter(Mandatory=$False)]
		[alias('q')]
		[switch]$Quiet
	)

    BEGIN {
		
		$PrtgServerObject = New-Object PrtgShell.PrtgServer
		
		$PrtgServerObject.Server   = $Server
		$PrtgServerObject.UserName = $UserName
		$PrtgServerObject.PassHash = $PassHash
		
		if ($HttpOnly) {
			$Protocol = "http"
			if (!$Port) { $Port = 80 }
			
		} else {
			$Protocol = "https"
			if (!$Port) { $Port = 443 }
			
			#$PrtgServerObject.OverrideValidation()
		}
		
		$PrtgServerObject.Protocol = $Protocol
		$PrtgServerObject.Port     = $Port
    }

    PROCESS {
		$url = $PrtgServerObject.UrlBuilder("api/getstatus.xml")

		try {
			#$QueryObject = HelperHTTPQuery $url -AsXML
			#$PrtgServerObject.OverrideValidation()
			$QueryObject = $PrtgServerObject.HttpQuery($url)
		} catch {
			throw "Error performing HTTP query"
		}
		
		$Data = $QueryObject.Data

		# the logic and future-proofing of this is a bit on the suspect side.
		# the idea is that we want to get all the properties that it returns
		# and shove them into our new object, but if the object is missing 
		# the property in the first place we will get an error. this happens
		# periodically when paessler adds new properties to the output.
		#
		# so how do we gracefully handle new properties?
		foreach ($ChildNode in $data.status.ChildNodes) {
			# for now, we outright ignore them.
			if (($PrtgServerObject | Get-Member | Select-Object -ExpandProperty Name) -contains $ChildNode.Name) {
				
				if ($ChildNode.Name -ne "IsAdminUser") {
					$PrtgServerObject.$($ChildNode.Name) = $ChildNode.InnerText
				} else {
					# TODO
					# there's at least four properties that need to be treated this way
					# this is because this property returns a text "true" or "false", which powershell always evaluates as "true"
					$PrtgServerObject.$($ChildNode.Name) = [System.Convert]::ToBoolean($ChildNode.InnerText)
				}
				
			}
		}
		
        $global:PrtgServerObject = $PrtgServerObject

		#HelperFormatTest ###### need to add this back in
		# this tests for a decimal-placement bug that existed in the output from some old versions of prtg
		
		if (!$Quiet) {
			return $PrtgServerObject | Select-Object @{n='Connection';e={$_.ApiUrl}},UserName,Version
		}
    }
}
