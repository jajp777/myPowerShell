#requires -version 4.0

Configuration CoreDSC {

[Parameter(Position=0,Mandatory)]
[ValidateNotNullorEmpty()]

Node $Computername {

    WindowsFeature Backup {
        Name = "Windows-Server-Backup"
    Service RemoteRegistry {
        Name="RemoteRegistry"
        StartUpType="Automatic"
    Environment Office {
        Value="Chicago"
        Ensure="present"
    }

        Type = "Directory"
        DestinationPath = "C:\Work"
    } 

        Type = "Directory"
        Ensure = "Present"


        Type = "Directory"
        Ensure = "Present"
        DestinationPath = "C:\Reports"
} #node


<#

    verify configuration is ready   

   Make sure you are in the right directory or specify OutputPath

