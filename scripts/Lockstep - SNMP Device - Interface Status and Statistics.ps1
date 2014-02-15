$Timer = Get-Date
function Test-ModuleImport ([string]$Module) {
    Import-Module $Module -ErrorAction SilentlyContinue
    if (!($?)) { return $false } `
        else   { return $true }
}

$Modules = @("prtgshell")

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

$OidTable = @()
$OidTable += New-OidObject "1.3.6.1.4.1.4329.15.3.5.1.2.1.17" Hardware
$OidTable += New-OidObject "1.3.6.1.4.1.4329.15.3.5.1.2.1.7"  Firmware
$OidTable += New-OidObject "1.3.6.1.4.1.4329.15.3.5.1.2.1.2"  Name
$OidTable += New-OidObject "1.3.6.1.4.1.4329.15.3.5.1.2.1.14" IpAddress

$OidTable += New-OidObject "1.3.6.1.4.1.4329.15.3.5.1.2.1.4"  Serial
$OidTable += New-OidObject "1.3.6.1.4.1.4329.15.3.5.1.2.1.22" State       # 1 = active, 2 = inactive

$OidTable += New-OidObject "1.3.6.1.4.1.4329.15.3.5.2.2.1.3"  InOctets
$OidTable += New-OidObject "1.3.6.1.4.1.4329.15.3.5.2.2.1.8"  OutOctets

$OidTable += New-OidObject "1.3.6.1.4.1.4329.15.3.5.2.2.1.11" Uptime      # in 1/100 of a second
$OidTable += New-OidObject "1.3.6.1.4.1.4329.15.3.5.2.2.1.15" SessionTime # with controller

$OidTable += New-OidObject "1.3.6.1.4.1.4329.15.3.5.2.2.1.16" 80211a
$OidTable += New-OidObject "1.3.6.1.4.1.4329.15.3.5.2.2.1.17" 80211b
$OidTable += New-OidObject "1.3.6.1.4.1.4329.15.3.5.2.2.1.18" 80211g
$OidTable += New-OidObject "1.3.6.1.4.1.4329.15.3.5.2.2.1.19" 80211n5
$OidTable += New-OidObject "1.3.6.1.4.1.4329.15.3.5.2.2.1.20" 80211n24

$OidTable += New-OidObject "1.3.6.1.4.1.4329.15.3.5.1.3.1.3"  RadioType $true
<#  0  off
    1  dot11a
    2  dot11an
    3  dot11anStrict
    4  dot11b
    5  dot11g
    6  dot11bg
    7  dot11gn
    8  dot11bgn
    9  dot11gnStrict
    10 dot11j         #>

$OidTable += New-OidObject "1.3.6.1.4.1.4329.15.3.1.1.7.1.2" ConfiguredChannel $true $true # 0 means auto

# NEED TO COME BACK AND CALCULATE FRIENDLY CHANNEL NUMBERS

$OidTable += New-OidObject "1.3.6.1.4.1.4329.15.3.1.1.7.1.6"  SelectedChannel   $true $true
$OidTable += New-OidObject "1.3.6.1.4.1.4329.15.3.1.1.7.1.9"  PowerLevel        $true $true
$OidTable += New-OidObject "1.3.6.1.4.1.4329.15.3.1.4.3.1.31" NoiseFloor        $true $true

$Oids = @{ifAdminStatus = "Admin Status" # .1.3.6.1.2.1.2.2.1.7
          ifOperStatus  = "Operational Status" # .1.3.6.1.2.1.2.2.1.8
          ifInOctets    = "Inbound Traffic" # .1.3.6.1.2.1.2.2.1.10
          ifOutOctets   = "Outbound Traffic" # .1.3.6.1.2.1.2.2.1.16
          ifInErrors    = "Inbound Errors" # .1.3.6.1.2.1.2.2.1.14
          ifOutErrors   = "Outbound Errors" # .1.3.6.1.2.1.2.2.1.20
          ifInDiscards  = "Inbound Discards" # .1.3.6.1.2.1.2.2.1.13
          ifOutDiscards = "Outbound Discards" # .1.3.6.1.2.1.2.2.1.19
          ifSpeed       = "Speed"} # .1.3.6.1.2.1.2.2.1.5


$Count     = $Oids.Count
$OidString = ""

foreach ($o in $Oids.GetEnumerator()) {
    $PortOid = $Port - 1
    if ($PortOid -eq 0) {
        $OidString += " IF-MIB::$($o.name)"
    } else {
        $OidString += " IF-MIB::$($o.name).$PortOid"
    }
}

$Command  = "snmpbulkget -Oq -r 3 -v $Version -c $Community -Cn$Count -Cr1 $Agent $OidString"
$Results  = iex $Command
$OidRx    = [regex] '::(\w+)\.\d+\ (.*)'
$Channels = ""
$Total    = 0

foreach ($r in $Results) {
    $Match   = $OidRx.Match($r)
    $Name    = $Match.groups[1].value
    $Value   = $Match.groups[2].value
    $Channel = $Oids.get_item($Name)

    switch ($Name) {
        {($_ -eq "ifOutOctets") -or ($_ -eq "ifInOctets")} {
            $Value     = [int64]$Value
            $Channels += Set-PrtgResult $Channel $Value BytesBandwidth -ss KiloBit -mo Difference -sc -dm Auto
            $Total    += $Value
        }
        {($_ -eq "ifOutDiscards") -or ($_ -eq "ifInDiscards") -or ($_ -eq "ifOutErrors") -or ($_ -eq "ifInErrors")} {
            $Channels += Set-PrtgResult $Channel $Value Count -mo Difference
        }
        ifOperStatus {
            if (($Value -eq "dormant") -or ($value -eq "up")) { $Value = 0 } `
                elseif ($Value -eq "down")                    { $Value = 1; $ErrorText = "Port is operationally down" } `
                elseif ($Value -eq "notPresent")              { $Value = 2; $ErrorText = "Port is no present" } `
                else                                          { $Value = 3; $ErrorText = "Port status is unknown" }
            $Channels += Set-PrtgResult $Channel $Value oper  -me 0
        }
        ifAdminStatus {
            if ($Value -eq "up") { $Value = 0 } `
                else             { $Value = 1; $ErrorText = "Port is administratively disabled" }
            $Channels += Set-PrtgResult $Channel $Value admin -me 0
        }
        ifSpeed {
            $Channels += Set-PrtgResult $Channel ($Value / 1000000)  Mb -MinWarn 1000000000
        }
        default { "Error" }
    }
}

$TotalChannel = Set-PrtgResult "Total Traffic" $Total BytesBandwidth -ss KiloBit -mo Difference -sc -dm Auto

$Elapsed = [math]::round(((Get-Date) - $Timer).TotalMilliSeconds,2)

$XmlOutput  = "<prtg>`n"
$XmlOutput += $TotalChannel
$XmlOutput += $Channels

if ($ErrorText) {
    $XmlOutput += "  <Text>$ErrorText</Text>`n"
    $XmlOutput += "  <Error>1</Error>`n"
}

$XmlOutput += "</prtg>"

$XmlOutput