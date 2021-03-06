#requires -version 3.0

<#
 Use a multiline comment like this to explain what this script
 does.
#>

Param (
[string]$Path=".",
[datetime]$Cutoff
)

#the path might be a . or a PSDrive shortcut so get the complete path
$Folder = Get-Item -Path $path

#Display a status message. 
Write-Host "Getting file data from $Folder" -ForegroundColor Green

#if $cutoff is specified, find the files last modified since the cutoff date.
if ($Cutoff) {
    Write-Host "Getting files modified since $Cutoff" -ForegroundColor Green
    $data = Get-ChildItem -Path $path -Recurse -File | 
    Where {$_.LastWriteTime -ge $Cutoff}
}
else {
    $data = Get-ChildItem -Path $path -Recurse -File
}

#measure the files
$stats = $data | Measure-Object -Property length -sum -Minimum -Average -Maximum

#write the result to the pipeline
$stats | Select-Object -Property @{Name="Folder";Expression={$Folder}},Count,Minimum,Maximum,Average,Sum

#end of script
