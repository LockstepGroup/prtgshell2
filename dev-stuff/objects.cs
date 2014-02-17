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

}