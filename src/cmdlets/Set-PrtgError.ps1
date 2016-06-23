
function Set-PrtgError {
  Param (
    [Parameter(Mandatory=$True,Position=0)]
    [string]$ErrorText
  )

  PROCESS {
    $XmlObject = New-Object PrtgShell.ExeXml
    return $XmlObject.PrintError($ErrorText)
  }
}