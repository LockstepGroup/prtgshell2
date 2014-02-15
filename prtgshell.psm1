###############################################################################
#
# PrtgShell
# Josh Sanders, Brian Addicks
# 2014 Lockstep Technology Group
#
# version 2
#
###############################################################################


Add-Type -TypeDefinition @"
using System;
using System.Net;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;
using System.Collections;
using System.Collections.Generic;
using System.Linq;

namespace PrtgShell {
	public class exexml {
	
		private int priority = 3;
		private int exeresult = 0;
		
		public string Name { get; set; }
		public string Tags { get; set; }
		public int Priority {
			get {
				return this.priority;
			}
			set {
				if (value > 0 && value <= 5) {
					this.priority = value;
				} else  {
					throw new ArgumentOutOfRangeException("Invalid value. Value must be between 0 and 5");
				}
			}
		}
		public string Script { get; set; }
		public string ExeParams { get; set; }
		public bool Environment { get; set; }
		public bool SecurityContext { get; set; }
		public string Mutex { get; set; }
		public int ExeResult {
			get {
				return this.exeresult;
			}
			set {
				if (value > 0 && value <= 2) {
					this.exeresult = value;
				} else  {
					throw new ArgumentOutOfRangeException("Invalid value. Value must be between 0 and 2");
				}
			}
		}
		public int ParentId { get; set; }
		
	}
	
	public class PrtgDevice {
		public int objid { get; set; }
		public string probe { get; set; }
		public string group { get; set; }
		public string device { get; set; }
		public string host { get; set; }
		public int downsens { get; set; }
		public int partialdownsens { get; set; }
		public int downacksens { get; set; }
		public int upsens { get; set; }
		public int warnsens { get; set; }
		public int pausedsens { get; set; }
		public int unusualsens { get; set; }
		public int undefinedsens { get; set; }
	}
	
	public class PrtgGroup {
		public int objid { get; set; }
		public string probe { get; set; }
		public string group { get; set; }
		public string name { get; set; }
		public int downsens { get; set; }
		public int partialdownsens { get; set; }
		public int downacksens { get; set; }
		public int upsens { get; set; }
		public int warnsens { get; set; }
		public int pausedsens { get; set; }
		public int unusualsens { get; set; }
		public int undefinedsens { get; set; }
	}
	
	public class PrtgSensor {
		private string SensorName = null;
		private int priority = 3;
	
		public int objid { get; set; }
		public int parentid { get; set; }
		public string probe { get; set; }
		public string group { get; set; }
		public string device { get; set; }
		public string sensor {
			get {
				return this.SensorName;
			}
			set {
				this.SensorName = value;
			}
		}
		public string name {
			get {
				return this.SensorName;
			}
			set {
				this.SensorName = value;
			}
		}
		public string tags { get; set; }
		public string status { get; set; }
		public string message { get; set; }
		public string lastvalue { get; set; }
		public string lastvalue_raw { get; set; }
		public int Priority {
			get {
				return this.priority;
			}
			set {
				if (value > 0 && value <= 5) {
					this.priority = value;
				} else  {
					throw new ArgumentOutOfRangeException("Invalid value. Value must be between 0 and 5");
				}
			}
		}
		public bool favorite { get; set; }
	}
	
	public class PrtgChannel {
		public int objid { get; set; }
		public string name { get; set; }
		public string lastvalue { get; set; }
		public decimal lastvalue_raw { get; set; }
	}
	
	public class PrtgServer {
		// can we rewrite the helper functions as methods in this class?
		
		private DateTime clock;
		private Stack<string> urlhistory = new Stack<string>();
		private string prtgshellversion = "2.0";
		
		public string Server { get; set; }
		public int Port { get; set; }
		public string UserName { get; set; }
		public string PassHash { get; set; }
		public string Protocol { get; set; }
		
		public string ApiUrl {
			get {
				if (!string.IsNullOrEmpty(this.Protocol) && !string.IsNullOrEmpty(this.Server) && this.Port > 0) {
					return this.Protocol + "://" + this.Server + ":" + this.Port + "/";
				} else {
					return null;
				}
			}
		}
		
		public string AuthString {
			get {
				if (!string.IsNullOrEmpty(this.UserName) && !string.IsNullOrEmpty(this.PassHash)) {
					return "username=" + this.UserName + "&passhash=" + this.PassHash;
				} else {
					return null;
				}
			}
		}
	
		public string PrtgShellVersion {
			get {
				return prtgshellversion;
			}
		}
	
		public int NewMessages { get; set; }
		public int NewAlarms { get; set; }
		public int Alarms { get; set; }
		public int AckAlarms { get; set; }
		public int NewToDos { get; set; }
		public string Clock {
			get {
				return this.clock.ToString();
			}
			set {
				this.clock = DateTime.Parse(value);
			}
		}
		public DateTime ClockasDateTime {
			get {
				return this.clock;
			}
			set {
				this.clock = value;
			}
		}
		public string ActivationStatusMessage { get; set; }
		public int BackgroundTasks { get; set; } // misc background tasks (not autodiscovery, maybe?)
		public int CorrelationTasks { get; set; } // similar sensors analysis
		public int AutoDiscoTasks { get; set; } // running autodiscoveries
		public string Version { get; set; }
		public bool PRTGUpdateAvailable { get; set; }
		public bool IsAdminUser { get; set; }
		public bool IsCluster { get; set; }
		public bool ReadOnlyUser { get; set; }
		public bool ReadOnlyAllowAcknowledge { get; set; }
		
		public bool RawFormattingError { get; set; }
		
		public string[] UrlHistory {
			get {
				return this.urlhistory.ToArray();
			}
		}
		
		public void FlushHistory () {
			this.urlhistory.Clear();
		}
		
		
		public string UrlBuilder (string Action) {
		
			if (Action.StartsWith("/")) Action = Action.Substring(1);
			
			string[] Pieces = new string[4];
			Pieces[0] = this.ApiUrl;
			Pieces[1] = Action;
			Pieces[2] = "?";
			Pieces[3] = this.AuthString;
			
			string CompletedString = string.Join ("",Pieces);
			this.urlhistory.Push(CompletedString);
			return CompletedString;
		}
		
		public string UrlBuilder (string Action, string[] QueryParameters) {
		
			if (Action.StartsWith("/")) Action = Action.Substring(1);
			
			string[] Pieces = new string[4];
			Pieces[0] = this.ApiUrl;
			Pieces[1] = Action;
			Pieces[2] = "?";
			Pieces[3] = this.AuthString;
			
			var FullString = new string[Pieces.Length + QueryParameters.Length];
			Pieces.CopyTo(FullString, 0);
			QueryParameters.CopyTo(FullString, Pieces.Length);
			
			string CompletedString = string.Join ("",FullString);
			this.urlhistory.Push(CompletedString);
			return CompletedString;
		}
		
		public string UrlBuilder (string Action, Hashtable QueryParameters) {
		
			if (Action.StartsWith("/")) Action = Action.Substring(1);
			
			string[] Pieces = new string[5];
			Pieces[0] = this.ApiUrl;
			Pieces[1] = Action;
			Pieces[2] = "?";
			Pieces[3] = this.AuthString;
			
			foreach(DictionaryEntry KeyPair in QueryParameters) {
				if (KeyPair.Value.GetType() == typeof(string) || KeyPair.Value.GetType() == typeof(int)) {
					Pieces[4] += ("&" + KeyPair.Key + "=" + KeyPair.Value);
				} else {
					string[] ConvertedArray = ((IEnumerable)KeyPair.Value).Cast<object>().Select(x => x.ToString()).ToArray();
					foreach (string SubValue in ConvertedArray) {
						Pieces[4] += ("&" + KeyPair.Key + "=" + SubValue);
					}
				}
			}
			
			string CompletedString = string.Join ("",Pieces);
			this.urlhistory.Push(CompletedString);
			return CompletedString;
		}
		
		private static bool OnValidateCertificate(object sender, X509Certificate certificate, X509Chain chain, SslPolicyErrors sslPolicyErrors) {
			return true;
		}
    
		public void OverrideValidation() {
			ServicePointManager.ServerCertificateValidationCallback = OnValidateCertificate;
			ServicePointManager.Expect100Continue = true;
			ServicePointManager.SecurityProtocol = SecurityProtocolType.Ssl3;
		}
	}
}
"@

###############################################################################



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
		if ($HttpOnly) {
			$Protocol = "http"
			if (!$Port) { $Port = 80 }
		} else {
			$Protocol = "https"
			if (!$Port) { $Port = 443 }
			
			$PrtgServerObject = New-Object PrtgShell.PrtgServer
			
			$PrtgServerObject.Protocol = $Protocol
			$PrtgServerObject.Port = $Port
			$PrtgServerObject.Server = $Server
			$PrtgServerObject.UserName = $UserName
			$PrtgServerObject.PassHash = $PassHash
			
			$PrtgServerObject.OverrideValidation()
		}
    }

    PROCESS {
		$url = $PrtgServerObject.UrlBuilder("api/getstatus.xml")

		try {
			$QueryObject = HelperHTTPQuery $url -AsXML
		} catch {
			throw "Error performing HTTP query"
		}
		
		$Data = $QueryObject.Data

		$data.status.ChildNodes | % {
			$PrtgServerObject.$($_.Name) = $_.InnerText
		}
		
        $global:PrtgServerObject = $PrtgServerObject

		#HelperFormatTest ###### need to add this back in
		
		if (!$Quiet) {
			return $PrtgServerObject | Select-Object @{n='Connection';e={$_.ApiUrl}},UserName,Version
		}
    }
}


###############################################################################


function Get-PrtgTableData {
	<#
		.SYNOPSIS
			Returns a PowerShell object containing data from the specified object in PRTG.
			
		.DESCRIPTION
			The Get-PrtgTableData cmdlet can return data of various different content types using the specified parent object, as well as specify the return columns or filtering options. The input formats generally coincide with the Live Data demo from the PRTG API documentation, but there are some content types that the cmdlet does not yet support, such as "sensortree".
		
		.PARAMETER Content
			The type of data to return about the specified object. Valid values are "devices", "groups", "sensors", "todos", "messages", "values", "channels", and "history". Note that all content types are not valid for all object types; for example, a device object can contain no groups or channels.
			
		.PARAMETER ObjectId
			An object ID from PRTG. Objects include probes, groups, devices, and sensors, as well as reports, maps, and todos.
		
		.PARAMETER Columns
			A string array of named column values to return. In general the default return values for a given content type will return all of the available columns; this parameter can be used to change the order of columns or specify which columns to include or ignore.
			
		.PARAMETER FilterTags
			A string array of sensor tags. This parameter only has any effect if the content type is "sensor". Output will only include sensors with the specified tags. Note that specifying multiple tags performs a logical OR of tags.
			
		.PARAMETER Count
			Number of records to return. PRTG's internal default for this is 500. Valid values are 1-50000.
			
		.PARAMETER Raw
			If this switch is set, the cmdlet will return the raw XML data rather than a PowerShell object.
		
		.EXAMPLE
			Get-PrtgTableData groups 1
			
			Returns the groups under the object ID 1, which is typically the Core Server's Local Probe.
		
		.EXAMPLE
			Get-PrtgTableData sensors -FilterTags corestatesensor,probesensor
			
			Returns a filtered list of sensors tagged with "corestatesensor" or "probesensor".
			
		.EXAMPLE
			Get-PrtgTableData messages 1002
			
			Returns the messages log for device 1002.
	#>

	Param (		
		[Parameter(Mandatory=$True,Position=0)]
		[ValidateSet("probes","groups","devices","sensors","todos","messages","values","channels","history")]
		[string]$Content,

		[Parameter(Mandatory=$false,Position=1)]
		[int]$ObjectId = 0,

		[Parameter(Mandatory=$False)]
		[string[]]$Columns,

		[Parameter(Mandatory=$False)]
		[string[]]$FilterTags,

		[Parameter(Mandatory=$False)]
		[int]$Count,

		[Parameter(Mandatory=$False)]
		[switch]$Raw
	)

	<# things to add
	
		filter_drel (content = messages only) today, yesterday, 7days, 30days, 12months, 6months - filters messages by timespan
		filter_status (content = sensors only) Unknown=1, Collecting=2, Up=3, Warning=4, Down=5, NoProbe=6, PausedbyUser=7, PausedbyDependency=8, PausedbySchedule=9, Unusual=10, PausedbyLicense=11, PausedUntil=12, DownAcknowledged=13, DownPartial=14 - filters messages by status
		sortby = sorts on named column, ascending (or decending with a leading "-")
		filter_xyz - fulltext filtering. this is a feature in its own right
	
	#>

	BEGIN {
		$PRTG = $Global:PrtgServerObject
		if ($PRTG.Protocol -eq "https") { $PRTG.OverrideValidation() }

		
		$CountProperty = @{}
		$FilterProperty = @{}
		
		if ($Count) {
			$CountProperty =  @{ "count" = $Count }
		}

		
		if ($FilterTags -and (!($Content -eq "sensors"))) {
			throw "Get-PrtgTableData: Parameter FilterTags requires content type sensors"
		} elseif ($Content -eq "sensors" -and $FilterTags) {
			$FilterProperty =  @{ "filter_tags" = $FilterTags }
		}

		if (!$Columns) {
			# this function currently doesn't work with "sensortree" or "maps"

			$TableLookups = @{
				"probes" = @("objid","type","name","tags","active","probe","notifiesx","intervalx","access","dependency","probegroupdevice","status","message","priority","upsens","downsens","downacksens","partialdownsens","warnsens","pausedsens","unusualsens","undefinedsens","totalsens","favorite","schedule","comments","condition","basetype","baselink","parentid","fold","groupnum","devicenum")
				
				"groups" = @("objid","type","name","tags","active","group","probe","notifiesx","intervalx","access","dependency","probegroupdevice","status","message","priority","upsens","downsens","downacksens","partialdownsens","warnsens","pausedsens","unusualsens","undefinedsens","totalsens","favorite","schedule","comments","condition","basetype","baselink","parentid","location","fold","groupnum","devicenum")
				
				"devices" = @("objid","type","name","tags","active","device","group","probe","grpdev","notifiesx","intervalx","access","dependency","probegroupdevice","status","message","priority","upsens","downsens","downacksens","partialdownsens","warnsens","pausedsens","unusualsens","undefinedsens","totalsens","favorite","schedule","deviceicon","comments","host","basetype","baselink","icon","parentid","location")
				
				"sensors" = @("objid","type","name","tags","active","downtime","downtimetime","downtimesince","uptime","uptimetime","uptimesince","knowntime","cumsince","sensor","interval","lastcheck","lastup","lastdown","device","group","probe","grpdev","notifiesx","intervalx","access","dependency","probegroupdevice","status","message","priority","lastvalue","lastvalue_raw","upsens","downsens","downacksens","partialdownsens","warnsens","pausedsens","unusualsens","undefinedsens","totalsens","favorite","schedule","minigraph","comments","basetype","baselink","parentid")
				
				"channels" = @("name","lastvalue","lastvalue_raw")
				
				"todos" = @("objid","datetime","name","status","priority","message","active")
				
				"messages" = @("objid","datetime","parent","type","name","status","message")
				
				"values" = @("datetime","value_","coverage")
				
				"history" = @("datetime","dateonly","timeonly","user","message")
				
				"storedreports" = @("objid","name","datetime","size")
				
				"reports" = @("objid","name","template","period","schedule","email","lastrun","nextrun")
			}
	
			$SelectedColumns = $TableLookups.$Content
		} else {
			$SelectedColumns = $Columns
		}

		$SelectedColumnsString = $SelectedColumns -join ","

		$HTMLColumns = @("downsens","partialdownsens","downacksens","upsens","warnsens","pausedsens","unusualsens","undefinedsens","message","favorite")
	}

	PROCESS {

		$Parameters = @{
			"content" = $Content
			"columns" = $SelectedColumnsString
			"id" = $ObjectId
		} ################################################# needs to handle filters!
		
		$Parameters += $CountProperty
		$Parameters += $FilterProperty
		
		$url = $PrtgServerObject.UrlBuilder("api/table.xml",$Parameters)

		##### data returned; do!

		if ($Raw) {
			$QueryObject = HelperHTTPQuery $url
			return $QueryObject.Data
		}

		$QueryObject = HelperHTTPQuery $url -AsXML
		$Data = $QueryObject.Data

		$ReturnData = @()

		foreach ($item in $Data.$Content.item) {
			$ThisRow = "" | Select-Object $SelectedColumns
			foreach ($Prop in $SelectedColumns) {
				if ($Content -eq "channels" -and $Prop -eq "lastvalue_raw") {
					# fix a bizarre formatting bug
					#$ThisRow.$Prop = HelperFormatHandler $item.$Prop
					$ThisRow.$Prop = $item.$Prop
				} elseif ($HTMLColumns -contains $Prop) {
					# strip HTML, leave bare text
					$ThisRow.$Prop =  $item.$Prop -replace "<[^>]*?>|<[^>]*>", ""
				} else {
					$ThisRow.$Prop = $item.$Prop
				}
			}
			$ReturnData += $ThisRow
		}

		if ($ReturnData.name -eq "Item" -or (!($ReturnData.ToString()))) {
			$DeterminedObjectType = Get-PrtgObjectType $ObjectId

			$ValidQueriesTable = @{
				group=@("devices","groups","sensors","todos","messages","values","history")
				probenode=@("devices","groups","sensors","todos","messages","values","history")
				device=@("sensors","todos","messages","values","history")
				sensor=@("messages","values","channels","history")
				report=@("Currently unsupported")
				map=@("Currently unsupported")
				storedreport=@("Currently unsupported")
			}

			Write-Host "No $Content; Object $ObjectId is type $DeterminedObjectType"
			Write-Host (" Valid query types: " + ($ValidQueriesTable.$DeterminedObjectType -join ", "))
		} else {
			return $ReturnData
		}
	}
}



function HelperHTTPQuery {
	Param (
		[Parameter(Mandatory=$True,Position=0)]
		[string]$URL,

		[Parameter(Mandatory=$False)]
		[alias('xml')]
		[switch]$AsXML
	)

	try {
		$Response = $null
		$Request = [System.Net.HttpWebRequest]::Create($URL)
		$Response = $Request.GetResponse()
		if ($Response) {
			$StatusCode = $Response.StatusCode.value__
			$DetailedError = $Response.GetResponseHeader("X-Detailed-Error")
		}
	}
	catch {
		$ErrorMessage = $Error[0].Exception.ErrorRecord.Exception.Message
		$Matched = ($ErrorMessage -match '[0-9]{3}')
		if ($Matched) {
			throw ('HTTP status code was {0} ({1})' -f $HttpStatusCode, $matches[0])
		}
		else {
			throw $ErrorMessage
		}

		#$Response = $Error[0].Exception.InnerException.Response
		#$Response.GetResponseHeader("X-Detailed-Error")
	}

	if ($Response.StatusCode -eq "OK") {
		$Stream    = $Response.GetResponseStream()
		$Reader    = New-Object IO.StreamReader($Stream)
		$FullPage  = $Reader.ReadToEnd()

		if ($AsXML) {
			$Data = [xml]$FullPage
		} else {
			$Data = $FullPage
		}

		$Global:LastResponse = $Data

		$Reader.Close()
		$Stream.Close()
		$Response.Close()
	} else {
		Throw "Error Accessing Page $FullPage"
	}

	$ReturnObject = "" | Select-Object StatusCode,DetailedError,Data
	$ReturnObject.StatusCode = $StatusCode
	$ReturnObject.DetailedError = $DetailedError
	$ReturnObject.Data = $Data

	return $ReturnObject
}

function HelperHTTPPostCommand() {
	param(
		[string] $url = $null,
		[string] $data = $null,
		[System.Net.NetworkCredential]$credentials = $null,
		[string] $contentType = "application/x-www-form-urlencoded",
		[string] $codePageName = "UTF-8",
		[string] $userAgent = $null
	);

	if ( $url -and $data ) {
		[System.Net.WebRequest]$webRequest = [System.Net.WebRequest]::Create($url);
		$webRequest.ServicePoint.Expect100Continue = $false;
		if ( $credentials ) {
			$webRequest.Credentials = $credentials;
			$webRequest.PreAuthenticate = $true;
		}
		$webRequest.ContentType = $contentType;
		$webRequest.Method = "POST";
		if ( $userAgent ) {
			$webRequest.UserAgent = $userAgent;
		}

		$enc = [System.Text.Encoding]::GetEncoding($codePageName);
		[byte[]]$bytes = $enc.GetBytes($data);
		$webRequest.ContentLength = $bytes.Length;
		[System.IO.Stream]$reqStream = $webRequest.GetRequestStream();
		$reqStream.Write($bytes, 0, $bytes.Length);
		$reqStream.Flush();

		$resp = $webRequest.GetResponse();
		$rs = $resp.GetResponseStream();
		[System.IO.StreamReader]$sr = New-Object System.IO.StreamReader -argumentList $rs;
		$sr.ReadToEnd();
	}
}

function HelperFormatTest {
	$URLKeeper = $global:lasturl

	$CoreHealthChannels = Get-PrtgSensorChannels 1002
	$HealthPercentage = $CoreHealthChannels | ? {$_.name -eq "Health" }
	$ValuePretty = [int]$HealthPercentage.lastvalue.Replace("%","")
	$ValueRaw = [int]$HealthPercentage.lastvalue_raw

	if ($ValueRaw -eq $ValuePretty) {
		$RawFormatError = $false
	} else {
		$RawFormatError = $true
	}

	$global:lasturl = $URLKeeper

	$StoredConfiguration = $Global:PrtgServerObject | Select-Object *,RawFormatError
	$StoredConfiguration.RawFormatError = $RawFormatError

	$global:PrtgServerObject = $StoredConfiguration
}

function HelperFormatHandler {
    Param (
        [Parameter(Mandatory=$False,Position=0)]
        $InputData
	)

	if (!$InputData) { return }

	if ($Global:PrtgServerObject.RawFormatError) {
		# format includes the quirk
		return [double]$InputData.Replace("0.",".")
	} else {
		# format doesn't include the quirk, pass it back
		return [double]$InputData
	}
}

###############################################################################
## PowerShell Module Functions
###############################################################################

Export-ModuleMember *-*