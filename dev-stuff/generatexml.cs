using System;
using System.IO;
using System.Xml;
using System.Xml.Linq;
using System.Text;

namespace PrtgShell {
	public class XmlDoc {
	
	
		public string MakeXml () {
		
			XmlDocument doc = new XmlDocument();

			XmlElement element1 = doc.CreateElement( "", "body", "" );
			doc.AppendChild( element1 );

			XmlElement element2 = doc.CreateElement( "", "level1", "" );
			element1.AppendChild( element2 );

			XmlElement element3 = doc.CreateElement( "", "level2", "" );
			XmlText text1 = doc.CreateTextNode( "text" );
			element3.AppendChild( text1 );
			element2.AppendChild( element3 );

			XmlElement element4 = doc.CreateElement( "", "level2", "" );
			XmlText text2 = doc.CreateTextNode( "another text" );
			element4.AppendChild( text2 );
			element2.AppendChild( element4 );
			
			return doc.OuterXml;
		}
		
		public string PrintXML(string XML) {
			String Result = "";

			MemoryStream mStream = new MemoryStream();
			XmlTextWriter writer = new XmlTextWriter(mStream, Encoding.UTF8); //Encoding.Unicode);
			XmlDocument document   = new XmlDocument();

			try {
				// Load the XmlDocument with the XML.
				document.LoadXml(XML);

				writer.Formatting = Formatting.Indented;

				// Write the XML into a formatting XmlTextWriter
				document.WriteContentTo(writer);
				writer.Flush();
				mStream.Flush();

				// Have to rewind the MemoryStream in order to read
				// its contents.
				mStream.Position = 0;

				// Read MemoryStream contents into a StreamReader.
				StreamReader sReader = new StreamReader(mStream);

				// Extract the text from the StreamReader.
				String FormattedXML = sReader.ReadToEnd();

				Result = FormattedXML;
			}
			catch (XmlException) {
				
			}

			mStream.Close();
			writer.Close();

			return Result;
		}
		
		
		
		/*
		
		            <prtg>
            <result>
            <channel>First channel</channel>
            <value>10</value>
            </result>
            <result>
            <channel>Second channel</channel>
            <value>20</value>
            </result>
            </prtg>
To return an error, the format is:

              <prtg>
              <error>1</error>
              <text>Your error message</text>
              </prtg>
		
		*/
		
		public string SetPrtgError (string ErrorText) {
			XDocument XmlObject = new XDocument(
				new XElement("prtg",
					new XElement("error", 1),
					new XElement("text", ErrorText)
				)
			);

			return XmlObject.ToString();
		}
		
		
		public string Xml2 () {
		
			XDocument objXDoc = new XDocument(
				new XComment("Employee Details"),
				new XElement("Employees",
					new XElement("Employee",
						new XElement("Name",
							new XElement("FirstName", "Henry"),
							new XElement("LastName", "Ford")
						),
						new XElement("Age","65")
					),
					 new XElement("Employee",
						new XElement("Name",
							new XElement("FirstName", "Bill"),
							new XElement("LastName", "Gates")
						),
						new XElement("Age", "55")
					)
				)
			);

			objXDoc.Declaration = new XDeclaration("1.0", "utf-8", "true");
		
			return objXDoc.ToString();
		}
	}
}