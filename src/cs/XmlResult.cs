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

    
    public class XmlResult {
        public string channel { get; set; }
        public decimal resultvalue { get; set; }

		List<string> ValidUnit = new List<string>(new string[] {
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
		
		private string Unit;
		
        public string unit {
			get {
				return this.Unit;
			}
			set {
				if ((ValidUnit.FindIndex(x => x.Equals(value, StringComparison.OrdinalIgnoreCase) ) != -1) || String.IsNullOrEmpty(value)) {
					this.Unit = value;
				} else  {
					this.Unit = "Custom";
					this.customunit = value;
				}
			}
		}
		
        public string customunit { get; set; }

		
		
		
		List<string> ValidSpeedVolumeSize = new List<string>(new string[] {
			"One",
			"Kilo",
			"Mega",
			"Giga",
			"Tera",
			"Byte",
			"KiloByte",
			"MegaByte",
			"GigaByte",
			"TeraByte",
			"Bit",
			"KiloBit",
			"MegaBit",
			"GigaBit",
			"TeraBit"
		});
		
		private string SpeedSize;
        public string speedsize {
			get {
				return this.SpeedSize;
			}
			set {
				if ((ValidSpeedVolumeSize.FindIndex(x => x.Equals(value, StringComparison.OrdinalIgnoreCase) ) != -1) || String.IsNullOrEmpty(value)) {
					this.SpeedSize = value;
				} else  {
					throw new ArgumentOutOfRangeException("Invalid value. Valid values are: " + string.Join(", ", ValidSpeedVolumeSize.ToArray()));
				}
			}
		}

		private string VolumeSize;
        public string volumesize {
			get {
				return this.VolumeSize;
			}
			set {
				if ((ValidSpeedVolumeSize.FindIndex(x => x.Equals(value, StringComparison.OrdinalIgnoreCase) ) != -1) || String.IsNullOrEmpty(value)) {
					this.VolumeSize = value;
				} else  {
					throw new ArgumentOutOfRangeException("Invalid value. Valid values are: " + string.Join(", ", ValidSpeedVolumeSize.ToArray()));
				}
			}
		}

		
		
		
		List<string> ValidSpeedTime = new List<string>(new string[] {
			"Second",
			"Minute",
			"Hour",
			"Day"
		});
		
		private string SpeedTime;
        public string speedtime {
			get {
				return this.SpeedTime;
			}
			set {
				if ((ValidSpeedTime.FindIndex(x => x.Equals(value, StringComparison.OrdinalIgnoreCase) ) != -1) || String.IsNullOrEmpty(value)) {
					this.SpeedTime = value;
				} else  {
					throw new ArgumentOutOfRangeException("Invalid value. Valid values are: " + string.Join(", ", ValidSpeedTime.ToArray()));
				}
			}
		}
		
		

        public bool valuemode { get; set; }
        // 0 = Absolute, 1 = Difference
        public string Mode {
            get {
                if (this.valuemode) {
                    return "Difference";
                } else { 
                    return "Absolute";
                }
            }
        }
        

        public bool isfloat { get; set; }

		
		
		List<string> ValidDecimalMode = new List<string>(new string[] { "Auto","All" });
		
		private string DecimalMode;
        public string decimalmode {
			get {
				if (String.IsNullOrEmpty(this.DecimalMode)) {
					// if it hasn't been set, automatically determine the values
					if (this.isfloat) {
						return "All";
					} else {
						return "Auto";
					}
				} else {
					return this.DecimalMode;
				}
			}
			set {
				if ((ValidDecimalMode.FindIndex(x => x.Equals(value, StringComparison.OrdinalIgnoreCase) ) != -1) || String.IsNullOrEmpty(value)) {
					this.DecimalMode = value;
				} else  {
					throw new ArgumentOutOfRangeException("Invalid value. Valid values are: " + string.Join(", ", ValidDecimalMode.ToArray()));
				}
			}
		}
		
		

        public bool warning { get; set; }
        public bool showchart { get; set; }
        public bool showtable { get; set; }

        // we're going to need to get more clever with these as well
        // the way it was handled in powershell revolved around the possibility of the values not being set
        // that can't happen here, so we're going to set them to -1 as a default in the constructor (-1 = not set)
        public int limitmaxerror { get; set; }
        public int limitmaxwarning { get; set; }
        public int limitminwarning { get; set; }
        public int limitminerror { get; set; }
        public string limiterrormsg { get; set; }
        public string limitwarningmsg { get; set; }

        public bool limitmode {
            get {
                // if any of the six limit options are set, return true
                // otherwise, return false
                if ((this.limitmaxerror > -1) || (this.limitminerror > -1) || (this.limitmaxwarning > -1) || (this.limitminwarning > -1)) { //  || String.IsNullOrEmpty(this.limiterrormsg) || String.IsNullOrEmpty(this.limitwarningmsg)) {
                    return true;
                } else {
                    return false;
                }
            }
        }

        public string valuelookup { get; set; }

        public XmlResult () {
			this.isfloat = false;
            this.warning = false;
            this.showchart = true;
            this.showtable = true;

            this.limitmaxerror = -1;
            this.limitminerror = -1;
            this.limitmaxwarning = -1;
            this.limitminwarning = -1;
        }
    }

}