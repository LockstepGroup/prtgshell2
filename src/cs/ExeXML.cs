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

    public class ExeXML {
		private string Text;
		
        public string text {
			get {
				return this.Text;
			}
			set {
				if (value.Length < 2000) {
					this.Text = value;
				} else  {
					throw new ArgumentOutOfRangeException("Invalid value. Maximum length is 2000 characters.");
				}
			}
		}

        public bool error { get; set; }
		
		// should this be read-only?
		// does there need to be a RemoveChannel method?
		public List<PrtgShell.XmlResult> channels { get; set; }
		
		public void AddChannel (PrtgShell.XmlResult channel) {
			this.channels.Add(channel);
		}
		
		
		public ExeXML () {
			this.channels = new List<PrtgShell.XmlResult>();
		}
		
		
		public string PrintError (string ErrorText) {
			XDocument XmlObject = new XDocument(
				new XElement("prtg",
					new XElement("error", 1),
					new XElement("text", ErrorText)
				)
			);

			return XmlObject.ToString();
		}
		
		
		// i suppose there should also be a method here to generate the XML object out, eh?
		// how this will actually function needs to be nailed down
		// this is the method that will need to determine what in this object is worthy of spitting out and how
		public string PrintOutput () {
			// make the root, add the text
			XDocument XmlObject = new XDocument(
				new XElement("prtg",
					new XElement("text",this.Text)
				)
			);
			
			// loop through the channels
			foreach (PrtgShell.XmlResult XmlResult in this.channels) {
				
				// make the result
				XElement ThisChannel = new XElement("result",
					new XElement("channel", XmlResult.channel),
					new XElement("value", XmlResult.resultvalue),
					new XElement("unit", XmlResult.unit)
				);
				

				if (!String.IsNullOrEmpty(XmlResult.customunit)) {
					ThisChannel.Add(
						new XElement("customunit", XmlResult.customunit)
					);
				}

                if (XmlResult.valuemode) {
                    ThisChannel.Add(
                        new XElement("mode", XmlResult.Mode)
                        );
                }

                if (XmlResult.warning) {
                    ThisChannel.Add(
                        new XElement("warning", Convert.ToString(Convert.ToInt32(XmlResult.warning)))
                        );
                }

				///////////////////////////////////////////
                // these both default to true; the usual methods of simply not including the tag when they're
                // not set won't work here.
                // will it work if we just flip the check? (if false...)
                if (!XmlResult.showchart) {
                    ThisChannel.Add(
                        new XElement("showchart", Convert.ToString(Convert.ToInt32(XmlResult.showchart)))
                        );
                }

                if (!XmlResult.showtable) {
                    ThisChannel.Add(
                        new XElement("showtable", Convert.ToString(Convert.ToInt32(XmlResult.showtable)))
                        );
                }

				///////////////////////////////////////////
                // limits
                if (XmlResult.limitmode) {
                    ThisChannel.Add(
                        new XElement("limitmode", Convert.ToString(Convert.ToInt32(XmlResult.limitmode)))
                        );
                }

                if (XmlResult.limitminwarning > -1) {
                    ThisChannel.Add(
                        new XElement("limitminwarning", Convert.ToString(XmlResult.limitminwarning))
                        );
                }

                if (XmlResult.limitmaxwarning > -1) {
                    ThisChannel.Add(
                        new XElement("limitmaxwarning", Convert.ToString(XmlResult.limitmaxwarning))
                        );
                }

                if (XmlResult.limitminerror > -1) {
                    ThisChannel.Add(
                        new XElement("limitminwarning", Convert.ToString(XmlResult.limitminwarning))
                        );
                }

                if (XmlResult.limitmaxerror > -1) {
                    ThisChannel.Add(
                        new XElement("limitmaxwarning", Convert.ToString(XmlResult.limitmaxwarning))
                        );
                }

                if (!(String.IsNullOrEmpty(XmlResult.limitwarningmsg))) {
                    ThisChannel.Add(
                        new XElement("mode", XmlResult.limitwarningmsg)
                        );
                }

                if (!(String.IsNullOrEmpty(XmlResult.limiterrormsg))) {
                    ThisChannel.Add(
                        new XElement("mode", XmlResult.limiterrormsg)
                        );
                }
				
				///////////////////////////////////////////
				// rates and speeds
				if (!(String.IsNullOrEmpty(XmlResult.volumesize))) {
                    ThisChannel.Add(
                        new XElement("mode", XmlResult.volumesize)
                        );
                }
				
				if (!(String.IsNullOrEmpty(XmlResult.speedsize))) {
                    ThisChannel.Add(
                        new XElement("mode", XmlResult.speedsize)
                        );
                }
				
				if (!(String.IsNullOrEmpty(XmlResult.speedtime))) {
                    ThisChannel.Add(
                        new XElement("mode", XmlResult.speedtime)
                        );
                }
				
				
				if (!(String.IsNullOrEmpty(XmlResult.valuelookup))) {
                    ThisChannel.Add(
                        new XElement("mode", XmlResult.valuelookup)
                        );
                }
				
				///////////////////////////////////////////
				// decimalmode & floats
				// this could use further review as well
				// not at all convinced that decimalmode actually works in the API,
				// but the way we handle it may also not be correct
				// isfloat works properly, but there might be a more elegant way to handle it
				if (!(String.IsNullOrEmpty(XmlResult.decimalmode))) {
                    ThisChannel.Add(
                        new XElement("mode", XmlResult.decimalmode)
                        );
                }
				
                if (XmlResult.isfloat) {
                    ThisChannel.Add(
                        new XElement("float",
                            Convert.ToString(Convert.ToInt32(XmlResult.isfloat)))
                        );
                }
				

				
				
				// add everything we've done here to the root
				XmlObject.Element("prtg").Add(ThisChannel);
			}

			// return beautiful, well-formatted xml
			return XmlObject.ToString();
		}
    }

}