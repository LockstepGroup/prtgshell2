$Device     = "uned.addicks.us"
$Community  = "pysnmptest"
$DeviceId   = "2008"
$SensorName = "ge.1.2 - test"
$PrtgHost   = "https://athena-temp.addicks.us/"
$PrtgUser   = "prtgadmin"
$PrtgHash   = "1510974160"

$PrtgHostRx = [regex] ".+?\/\/(.+?)\/"
$PrtgHost   = $PrtgHostRx.Match("$($PrtgHost)").Groups[1].Value

$SensorNameRx = [regex] "(.+?)\ "
$SensorName   = $SensorNameRx.Match($SensorName).Groups[1].Value

$WorkDir     = "$($env:temp)\$DeviceId"
$LockFile    = "$WorkDir\.lockfile"
$LastRun     = "$WorkDir\.lastrun"
$Interval    = 1
$DesiredTime = (Get-Date).AddSeconds($Interval * -1)

if (!(Test-Path $WorkDir)) { $MakeDir = New-Item -Path $WorkDir -ItemType Directory }

if (Test-Path $LastRun) {
    $LastWrite = (gci $LastRun).LastWriteTime
    if (($DesiredTime -lt $LastWrite) -or (Test-Path $lockfile)) {
        (gc "$WorkDir\$Name")
        return "no run"
    }
}

$CreateLastRun = New-Item -Path $LastRun  -ItemType File -Force
$CreateLastRun = New-Item -Path $LockFile -ItemType File -Force

###############################################################################
# Connect to Prtg Server and get the current sensors with the tag netapplun

$PrtgConnection = Get-PrtgServer $PrtgHost $PrtgUser $PrtgHash

$UniqueTag      = "snmpinterface"
$CurrentSensors = Get-PrtgTableData sensors $DeviceId -FilterTags $UniqueTag

###############################################################################
#

function Test-ModuleImport ([string]$Module) {
    Import-Module $Module -ErrorAction SilentlyContinue
    if (!($?)) { return $false } `
        else   { return $true }
}

$Modules = @("C:\dev\prtgshell\prtgshell.psm1"
             "C:\_strap\sharpsnmp\sharpsnmp.psm1")

foreach ($m in $Modules) {
    if ($Debug) { "...importing $m" }
    $Import = Test-ModuleImport $m
    if (!($Import)) {
    return @"
<prtg>
  <error>1</error>
  <text>$m module not loaded: ensure the module is visible for 32-bit PowerShell</text>
</prtg>
"@
    }
}

function New-OidObject ($Oid,$Label) {

    $OidObject                = "" | Select Oid,Label
    $OidObject.Oid            = $Oid
    $OidObject.Label          = $Label

    return $OidObject
}

$OidTable  = @()
$OidTable += New-OidObject "1.3.6.1.2.1.2.2.1.7"  AdminStatus
$AdminLookup = @{ 1 = "up"
                  2 = "down"
                  3 = "testing" }

$OidTable += New-OidObject "1.3.6.1.2.1.2.2.1.8"  OperStatus
$OperLookup = @{ 1 = "up"
                 2 = "down"
                 3 = "testing"
                 4 = "unknown"
                 5 = "dormant"
                 6 = "not present"
                 7 = "lower layer down" }

$OidTable += New-OidObject "1.3.6.1.2.1.2.2.1.10" InOctets
$OidTable += New-OidObject "1.3.6.1.2.1.2.2.1.16" OutOctets

$OidTable += New-OidObject "1.3.6.1.2.1.2.2.1.14" InErrors
$OidTable += New-OidObject "1.3.6.1.2.1.2.2.1.20" OutErrors

$OidTable += New-OidObject "1.3.6.1.2.1.2.2.1.13" InDiscards
$OidTable += New-OidObject "1.3.6.1.2.1.2.2.1.19" OutDiscards

$OidTable += New-OidObject "1.3.6.1.2.1.2.2.1.5"  Speed

# $OidTable += New-OidObject "1.3.6.1.4.1.9.5.1.4.1.1.10" Duplex #This may just be cisco

function Get-InterfaceInfo ($Index) {
    $Oids = @()
    foreach ($o in $OidTable) {
        $FullOid  = $o.Oid + "." + $Index
        $Oids    += $FullOid
    }

    try   {
        $Results = Invoke-SnmpGet $Device $Community $Oids
    } catch {
        Remove-Item $LockFile
        return Set-PrtgError "Snmp Timeout"
    }
    
    foreach ($o in $OidTable) {
        $Data = ($Results | ? { $_.OID -eq "`.$($o.Oid)`.$Index" }).Data
        Set-Variable -Name $o.Label -Value $Data
    }

    $Speed = 1000000000 / 1000000
    if ($Speed -gt 999) { $FriendlySpeed = "1Gb/s"} `
                   else { $FriendlySpeed = "$Speed`Mb/s" }

    $FriendlyAdmin = $AdminLookup.Get_Item([int]$AdminStatus)

    $FriendlyOper  = $OperLookup.Get_Item([int]$OperStatus)

    $Message = "Port is admin $FriendlyAdmin, operationally $FriendlyOper"

    $InOctets    = [int64]$InOctets
    $OutOctets   = [int64]$OutOctets
    $TotalOctets = $InOctets + $OutOctets

    $XmlOutput  = "<prtg>`n"
    $XmlOutput += "  <text>$Message</text>`n"

    $XmlOutput += Set-PrtgResult "Total Traffic"    $TotalOctets  BytesBandwidth -ss KiloBit -mo Difference -sc -dm Auto
    $XmlOutput += Set-PrtgResult "Inbound Traffic"  $InOctets     BytesBandwidth -ss KiloBit -mo Difference -sc -dm Auto
    $XmlOutput += Set-PrtgResult "Outbound Traffic" $OutOctets    BytesBandwidth -ss KiloBit -mo Difference -sc -dm Auto

    $XmlOutput += Set-PrtgResult "Inbound Errors"   $InErrors     packets
    $XmlOutput += Set-PrtgResult "Outbound Errors"  $OutErrors    packets

    $XmlOutput += Set-PrtgResult "Inbound Discards" $InDiscards   packets
    $XmlOutput += Set-PrtgResult "Inbound Discards" $InDiscards   packets

    $XmlOutput += "</prtg>"

    $XmlOutput
}

$Create  = @()
$IndexRx = [regex] "\d+$"

try   {
    $Aliases = Invoke-SnmpWalk $Device $Community .1.3.6.1.2.1.31.1.1.1.18
} catch {
    Remove-Item $LockFile
    return Set-PrtgError "Snmp Timeout"
}

try   {
    $Names   = Invoke-SnmpWalk $Device $Community .1.3.6.1.2.1.31.1.1.1.1
} catch {
    Remove-Item $LockFile
    return Set-PrtgError "Snmp Timeout"
}

foreach ($a in ($Aliases | ? { $_.Data })) {
    $Index = $IndexRx.Match($a.OID).Value
    $Name  = ($Names | ? { $_.Oid -eq ".1.3.6.1.2.1.31.1.1.1.1.$Index" }).Data
    Get-InterfaceInfo $Index | Out-File "$WorkDir\$Name"

    $Lookup = $CurrentSensors | ? { $_.Sensor -eq $Lun.Path }

    if (!($Lookup)) {
    $Create += $Name

    $SensorObject                 = "" | Select Name,Tags,Priority,Script,ExeParams,Environment,SecurityContext,Mutex,ExeResult,ParentId
    $SensorObject.Name            = "$Name - $($a.Data)"
    $SensorObject.Tags            = "xmlexesensor snmpinterface" # space seperated tags
    $SensorObject.Priority        = 3 # 1-5
    $SensorObject.Script          = "Lockstep - NetApp - Lun Usage.ps1"
    $SensorObject.ExeParams       = ""
    $SensorObject.Environment     = 1 # 0 for default, 1 for placeholders
    $SensorObject.SecurityContext = 1 # 0 for probe service, 1 for windows creds of device
    $SensorObject.Mutex           = ""
    $SensorObject.ExeResult       = 1 # 0 discard, 1 always write result, 2 write result on error
    $SensorObject.ParentId        = $DeviceId
        
    $CreateSensor = New-PrtgSensor $SensorObject
    }
}

Remove-Item -Path $LockFile
return (gc "$WorkDir\$SensorName")