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

    public class NewPingSensor : PrtgSensorCreator {
		
        public NewPingSensor () {
            this.sensortype = "ping";
            this.inherittriggers = true;
            this.name_ = "Ping";
            this.tags_ = new string[] {"prtgshell","pingsensor"};
            this.intervalgroup = true;  
            this.interval = 30;
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

                return queryString.ToString();
            }
        }
    }
}