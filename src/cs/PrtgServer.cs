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

        public void FlushHistory() {
            this.urlhistory.Clear();
        }


        public string UrlBuilder(string Action) {

            if (Action.StartsWith("/")) Action = Action.Substring(1);

            string[] Pieces = new string[4];
            Pieces[0] = this.ApiUrl;
            Pieces[1] = Action;
            Pieces[2] = "?";
            Pieces[3] = this.AuthString;

            string CompletedString = string.Join("", Pieces);
            this.urlhistory.Push(CompletedString);
            return CompletedString;
        }

        public string UrlBuilder(string Action, string[] QueryParameters) {

            if (Action.StartsWith("/")) Action = Action.Substring(1);

            string[] Pieces = new string[4];
            Pieces[0] = this.ApiUrl;
            Pieces[1] = Action;
            Pieces[2] = "?";
            Pieces[3] = this.AuthString;

            var FullString = new string[Pieces.Length + QueryParameters.Length];
            Pieces.CopyTo(FullString, 0);
            QueryParameters.CopyTo(FullString, Pieces.Length);

            string CompletedString = string.Join("", FullString);
            this.urlhistory.Push(CompletedString);
            return CompletedString;
        }

        public string UrlBuilder(string Action, Hashtable QueryParameters) {

            if (Action.StartsWith("/")) Action = Action.Substring(1);

            string[] Pieces = new string[5];
            Pieces[0] = this.ApiUrl;
            Pieces[1] = Action;
            Pieces[2] = "?";
            Pieces[3] = this.AuthString;

            foreach (DictionaryEntry KeyPair in QueryParameters) {
                if (KeyPair.Value.GetType() == typeof(string) || KeyPair.Value.GetType() == typeof(int)) {
                    Pieces[4] += ("&" + KeyPair.Key + "=" + KeyPair.Value);
                } else {
                    string[] ConvertedArray = ((IEnumerable)KeyPair.Value).Cast<object>().Select(x => x.ToString()).ToArray();
                    foreach (string SubValue in ConvertedArray) {
                        Pieces[4] += ("&" + KeyPair.Key + "=" + SubValue);
                    }
                }
            }

            string CompletedString = string.Join("", Pieces);
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


        private System.Uri prtguri;

        // this likely doesn't need to be public
        // or exist, this is just for peeking
        public System.Uri PrtgUri {
            get { return this.prtguri; }
        }

        private Hashtable parsed_querystring;

        public void SetPrtgUri(string serverstring) {
            this.prtguri = new System.Uri(serverstring);

            this.Server = this.prtguri.Host;
            this.Port = this.prtguri.Port;
            this.Protocol = this.prtguri.Scheme;

            NameValueCollection querystring_nvc = HttpUtility.ParseQueryString(this.prtguri.Query);

            this.parsed_querystring = new Hashtable();

            foreach (string key in querystring_nvc) {
                this.parsed_querystring.Add(key, querystring_nvc[key]);
            }

            // this syntax is all wrong
            // if the hashtable includes these two values, set them
            //if (this.parsed_querystring.username) {
            //	this.UserName = this.parsed_querystring.username;
            //}

            //if (this.parsed_querystring.passhash) {
            //	this.PassHash = this.parsed_querystring.passhash;
            //}
        }

        public HttpQueryReturnObject HttpQuery(string Url, bool AsXml = true) {
            // this works. there's some logic missing from the original powershell version of this
            // that may or may not be important (it was error handling of some flavor)
            // also, all requests should not be treated as XML for this to be more generic
            // (the powershell version had an "-asxml" flag to handle this)

            HttpWebResponse Response = null;
            HttpStatusCode StatusCode = new HttpStatusCode();

            try {
                HttpWebRequest Request = WebRequest.Create(Url) as HttpWebRequest;

                //if (Response.ContentLength > 0) {

                try {
                    Response = Request.GetResponse() as HttpWebResponse;
                    StatusCode = Response.StatusCode;
                } catch (WebException we) {
                    StatusCode = ((HttpWebResponse)we.Response).StatusCode;
                }

                string DetailedError = Response.GetResponseHeader("X-Detailed-Error");
                // }

            } catch {
                throw new HttpException("httperror");
            }

            if (Response.StatusCode.ToString() == "OK") {
                StreamReader Reader = new StreamReader(Response.GetResponseStream());
                string Result = Reader.ReadToEnd();
                XmlDocument XResult = new XmlDocument();

                if (AsXml) {
                    XResult.LoadXml(Result);
                }

                Reader.Close();
                Response.Close();

                HttpQueryReturnObject ReturnObject = new HttpQueryReturnObject();
                ReturnObject.Statuscode = StatusCode;
                if (AsXml) { ReturnObject.Data = XResult; }
                ReturnObject.RawData = Result;
                return ReturnObject;

            } else {

                throw new HttpException("httperror");
            }
        }
    }
}