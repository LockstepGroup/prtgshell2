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

    public class NewSnmpTrafficSensor : PrtgSensorCreator {
        public int interfacenumber_ { get; set; }
        public int stack_ { get; set; }

//    "interfacenumber__check" = "$InterfaceNumber`:$Name|$Name|Connected|1 GBit/s|Ethernet|1|$Name|1000000000|3|2|" # don't know what the 3|2 are, or if the other bits matter

        private string interfacenumber__check {
            get {
                string interfacenumberlabel = this.interfacenumber_.ToString();
                interfacenumberlabel += ":" + this.name_ + "|" + this.name_;
                interfacenumberlabel += "Connected|1 GBit/s|Ethernet|1|" + this.name_ + "|1000000000|3|2|";
                return interfacenumberlabel;
            }
        }
        //string interfacenumber__check = this.interfacenumber_.ToString();
        //interfacenumber__check += ":" + this.name_ + "|" + this.name_;
        //interfacenumber__check += "Connected|1 GBit/s|Ethernet|1|" + this.name_ + "|1000000000|3|2|";
        
        public NewSnmpTrafficSensor () {
            this.sensortype = "snmptraffic";
            this.inherittriggers = true;
            this.name_ = "Snmp Traffic Sensor";
            this.tags_ = new string[] {"prtgshell","snmptrafficsensor","bandwidthsensor"};
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
                
                queryString["interfacenumber_"] = this.interfacenumber_.ToString();
                queryString["interfacenumber__check"] = this.interfacenumber__check;
                queryString["namein_"] = "Traffic In";
                queryString["nameout_"] = "Traffic Out";
                queryString["namesum_"] = "Traffic Total";
                queryString["stack_"] = this.stack_.ToString();

                return queryString.ToString();
            }
        }
    }
    /*
    "name_"                  = $Name
    "tags_"                  = "prtgshell snmptrafficsensor bandwidthsensor $Tags"
    "priority_"              = $Priority
    "intervalgroup"          = 1
    "interval_"              = "$Interval|$Interval seconds"
    "inherittriggers"        = 1
    "id"                     = $ParentId
    "sensortype"             = "snmptraffic"

    "interfacenumber_"       = 1
    "interfacenumber__check" = "$InterfaceNumber`:$Name|$Name|Connected|1 GBit/s|Ethernet|1|$Name|1000000000|3|2|" # don't know what the 3|2 are, or if the other bits matter
    "namein_"                = "Traffic In"
    "nameout_"               = "Traffic Out"
    "namesum_"               = "Traffic Total"
    "stack_"                 = 0
    */

}