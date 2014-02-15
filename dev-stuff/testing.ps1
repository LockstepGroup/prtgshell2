Add-Type -TypeDefinition ((gc .\prtgsensor.cs) -join "`n") -ReferencedAssemblies @(([System.Reflection.Assembly]::LoadWithPartialName("System.Web")).Location)
$NewSensor = New-Object PrtgShell.NewExeXml
$NewSensor