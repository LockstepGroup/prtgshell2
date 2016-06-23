using System;
using System.IO;
using System.Net;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;
using System.Collections;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Linq;
using System.Web;
using System.Xml;
using System.Xml.Linq;



namespace PrtgShell {

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
                if (value >= 0 && value <= 5) {
                    this.priority = value;
                } else {
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
        public string condition { get; set; }
        public string fold { get; set; }
        public string groupnum { get; set; }
        public string devicenum { get; set; }
    }

    public class PrtgGroup : PrtgProbe {
        public string group { get; set; }
        public string location { get; set; }
    }

    public class PrtgDevice : PrtgObject {
        public string device { get; set; }
        public string group { get; set; }
        public string grpdev { get; set; }
        public string deviceicon { get; set; }
        public string host { get; set; }
        public string icon { get; set; }
        public string location { get; set; }
    }

    public class PrtgSensor : PrtgObject {
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