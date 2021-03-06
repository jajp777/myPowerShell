# gotcha 2: current location vs current directory

#prep: go to the file system home folder
cd $home;ls foo*,bar* | remove-item;ls ./documents/foo* | remove-item;ls ./documents/bar* | remove-item
cls

<#
    PowerShell maintains a notion of your current location.
    
    this is obvious from the default prompt - it follows you as you move around
    the shell
#>

cd documents
# note the change in the prompt
cd ..
# note the change in the prompt again

# in fact PowerShell has cmdlets to get the current location
get-location
# and there's the $pwd automatic variable which does the same thing
$pwd
"$pwd/documents"

# and you can change this location as well:
set-location ./documents

<#
    PowerShell uses this location to resolve relative paths in PowerShell cmdlets.
    
    For instance:
#>

ls pluralsight

<# 
    powershell knows that this path to c:\users\beefarino\documents\pluralsight because my 
    current location is c:\users\beefarino\documents       
#>

cls

<#
    so it should come as no surprise that when I run this command:
#>
new-item -path foo-from-powershell.txt -type file -value 'hello!'

<#
    ... a new file is created in my current location
#>
ls foo*

<#
    now, let's to something similar; instead of using the powershell cmdlet, let's use
    the .net framework directly to create a file:
#>
[io.file]::writeAllText( "foo-from-dotnet.txt","hello again!" )

<#
    ... and see the file that was created:
#>
ls foo*

<# 
    so... where's the file?  we didn't get an error, so the file must exist right?
    where did it go?


    While PowerShell maintains your current LOCATION, the process is also maintaining 
    your current DIRECTORY.  


    LOCATION is used to resolve paths by powershell cmdlets (like new-item)
    DIRECTORY is used to resolve paths in the BCL, windows API, etc

    slide deck: what happened in new-item vs [io.file]::writeAllBytes

    You can see this by checking the value of [environment]::currentDirectory.    
#>
[environment]::currentDirectory
[environment]::currentDirectory | ls

<#
    current directory and current location CAN be identical, but you can't count on it.  
    In fact, unless you take specific action to change it, the current directory never 
    actually changes in PowerShell  
#>
cd ~
get-location
[environment]::CurrentDirectory

# they are identical here

cd documents
$pwd
[environment]::CurrentDirectory

# but now they're different
    
<#
    Moreover, your LOCATION may not even
    be a file system path; it isn't possible for the current DIRECTORY to be 
    anyplace outside of the file system
#>
cd cert:
# now the current LOCATION is the certificate store
$pwd
[environment]::CurrentDirectory

cd c:
cls

<#
    so what can we do about this?

    there is a fairly simple way to make the current DIRECTORY match the current filesystem LOCATION

    every time powershell needs to write the prompt, it calls a magic function named prompt to 
    retrieve the prompt string.  In fact, you can call this function at whim
#>
prompt
# see the prompt

<#
    you can put any logic you want into this function.  since this gets called after every powershell
    command is executed, it's a great place to cram something like this:
#>
cls
#@
function prompt {
    $curdir = get-location -PSProvider fileSystem | select-object -expand Path;
    [environment]::CurrentDirectory = $curdir
    "PS $pwd> "
}
#@

<#
    once we've added this logic to our prompt, our current directory follows the current location of 
    the filesystem provider
#>

cd ~
$pwd
[environment]::CurrentDirectory
cd ~/documents
$pwd
[environment]::CurrentDirectory

<#
    now any APIs and command-line utilities will output files in the expected place
#>

[io.file]::writeAllText( "bar-from-dotnet.txt","hello again!" )
ls bar*