Add-Type -TypeDefinition ((gc .\prtgsensor.cs) -join "`n")
$NewSensor = New-Object PrtgShell.NewExeXml
$NewSensor