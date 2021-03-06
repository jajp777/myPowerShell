#requires -version 3.0

<#
.Synopsis
Create a system report
.Description
Use WMI to gather system information and prepare a report. The default behavior is to simply write objects to the pipeline, but you can format the results as a plain text report using -Text, or an HTML report using -HTML.
.Parameter Computername
The name of the computer to query. The default is the local host.
.Parameter ReportTitle
The name to use for the report title.
.Parameter HTML
Write an HTML "report" to the pipeline. You can pipe to Out-File 
to save it.
.Parameter TEXT
Create a formatted text report which you can pipe to a file.
.Example
PS C:\> c:\scripts\New-SystemReport.ps1
.Example
PS C:\> get-content computers.txt | c:\scripts\new-systemreport.ps1 | out-file report.txt
.Example
PS C:\> get-content computers.txt | c:\scripts\new-systemreport.ps1 -html | out-file \\web01\report$\allservers.htm
.Example
PS C:\> get-content computers.txt | foreach { 
$comp=$_
c:\scripts\new-systemreport.ps1 -computername $comp -html | out-file "\\web01\report$\$comp.htm"
.Example
PS C:\> c:\scripts\new-systemreport.ps1 -comp "server01","server02","server03" -Text
}
#>

[cmdletbinding(DefaultParameterSetName="object")]

Param (
[Parameter(Position=0,ValueFromPipeline=$True)]
[ValidateNotNullOrEmpty()]
[string[]]$computername=$env:computername,
[ValidateNotNullOrEmpty()]
[string]$ReportTitle="System Inventory Report",
[Parameter(ParameterSetName="HTML")]
[switch]$HTML,
[Parameter(ParameterSetName="TEXT")]
[switch]$Text
)

Begin {
    Function NewChart {
        Param(
            [string]$Path="$env:temp\diskchart.png",
            [object]$Data,
            [string]$Legend,
            [string]$LegendText= "My Data",
            [string]$Title,
            [string]$SeriesName= "My Series",
            [switch]$Label,
            [int]$Width = 600,
            [int]$Height = 400,
            [ValidateSet("TopLeft","TopCenter","TopRight",
                        "MiddleLeft","MiddleCenter","MiddleRight",
                        "BottomLeft","BottomCenter","BottomRight")]
            [String]$Alignment = "TopCenter"
            )
            
            [void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms.DataVisualization")
             
            #Create the chart object
            $Chart = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
            $Chart.Width = $Width
            $Chart.Height = $Height
            
            #Create the chart area and set it to be 2D
            $ChartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
            $ChartArea.Area3DStyle.Enable3D = $False
            $Chart.ChartAreas.Add($ChartArea) 
            
            #Set the title and alignment
            if ($Title) {
                [void]$Chart.Titles.Add("$Title")
                $Chart.Titles[0].Alignment = $Alignment
                $Chart.Titles[0].Font = "Verdana,16pt"
            }
            $SeriesName = $SeriesName
            $Chart.Series.Add($SeriesName) | Out-Null
            $Chart.Series[$SeriesName].ChartType = "bar"
            if ($legend) {
                #add a legend
                $chart.Legends.Add($Legend) | Out-Null
                $chart.Series[$SeriesName].IsVisibleInLegend = $True
                $chart.Series[$SeriesName].LegendText = $LegendText
            }
            
            $Data | ForEach-Object {
                
                # Create the data series and add bar chart
                $point = $Chart.Series[$SeriesName].Points.AddXY($_.drive,$_.percentfree)
                #adjust color
                if (($_.percentFree -as [int]) -le 12) {
                    $chart.Series[$SeriesName].points[$point].Color = "red"
                }
                elseif ( ($_.percentFree -as [int]) -le 40 ) {
                    $chart.Series[$SeriesName].points[$point].Color = "yellow"
                }
                else {
                   $chart.Series[$SeriesName].points[$point].Color = "green"
                }
                #add a label
                if ($label) {
                    $chart.Series[$SeriesName].points[$point].Label = "{0:P2}" -f ($_.freeGB/$_.sizeGB)
                    $chart.Series[$SeriesName].AxisLabel = $_.drive
                }
            
            } | Out-Null
            
            #Save the chart to a png file
            $Chart.SaveImage($Path,"png")
            Get-Item $path
            
    }
Function Get-CSInfo {
  
  [cmdletbinding()]
  
  param(
  [Parameter(Position=0,ValueFromPipeline=$True)]
  [ValidateNotNullOrEmpty()]
  [string[]]$computername=$env:computername
  )
  
  Process {
      ForEach ($computer in $Computername) {
        Write-Verbose "Querying $computer for system information"
        
        Try {
          $os = Get-WmiObject -Class Win32_OperatingSystem `
          -Property "__SERVER","Version","BuildNumber","ServicePackMajorVersion" `
          -ComputerName $computer -erroraction "Stop"
          $cs = Get-WmiObject -Class Win32_ComputerSystem `
          -Property "__SERVER","TotalPhysicalMemory","NumberOfProcessors",
          "NumberOfLogicalProcessors" `
          -ComputerName $computer -erroraction "Stop"
          $bios = Get-WmiObject -Class Win32_BIOS `
           -Property "__SERVER","SerialNumber" `
          -ComputerName $computer -errorAction "Stop"
        }
        Catch {
            $msg=("There was an error getting system information from {0}. {1}" -f $computer, $_.Exception.Message)
            Write-Warning $msg
        }
            
          $props = [ordered]@{
                "ComputerName"=$os.__SERVER
                 "OS Version"=$os.version
                 "OS Build"=$os.buildnumber
                 "Service Pack"=$os.servicepackmajorversion
                 "MemoryGB"= $cs.totalphysicalmemory/1GB -as [int]
                 "CPUs"=$cs.numberofprocessors
                 "LogicalCPUs" = $cs.NumberOfLogicalProcessors
                 "BIOS Serial"=$bios.serialnumber
                 }
                 
          $obj = New-Object -TypeName PSObject -Property $props
          Write-Output $obj
    
    } #foreach
} #Process 
} #function

#define variables used later in the script.
#this must be left justified        
$head = @'
<title>System Report</title>
<style>
body { background-color:#FFFFFF;
       font-family:Tahoma;
       font-size:12pt; }
td, th { border:1px solid black; 
         border-collapse:collapse; }
th { color:white;
     background-color:black; }
table, tr, td, th { padding: 2px; margin: 0px }
tr:nth-child(odd) {background-color: lightgray}
table { margin-left:50px; }
</style>
'@

#initialize some arrays
$fragments=@()
$textreport=@()

}

Process {
ForEach ($computer in $Computername) {
    Write-Verbose "Creating a report for $computer"
    $csinfo = Get-CSInfo -computername $computer
    
    #if Get-CSinfo worked, then get disk information
    if ($csinfo) {
        Write-Verbose "Getting disk information from $computer"
        $data = Get-WmiObject -Class Win32_LogicalDisk -Filter 'DriveType=3' -ComputerName $computer 

        $drives = foreach ($item in $data) {
            $prophash = [ordered]@{
            Drive = $item.DeviceID
            Volume = $item.VolumeName
            Compressed = $item.Compressed
            SizeGB = $item.size/1GB -as [int]
            FreeGB = "{0:N4}" -f ($item.Freespace/1GB)
            PercentFree = ($item.Freespace/$item.size) * 100
            }
            New-Object PSObject -Property $prophash
        } #foreach item
    
    #add as much other reporting code as you'd like foreach computer
    } #if $csinfo

    #did we get CSInfo and $drives?
    If ($CSInfo -AND $drives) {    
        #take action depending on what Parameter set was used
        Switch ($pscmdlet.parameterSetName) {
        "HTML" {
            Write-Verbose "Creating HTML code"

            #create bar chart for disk space
            Write-Verbose "Creating chart"
            
            $Chartfile = NewChart -Data ($Drives | sort Drive -Descending)
            Write-Verbose $chartfile.fullname
            Write-verbose "Encoding image"
            $ImageBits = [Convert]::ToBase64String((Get-Content $($Chartfile.fullname) -Encoding Byte))
            $ImageHTML = "<img src=data:image/png;base64,$($ImageBits) alt='disk utilization' style='left 50px'/>"
            $fragments+= $csinfo | ConvertTo-Html -As LIST -Fragment -PreContent "<h2>$($csinfo.Computername) Computer Info</h2>" | Out-String
            $fragments+= $drives | ConvertTo-Html -Fragment -PreContent "<h2>$($csinfo.computername) Disk Info</h2>" | Out-String
            $fragments+= "$ImageHTML <br>"
       
        } #html
        "TEXT" {
           Write-Verbose "Creating formatted text report"
           $textreport+=$csInfo.Computername
           $textreport+="  System Information"
           $textreport+="`r"
           #Trim empty spaces and add each line as an indented string
           ($csinfo | out-string).Trim().Split("`n") | foreach {
             $textreport+="  $_"
           }
           $textreport+="`r"
           $textreport+="  Drive Information"
           $textreport+="`r"
           ($drives | format-table -autosize | out-String).Trim().Split("`n") | 
           foreach {
            $textreport+= "  $_"
           }
           $textreport+="`n"
        } #text
        
        Default {
         Write-Verbose "Writing default object output"
         Write $csinfo
         write $drives
        } #default
        } #switch

   } #if $csinfo and $drives
   else {
    Write-Host "Skipping report for $computer since not everything could be retrieved" -ForegroundColor Red
   }
} #foreach

} #process

End {
#Write the finished report
    If ($HTML) {
        $fragments+="<I>Report run $(Get-Date)</I>"
        ConvertTo-HTML -head $head -title $reportTitle -PreContent "<h1>System Inventory Report</h1>" -PostContent $fragments
    }
    
    if ($Text) {
        write $ReportTitle
        write ("-"*($reportTitle.Length))
        write "`r"
        Write $textReport
        write "Report run $(Get-Date)"
    }
    
  Write-Verbose "Finished Creating Report"
} #end

