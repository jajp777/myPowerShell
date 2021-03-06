# prep:
<#
function obliterate-computer{ 
    sleep -second 1.4
    write-host -fore green  @'

                                   /\\|//'
                                    (O X)    
     ---------------------------ooO--(_)--Ooo----------------------------
   
'@
    write-host  @'

      @@@@@@@@   @@@@@@    @@@@@@   @@@@@@@   @@@@@@@   @@@ @@@  @@@@@@@@  
     @@@@@@@@@  @@@@@@@@  @@@@@@@@  @@@@@@@@  @@@@@@@@  @@@ @@@  @@@@@@@@  
     !@@        @@!  @@@  @@!  @@@  @@!  @@@  @@!  @@@  @@! !@@  @@!       
     !@!        !@!  @!@  !@!  @!@  !@!  @!@  !@   @!@  !@! @!!  !@!       
     !@! @!@!@  @!@  !@!  @!@  !@!  @!@  !@!  @!@!@!@    !@!@!   @!!!:!    
     !!! !!@!!  !@!  !!!  !@!  !!!  !@!  !!!  !!!@!!!!    @!!!   !!!!!:    
     :!!   !!:  !!:  !!!  !!:  !!!  !!:  !!!  !!:  !!!    !!:    !!:       
     :!:   !::  :!:  !:!  :!:  !:!  :!:  !:!  :!:  !:!    :!:    :!:       
      ::: ::::  ::::: ::  ::::: ::   :::: ::   :: ::::     ::     :: ::::  
      :: :: :    : :  :    : :  :   :: :  :   :: : ::      :     : :: ::   
                                                                           
'@ -fore darkred

    write-host -fore green  @'
       
     ---------------------------ooO-------Ooo----------------------------

'@
sleep -second 4
}
#>
# demo starts here #

# powershell understands basic expressions
5-3
'hello' + ' world!'


<# 
    and as discussed in the intro to this module, powershell lets you 
    combine expressions and commands into pipelines
#>

'this is some data' | out-file ./data.txt

<#
    In this case the expression result provides input to the out-file
    cmdlet, which writes its input to the file data.txt
#>
get-content ./data.txt

<#
    If we look at the help for out-file, we can see that this input
    is actually just another cmdlet parameter named InputObject
#>
get-help out-file -param *

<#
-InputObject <psobject>
    Specifies the objects to be written to the file. Enter a variable that contains the o
    bjects or type a command or expression that gets the objects.

    Required?                    false
    Position?                    named
    Default value
    Accept pipeline input?       true (ByValue)
    Accept wildcard characters?  false
    
    The help for InputObject is marked as accepting pipeline input, which means we 
    can rewrite our previous example like so:
#>
cls

out-file ./data.txt -inputobject 'this is some other data'
get-content ./data.txt

#note the content of the file is updated

<#
    so it should come as no surprise that if we use an expression to provide 
    input to out-file, the data file will contain the results of our expression
#>
1+1 | out-file ./data.txt
get-content ./data.txt

# the file contains the value 2

<#
    and it should follow that we can reorganize our pipeline input into the 
    argument for out-file:
#>
out-file ./data.txt -inputobject 1+1
get-content ./data.txt

# wait - the file contains the expression iteself, 1+1... what gives?

<#
    this is an order-of-operations thing...
    
    in the first case, our pipeline consists of two segments: 1+1 which is set to pipe to out-file.
    when this case executes, the 1+1 is resolved first since it represents a complete pipeline segment
    and it's output is requried as input before the out-file cmdlet can be executed.  Here, '1 + 1' is 
    viewed to be an expression since it's a complete statement
    
    in the second case, the out-file cmdlet is the only segment in the pipeline.  when this executes,
    powershell doesn't notice the '1 + 1' until it's parsing parameter values for the cmdlet.  by that point,
    it isn't looking for expressions to evaluate, it's looking for objects or values.  so rather than resolve
    '1 + 1' as an expression, PowerShell "helps you out" by interpreting '1 + 1' as a string.
#>
cls

<#
    this may seem odd, but it makes a lot of sense.  
    
    consider this example:
#>
out-file ./neverExecuteTheseCommands.txt -inputobject obliterate-computer

<#
    Assume that I've got an obliterate-computer cmdlet that I can use to ... well, obliterate the 
    contents of my computer.
    
    I obviously don't want to EXECUTE the obliterate-comptuer cmdlet in this case, I'm just
    making a note of it in a file.  NOT interpreting parameters as expressions is the safest 
    option for powershell to use.
#>

<#
    So what do you do when you need PowerShell to evaluate a parameter?  Easy - just enclose it in parentheses ()
#>

out-file ./data.txt -inputobject (1+1)
get-content ./data.txt

<#
    this forces PowerShell to look at the '1+1' FIRST, evaluating it as an expression before 
    even considering the outer context of the out-file cmdlet.       
#>

# The parens than contain any arbitrarily complex powershell statement, including cmds and pipelines
out-file ./neverExecuteTheseCommands.txt -inputobject (obliterate-computer)