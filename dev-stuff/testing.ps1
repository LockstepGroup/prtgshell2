<#

Add-Type -TypeDefinition ((gc .\prtgsensor.cs) -join "`n") -ReferencedAssemblies @(([System.Reflection.Assembly]::LoadWithPartialName("System.Web")).Location)
$NewSensor = New-Object PrtgShell.NewExeXml
$NewSensor
#>

Add-Type -TypeDefinition ((gc .\generatexml.cs) -join "`n") -ReferencedAssemblies @(
	([System.Reflection.Assembly]::LoadWithPartialName("System.Xml")).Location,
	([System.Reflection.Assembly]::LoadWithPartialName("System.Xml.Linq")).Location
	)
$NewDoc = New-Object PrtgShell.XmlDoc
$NewDoc



###############################################################################


ipmo .\prtgshell2.psm1
$OutputObject = New-Object PrtgShell.ExeXML

$OutputObject.text = "this is the return text"

$OutputObject.AddChannel((New-PrtgResult -Channel "My Channel 1" -Value (Get-Random 10000) -Unit BytesDisk))
$OutputObject.AddChannel((New-PrtgResult -Channel "My Channel 2" -Value (Get-Random 10000) -Unit BytesDisk))
$OutputObject.AddChannel((New-PrtgResult -Channel "My Channel 3" -Value (Get-Random 10000) -Unit Hooligans))

$OutputObject.PrintOutput()