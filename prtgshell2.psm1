###############################################################################
#
# PrtgShell
# Josh Sanders, Brian Addicks
# 2014 Lockstep Technology Group
#
# version 2
#
###############################################################################


Add-Type -ReferencedAssemblies @(([System.Reflection.Assembly]::LoadWithPartialName("System.Web")).Location) -TypeDefinition @"

using System;
using System.Net;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;
using System.Collections;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Linq;
using System.Web;

namespace PrtgShell {
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
    
    public class PrtgSensorCreator {
		// this is the class that will be created and populated to validate sensor creation
		// is there really a point to having these things obfuscate the names
		
		// http://stackoverflow.com/questions/2605268/reverse-function-of-httputility-parsequerystring
		// this should have a method that uses the data you've given it to create the query string
		// the trick to this is that the main class (this class) will never know what all it should include
		// ... but the inherited classes will
		// so is it possible to define a method here that somehow uses information defined in the inherited classes
		// that then produces the correct, complete query string?
		
		
		// how this thing should work:
		// the creator contains all the base objects that all sensors get
			// "name_" = $PrtgObject.Name
			// "tags_" = $PrtgObject.Tags
			// "priority_" = $PrtgObject.Priority
			// "intervalgroup" = 1
			// "interval_" = "60|60 seconds"
			// "inherittriggers" = 1
			// "id" = $PrtgObject.ParentId
			// "sensortype" = "exexml"
		// it will also include some methods that they will all need
			// such as "CreateQueryString" which is what the http post command needs
			
		// there will then be various derived classes that will inherit this down
		
		
		private int sensor_priority = 3;
		private bool inherit_interval = true;
		private int polling_interval = 60;
		//public Hashtable QueryString = new Hashtable();
		public string name_ { get; set; }
		public string[] tags_ { get; set; }
		public string sensortype { get; set; }
		public int id { get; set; }
		
		public int priority_ {
			get {
				return this.sensor_priority;
			}
			set {
				if (value > 0 && value <= 5) {
					this.sensor_priority = value;
				} else  {
					throw new ArgumentOutOfRangeException("Invalid value. Value must be between 0 and 5");
				}
			}
		}
		
		public bool inherittriggers { get; set; }
		
		public bool intervalgroup {
			get {
				return this.inherit_interval;
			}
			set {
				this.inherit_interval = value;
			}
		}
		
		public string interval_ {
			get {
				return this.polling_interval.ToString() + "|" + ToTimeString(this.polling_interval);
			}
		}
		
		public int interval {
			get {
				return this.polling_interval;
			}
			set {
				this.polling_interval = value;
			}
		}

        private string ToTimeString(int InputSeconds) {
            if (((InputSeconds % 86400) == 0) && (InputSeconds / 86400 != 1)) {
                return (InputSeconds / 86400).ToString() + " days";
            } else if (((InputSeconds % 3600) == 0) && (InputSeconds / 3600 != 1)) {
                return (InputSeconds / 3600).ToString() + " hours";
            } else if (((InputSeconds % 60) == 0) && (InputSeconds / 60 != 1)) {
                return (InputSeconds / 60).ToString() + " minutes";
            } else {
                return InputSeconds.ToString() + " seconds";
            }
        }
		
    }
	
	
	public class NewExeXml : PrtgSensorCreator {
	
		public string exefile { get; set; }
		
		public string exefile_ {
			get {
				if (!String.IsNullOrEmpty(this.exefile)) {
					return this.exefile + "|" + this.exefile + "||";
				} else {
					return String.Empty;
				}
			}
		}
		public string exefilelabel { get; set; }
		public string exeparams_ { get; set; }
		public bool environment_ { get; set; }
		public bool usewindowsauthentication_ { get; set; }
		public string mutexname_ { get; set; }
		public int timeout_ { get; set; }
		public int writeresult_ { get; set; }
		
		public NewExeXml () {
			this.sensortype = "exexml";
			this.environment_ = false;
			this.usewindowsauthentication_ = false;
			this.inherittriggers = true;
			this.timeout_ = 60;
			this.writeresult_ = 0;
			this.name_ = "XML Custom EXE/Script Sensor";
			this.tags_ = new string[] {"xmlexesensor"};
			this.intervalgroup = true;	
			this.interval = 60;
		}
		
		
		public string QueryString {
			get {
				NameValueCollection queryString = System.Web.HttpUtility.ParseQueryString(string.Empty);

				queryString["name_"] = this.name_;
				queryString["tags_"] = String.Join(" ",this.tags_);
				queryString["priority_"] = this.priority_.ToString();
				queryString["intervalgroup"] = Convert.ToString(Convert.ToInt32(this.intervalgroup));
				queryString["interval_"] = this.interval_;
				queryString["inherittriggers"] = Convert.ToString(Convert.ToInt32(this.inherittriggers));
				queryString["id"] = this.id.ToString();
				queryString["sensortype"] = this.sensortype;
				
				queryString["exefile_"] = this.exefile_;
				queryString["exefilelabel"] = this.exefilelabel;
				queryString["exeparams_"] = this.exeparams_;
				queryString["environment_"] = Convert.ToString(Convert.ToInt32(this.environment_));
				queryString["usewindowsauthentication_"] = Convert.ToString(Convert.ToInt32(this.usewindowsauthentication_));
				queryString["mutexname_"] = this.mutexname_;
				queryString["timeout_"] = this.timeout_.ToString();
				queryString["writeresult_"] = this.writeresult_.ToString();
				
				return queryString.ToString();
			}
		}
	}
	
	
	public class NewAggregation : PrtgSensorCreator {
	
		// "aggregationchannel_" = $AggregationChannelDefinition
		// "warnonerror_" = 0 # 0 = "Factory sensor shows error state when one or more source sensors are in error state"; 1 = "Factory sensor shows warning state when one or more source sensors are in error state"; 2 = "Use custom formula", uses aggregation status field
		// "aggregationstatus_" = 0 # https://prtg.forsyth.k12.ga.us/help/sensor_factory_sensor.htm#sensor_status
		// "missingdata_" = 0 # 0 = " Do not calculate factory channels that use the sensor"; 1 = "Calculate the factory channels and use zero as source value"

		public string aggregationchannel_ { get; set; }
		public int warnonerror_ { get; set; }
		public bool aggregationstatus_ { get; set; }
		public bool missingdata_ { get; set; }
		
		public NewAggregation () {
			this.sensortype = "aggregation";
			this.inherittriggers = true;		
			this.name_ = "Sensor Factory";
			this.tags_ = new string[] {"factorysensor"};
			this.intervalgroup = true;	
			this.interval = 60;
			
			this.aggregationchannel_ = @"#1:Sample
Channel(1000,0)
#2:Response Time[ms]
Channel(1001,1)";
			this.warnonerror_ = 0;
			this.aggregationstatus_ = false;
			this.missingdata_ = false;
		}
		
		
		public string QueryString {
			get {
				NameValueCollection queryString = System.Web.HttpUtility.ParseQueryString(string.Empty);

				queryString["name_"] = this.name_;
				queryString["tags_"] = String.Join(" ",this.tags_);
				queryString["priority_"] = this.priority_.ToString();
				queryString["intervalgroup"] = Convert.ToString(Convert.ToInt32(this.intervalgroup));
				queryString["interval_"] = this.interval_;
				queryString["inherittriggers"] = Convert.ToString(Convert.ToInt32(this.inherittriggers));
				queryString["id"] = this.id.ToString();
				queryString["sensortype"] = this.sensortype;
				
				queryString["aggregationchannel_"] = this.aggregationchannel_;
				queryString["warnonerror_"] = this.warnonerror_.ToString();
				queryString["aggregationstatus_"] = Convert.ToString(Convert.ToInt32(this.aggregationstatus_));
				queryString["missingdata_"] = Convert.ToString(Convert.ToInt32(this.missingdata_));
				
				return queryString.ToString();
			}
		}
	}

    public class NewChannel {
	
		// several of these need some validation
		
        public string channelname { get; set; }
        public decimal channelvalue { get; set; }
		public bool isfloat { get; set; }
		
		private List<string> StandardUnits = new List<string>(new string[] {
			"BytesBandwidth",
            "BytesMemory",
            "BytesDisk",
            "Temperature",
            "Percent",
            "TimeResponse",
            "TimeSeconds",
            "Count",
            "CPU",
            "BytesFile",
            "SpeedDisk",
            "SpeedNet",
            "TimeHours"
        });
		
		private string ChannelUnitName = null;
		
		private string ChannelUnit = null;
		public string channelunit {
			get {
				return this.ChannelUnit;
			}
			set {
				if (StandardUnits.Contains(value, StringComparer.OrdinalIgnoreCase)) {
					this.ChannelUnitName = value;
					this.ChannelUnit = null;
				} else {
					this.ChannelUnitName = "Custom";
					this.ChannelUnit = value;
				}
			}
		}
		
		// this is just here for testing the logic
		// if this.ChannelUnit = null, don't return the customunit element
		public string ShowChannel () {
			return "UNIT: " + this.ChannelUnitName + "; CUSTOMUNIT: " + this.ChannelUnit;
		}
		
		
		public bool showchart { get; set; }
		
		public string errormessage { get; set; }
		
		public string maxwarnthreshold { get; set; } // these thresholds probably need to be decimals, floats, or ints (rather than strings)
		public string minwarnthreshold { get; set; }
		public string maxerrorthreshold { get; set; }
		public string minerrorthreshold { get; set; }
		
		// private bool limitmode = false; // if any of the thresholds above are set, this needs to be flipped to true
		
		public string channelmode { get; set; } // absolute or difference
		
		public string speedsize { get; set; } // [ValidateSet("One","Kilo","Mega","Giga","Tera","Byte","KiloByte","MegaByte","GigaByte","TeraByte","Bit","KiloBit","MegaBit","GigaBit","TeraBit")]
		public string decimalmode { get; set; } // auto, all (there's a third value here, "custom", that isn't currently configurable through the exexml api)
		
		public bool iswarning { get; set; }
		public string valuelookup { get; set; }
		
		// constructor
		public NewChannel () {
			// set defaults here
			// you can also overload this construct to pass params in using new-object
		}
    }

	
	public class PrtgBaseObject {
		public int objid { get; set; }
		public string name { get; set; }
	}
	
	public class PrtgObject : PrtgBaseObject {
		// all of the properties and methods here are used in
		// probes, groups, devices, and sensors
		
		// these datatypes need to be refined
		
		private int priority = 3;
		
		public string type { get; set; }
		public string tags { get; set; }
		public string active { get; set; }
		public string probe { get; set; }
		public string notifiesx { get; set; }
		public string intervalx { get; set; }
		public string access { get; set; }
		public string dependency { get; set; }
		public string probegroupdevice { get; set; }
		public string status { get; set; }
		public string message { get; set; }
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
		public string upsens { get; set; }
		public string downsens { get; set; }
		public string downacksens { get; set; }
		public string partialdownsens { get; set; }
		public string warnsens { get; set; }
		public string pausedsens { get; set; }
		public string unusualsens { get; set; }
		public string undefinedsens { get; set; }
		public string totalsens { get; set; }
		public string favorite { get; set; }
		public string schedule { get; set; }
		public string comments { get; set; }
		public string basetype { get; set; }
		public string baselink { get; set; }
		public string parentid { get; set; }
	}
	
	public class PrtgProbe : PrtgObject {
		// probes inherit everything from objects as well as the following
		
		public string condition { get; set; }
		public string fold { get; set; }
		public string groupnum { get; set; }
		public string devicenum { get; set; }
	}
	
	public class PrtgGroup : PrtgProbe {
		// groups inherit everything from probes as well as the following
		
		public string group { get; set; }
		public string location { get; set; }
	}
	
	public class PrtgDevice : PrtgObject {
		// probes inherit everything from objects as well as the following
		
		public string device { get; set; }
		public string group { get; set; }
		public string grpdev { get; set; }
		public string deviceicon { get; set; }
		public string host { get; set; }
		public string icon { get; set; }
		public string location { get; set; }
	}
	
	public class PrtgSensor : PrtgObject {
		// probes inherit everything from objects as well as the following
		
		public string device { get; set; }
		public string group { get; set; }
		public string grpdev { get; set; }
		
		public string downtime { get; set; }
		public string downtimetime { get; set; }
		public string downtimesince { get; set; }
		public string uptime { get; set; }
		public string uptimetime { get; set; }
		public string uptimesince { get; set; }
		public string knowntime { get; set; }
		public string cumsince { get; set; }
		public string sensor { get; set; }
		public string interval { get; set; }
		public string lastcheck { get; set; }
		public string lastup { get; set; }
		public string lastdown { get; set; }
		
		public string lastvalue { get; set; }
		public string lastvalue_raw { get; set; }
		public string minigraph { get; set; }
	}
	
	public class PrtgChannel : PrtgBaseObject {
		public string lastvalue { get; set; }
		public decimal lastvalue_raw { get; set; }
	}
	
	public class PrtgTodo : PrtgBaseObject {
		public string datetime { get; set; }
		public decimal status { get; set; }
		public string priority { get; set; }
		public decimal message { get; set; }
		public decimal active { get; set; }
	}
	
	public class PrtgMessage : PrtgBaseObject {
		public string datetime { get; set; }
		public decimal parent { get; set; }
		public string type { get; set; }
		public decimal status { get; set; }
		public decimal message { get; set; }
	}
	
	public class PrtgValue {
		public string datetime { get; set; }
		public decimal value_ { get; set; }
		public string coverage { get; set; }
	}

	public class PrtgHistory {
		public string datetime { get; set; }
		public decimal dateonly { get; set; }
		public string timeonly { get; set; }
		public string user { get; set; }
		public string message { get; set; }
	}
	
	public class PrtgStoredReport : PrtgBaseObject {
		public string datetime { get; set; }
		public decimal size { get; set; }
	}
	
	public class PrtgReport : PrtgBaseObject {
		public string template { get; set; }
		public decimal period { get; set; }
		public string schedule { get; set; }
		public decimal email { get; set; }
		public decimal lastrun { get; set; }
		public decimal nextrun { get; set; }
	}

// ---------------------- Used for Setting EXEXML results ---------------------- //

    public class XmlResult {
        public string channel { get; set; }
        public decimal resultvalue { get; set; }

        public string unit { get; set; } 
        // ValidateSet: BytesBandwidth, BytesMemory, BytesDisk, Temperature, Percent, TimeResponse, TimeSeconds, Count, CPU (*), BytesFile, SpeedDisk, SpeedNet, TimeHours
        // Custom set for anything else

        public string customunit { get; set; }

        public string speedsize { get; set; }
        // ValidateSet: One, Kilo, Mega, Giga, Tera, Byte, KiloByte, MegaByte, GigaByte, TeraByte, Bit, KiloBit, MegaBit, GigaBit, TeraBit

        public string volumesize { get; set; }
        // ValidateSet: One, Kilo, Mega, Giga, Tera, Byte, KiloByte, MegaByte, GigaByte, TeraByte, Bit, KiloBit, MegaBit, GigaBit, TeraBit

        public string speedtime { get; set; }
        // ValidateSet: Second, Minute, Hour, Day

        public bool mode { get; set; }
        // 0 = Absolute, 1 = Difference

        public bool isfloat { get; set; }

        public string decimalmode { get; set; }
        //ValidateSet: Auto, All

        public bool warning { get; set; }
        public bool showchart { get; set; }
        public bool showtable { get; set; }
        public int limitmaxerror { get; set; }
        public int limitmaxwarning { get; set; }
        public int limitminwarning { get; set; }
        public int limitminerror { get; set; }
        public string limiterrormsg { get; set; }
        public string limitwarningmsg { get; set; }
        public bool limitmode { get; set; }
        public string valuelookup { get; set; }

        public XmlResult () {
			this.isfloat = false;
            this.warning = false;
            this.showchart = true;
            this.showtable = true;
            this.limitmode = false;
        }
    }

    public class ExeXML {
        public string text { get; set; }
        // max of 2000 characters

        public bool error { get; set; }

    }

// ----------------------------------------------------------------------------- //
}
"@

###############################################################################

<#
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
#>



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
			$PrtgServerObject.Port     = $Port
			$PrtgServerObject.Server   = $Server
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
			if ($_.Name -ne "IsAdminUser") {
				$PrtgServerObject.$($_.Name) = $_.InnerText
			} else {
				# TODO
				# there's at least four properties that need to be treated this way
				# this is because this property returns a text "true" or "false", which powershell always evaluates as "true"
				$PrtgServerObject.$($_.Name) = [System.Convert]::ToBoolean($_.InnerText)
			}
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
				
				"channels" = @("objid","name","lastvalue","lastvalue_raw")
				
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
		
		<#
		
		HOW THIS WILL LIKELY NEED TO WORK
		---
		
		build a switch statement that uses $Content to determine which types of objects we're going to create
		foreach item, assign all properties to the object
		attach the object to $ReturnData
		
		#>
		
		$PrtgObjectType = switch ($Content) {
			"probes"	{ "PrtgShell.PrtgProbe" }
			"groups"	{ "PrtgShell.PrtgGroup" }
			"devices"	{ "PrtgShell.PrtgDevice" }
			"sensors"	{ "PrtgShell.PrtgSensor" }
			"todos"		{ "PrtgShell.PrtgTodo" }
			"messages"	{ "PrtgShell.PrtgMessage" }
			"values"	{ "PrtgShell.PrtgValue" }
			"channels"	{ "PrtgShell.PrtgChannel" }
			"history"	{ "PrtgShell.PrtgHistory" }
		}
		
		
		

		foreach ($item in $Data.$Content.item) {
			$ThisObject = New-Object $PrtgObjectType
			#$ThisRow = "" | Select-Object $SelectedColumns
			foreach ($Prop in $SelectedColumns) {
				if ($Content -eq "channels" -and $Prop -eq "lastvalue_raw") {
					# fix a bizarre formatting bug
					#$ThisObject.$Prop = HelperFormatHandler $item.$Prop
					$ThisObject.$Prop = $item.$Prop
				} elseif ($HTMLColumns -contains $Prop) {
					# strip HTML, leave bare text
					$ThisObject.$Prop =  $item.$Prop -replace "<[^>]*?>|<[^>]*>", ""
				} else {
					$ThisObject.$Prop = $item.$Prop
				}
			}
			$ReturnData += $ThisObject
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




function Get-PrtgObject {

	Param (
		[Parameter(Mandatory=$false,Position=0)]
		[int]$ObjectId = 0
	)

	BEGIN {
		if ($PRTG.Protocol -eq "https") { $PRTG.OverrideValidation() }
	}

	PROCESS {

		$Parameters = @{
			"content" = "sensortree"
			"id" = $ObjectId
		}
		
		$url = $PrtgServerObject.UrlBuilder("api/table.xml",$Parameters)

		##### data returned; do!

		if ($Raw) {
			$QueryObject = HelperHTTPQuery $url
			return $QueryObject.Data
		}

		$QueryObject = HelperHTTPQuery $url -AsXML
		$Data = $QueryObject.Data

		$DeviceType = $Data.prtg.sensortree.nodes.SelectNodes("*[1]").LocalName
		
		return $Data.prtg.sensortree.nodes.SelectNodes("*[1]")
		
		$ReturnData = @()
		
		<#
		
		HOW THIS WILL LIKELY NEED TO WORK
		---
		
		build a switch statement that uses $Content to determine which types of objects we're going to create
		foreach item, assign all properties to the object
		attach the object to $ReturnData
		
		#>
		
		$PrtgObjectType = switch ($Content) {
			"probes"	{ "PrtgShell.PrtgProbe" }
			"groups"	{ "PrtgShell.PrtgGroup" }
			"devices"	{ "PrtgShell.PrtgDevice" }
			"sensors"	{ "PrtgShell.PrtgSensor" }
			"todos"		{ "PrtgShell.PrtgTodo" }
			"messages"	{ "PrtgShell.PrtgMessage" }
			"values"	{ "PrtgShell.PrtgValue" }
			"channels"	{ "PrtgShell.PrtgChannel" }
			"history"	{ "PrtgShell.PrtgHistory" }
		}
		
		
		

		foreach ($item in $Data.$Content.item) {
			$ThisObject = New-Object $PrtgObjectType
			#$ThisRow = "" | Select-Object $SelectedColumns
			foreach ($Prop in $SelectedColumns) {
				if ($Content -eq "channels" -and $Prop -eq "lastvalue_raw") {
					# fix a bizarre formatting bug
					#$ThisObject.$Prop = HelperFormatHandler $item.$Prop
					$ThisObject.$Prop = $item.$Prop
				} elseif ($HTMLColumns -contains $Prop) {
					# strip HTML, leave bare text
					$ThisObject.$Prop =  $item.$Prop -replace "<[^>]*?>|<[^>]*>", ""
				} else {
					$ThisObject.$Prop = $item.$Prop
				}
			}
			$ReturnData += $ThisObject
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

###############################################################################

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

###############################################################################

function New-PrtgResult {
    PARAM (
        [Parameter(Mandatory=$True,Position=0)]
        [string]$Channel,

        [Parameter(Mandatory=$True,Position=1)]
        [decimal]$Value,

        [Parameter(Mandatory=$False)]
        [string]$Unit,

        [Parameter(Mandatory=$False)]
        [ValidateSet("one","kilo","mega","giga","tera","byte","kilobyte","megabyte","gigabyte","terabyte","bit","kilobit","megabit","gigabit","terabit")]
        [string]$SpeedSize,

        [Parameter(Mandatory=$False)]
        [ValidateSet("one","kilo","mega","giga","tera","byte","kilobyte","megabyte","gigabyte","terabyte","bit","kilobit","megabit","gigabit","terabit")]
        [string]$VolumeSize,

        [Parameter(Mandatory=$False)]
        [ValidateSet("second","minute","hour","day")]
        [string]$SpeedTime,

        [Parameter(Mandatory=$False)]
        [switch]$Difference,

        [Parameter(Mandatory=$False)]
        [ValidateSet("auto","all")]
        [string]$DecimalMode,

        [Parameter(Mandatory=$False)]
        [switch]$Warning,

        [Parameter(Mandatory=$False)]
        [switch]$IsFloat,

        [Parameter(Mandatory=$False)]
        [switch]$ShowChart,

        [Parameter(Mandatory=$False)]
        [switch]$ShowTable,

        [Parameter(Mandatory=$False)]
        [int]$LimitMaxError,

        [Parameter(Mandatory=$False)]
        [int]$LimitMinError,

        [Parameter(Mandatory=$False)]
        [int]$LimitMaxWarning,

        [Parameter(Mandatory=$False)]
        [int]$LimitMinWarning,

        [Parameter(Mandatory=$False)]
        [string]$LimitErrorMsg,

        [Parameter(Mandatory=$False)]
        [string]$LimitWarningMsg,

        [Parameter(Mandatory=$False)]
        [switch]$LimitMode,

        [Parameter(Mandatory=$False)]
        [string]$ValueLookup
    )

    BEGIN {
    }

    PROCESS {
        $ReturnObject = New-Object PrtgShell.XmlResult

        $ReturnObject.channel         = $Channel
        $ReturnObject.resultvalue     = $Value
        $ReturnObject.unit            = $Unit
        $ReturnObject.speedsize       = $SpeedSize
        $ReturnObject.volumesize      = $VolumeSize
        $ReturnObject.speedtime       = $SpeedTime
        $ReturnObject.mode            = $Mode
        $ReturnObject.decimalmode     = $DecimalMode
        $ReturnObject.Warning         = $Warning
        $ReturnObject.isfloat         = $IsFloat
        $ReturnObject.showchart       = $ShowChart
        $ReturnObject.showtable       = $ShowTable
        $ReturnObject.limitmaxerror   = $LimitMaxError
        $ReturnObject.limitminerror   = $LimitMinError
        $ReturnObject.limitmaxwarning = $LimitMaxWarning
        $ReturnObject.limitminwarning = $LimitMinWarning
        $ReturnObject.limiterrormsg   = $LimitErrorMsg
        $ReturnObject.limitwarningmsg = $LimitWarningMsg
        $ReturnObject.limitmode       = $LimitMode
        $ReturnObject.valuelookup     = $ValueLookup

        return $ReturnObject
    }
}

###############################################################################



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