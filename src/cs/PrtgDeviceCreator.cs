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

    
    public class PrtgDeviceCreator {
		
		public string name_ { get; set; }
		public string host_ { get; set; }
		public string[] tags_ { get; set; }
		public int id { get; set; }
		public string deviceicon_ { get; set; }
		//public int discoverytype_ = 0;
		//public int discoveryschedule_ = 0;
		
		public string discoverytype_ { get; set; }
		public string devicetemplate_ { get; set; }
		public string devicetemplate__check { get; set; }
		
        public string QueryString {
            get {
                NameValueCollection queryString = System.Web.HttpUtility.ParseQueryString(string.Empty);

                queryString["id"] = this.id.ToString();
                queryString["name_"] = this.name_;
                queryString["host_"] = this.host_;
                queryString["deviceicon_"] = this.deviceicon_;
                queryString["tags_"] = String.Join(" ",this.tags_);
                //queryString["discoverytype_"] = Convert.ToString(Convert.ToInt32(this.discoverytype_));
                //queryString["discoveryschedule_"] = Convert.ToString(Convert.ToInt32(this.discoveryschedule_));
				
                if (!string.IsNullOrEmpty(this.discoverytype_)) { queryString["discoverytype_"] = this.discoverytype_; }
                if (!string.IsNullOrEmpty(this.devicetemplate_)) { queryString["devicetemplate_"] = this.devicetemplate_; }
                if (!string.IsNullOrEmpty(this.devicetemplate__check)) { queryString["devicetemplate__check"] = this.devicetemplate__check; }

                return queryString.ToString();
            }
        }
		
        public PrtgDeviceCreator () {
            this.deviceicon_ = "a_server_1.png";
			this.tags_ = new string[] {""};
        }
    }
}

/*



id:2517
name_:DeviceName!
ipversion_:0
host_:google.com
hostv6_:
tags_:
deviceicon_:a_server_1.png
discoverytype_:0
devicetemplate_:1
devicetemplate_:1
discoveryschedule_:0
windowsconnection:0
windowsconnection:1
windowslogindomain_:
windowsloginusername_:
windowsloginpassword_:
linuxconnection:0
linuxconnection:1
linuxloginusername_:
linuxloginmode_:0
linuxloginpassword_:
privatekey_:
wbemprotocol_:https
wbemportmode_:0
wbemport_:5989
sshport_:22
sshelevatedrights_:1
elevationnamesudo_:
elevationnamesu_:
elevationpass_:
sshversion_devicegroup_:2
vmwareconnection:0
vmwareconnection:1
esxuser_:
esxpassword_:
esxprotocol_:0
vmwaresessionpool_:1
dbcredentials:0
dbcredentials:1
usedbcustomport_:0
dbport_:
dbauth_:0
dbuser_:
dbpassword_:
dbtimeout_:60
cloudcredentials:0
cloudcredentials:1
awsak_:
awssk_:
snmpversiongroup:0
snmpversiongroup:1
snmpversion_:V2
snmpcommv1_:public
snmpcommv2_:public
snmpauthmode_:authpHMACMD596
snmpuser_:
snmpauthpass_:
snmpencmode_:DESPrivProtocol
snmpencpass_:
snmpcontext_:
snmpport_:161
snmptimeout_:5
accessgroup:0
accessgroup:1
accessrights_:1
accessrights_:1
accessrights_201:-1

*/