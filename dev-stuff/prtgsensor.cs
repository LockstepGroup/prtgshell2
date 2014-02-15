
using System;
using System.Net;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;
using System.Collections;
using System.Collections.Generic;
using System.Linq;

namespace PrtgShell {
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
	
	
	// public class exexml {
	
		// private int priority = 3;
		// private int exeresult = 0;
		
		// public string Name { get; set; }
		// public string Tags { get; set; }
		// public int Priority {
			// get {
				// return this.priority;
			// }
			// set {
				// if (value > 0 && value <= 5) {
					// this.priority = value;
				// } else  {
					// throw new ArgumentOutOfRangeException("Invalid value. Value must be between 0 and 5");
				// }
			// }
		// }
		// public string Script { get; set; }
		// public string ExeParams { get; set; }
		// public bool Environment { get; set; }
		// public bool SecurityContext { get; set; }
		// public string Mutex { get; set; }
		// public int ExeResult {
			// get {
				// return this.exeresult;
			// }
			// set {
				// if (value > 0 && value <= 2) {
					// this.exeresult = value;
				// } else  {
					// throw new ArgumentOutOfRangeException("Invalid value. Value must be between 0 and 2");
				// }
			// }
		// }
		// public int ParentId { get; set; }
		
	// }
	
	
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
		public string name_ { get; set; }
		public string[] tags_ { get; set; }
		public string sensor_type { get; set; }
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
				return ToTimeString(this.polling_interval);
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
	
		// "exefile_" = "$($PrtgObject.Script)|$$(PrtgObject.Script)||" # WHAT THE FUCK
		// "exefilelabel" = "" # this is hidden by default; ??
		// "exeparams_" = $PrtgObject.ExeParams
		// "environment_" = $PrtgObject.Environment
		// "usewindowsauthentication_" = $PrtgObject.SecurityContext
		// "mutexname_" = $PrtgObject.Mutex
		// "timeout_" = 60
		// "writeresult_" = $PrtgObject.ExeResult # this can be 0 or 1 in v13, or 0-2 in v14 (2 being "write on error only")
		
		public string exeparams_ { get; set; }
		public bool environment_ { get; set; }
		public bool usewindowsauthentication_ { get; set; }
		public string mutexname_ { get; set; }
		public int timeout_ { get; set; }
		public int writeresult_ { get; set; }
		
		public NewExeXml () {
			this.sensor_type = "exexml";
			this.environment_ = false;
			this.usewindowsauthentication_ = false;
			this.inherittriggers = true;
			this.timeout_ = 60;
			this.writeresult_ = 0;
			this.name_ = "XML Custom EXE/Script Sensor";
			this.tags_ = new string[] {"xmlexesensor"};
			this.intervalgroup = true;	
			this.interval = 60
		}
	}
}