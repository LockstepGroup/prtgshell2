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

    
    public class PrtgGroupCreator {
		
		public string name_ { get; set; }
		public string[] tags_ { get; set; }
		public int id { get; set; }
		
        public string QueryString {
            get {
                NameValueCollection queryString = System.Web.HttpUtility.ParseQueryString(string.Empty);

                queryString["id"] = this.id.ToString();
                queryString["name_"] = this.name_;
                queryString["tags_"] = String.Join(" ",this.tags_);

                return queryString.ToString();
            }
        }
		
        public PrtgGroupCreator () {
			this.tags_ = new string[] {""};
        }
		
    }
	

}