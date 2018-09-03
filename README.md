# cleanlogs

## Description

Tool to remove old files on directory following some rules.  
rules are common file specifications (with * and ?) and age values based on Access, Create and Modified file timestamp.  

## Settings

cleanlogs use an ini file to get rules

### section :default

Set "default" values for other entries

### section :override

Set "override" values for other entries after default and specific values are set.

### section DIRECTORY

Set "specific" values for a specific place (local directory or share on UNC format)

### parameters

**criteres=Criteria_List**

French term for "Criteria".  
Format : [(Acces|Modify|Create)]+value[Day|Week|Month|Year][filespec [,filespec]...]  
Sample : criteres=(c)+3d[*.log;*.trc] (m)+3w[PY*.tmp]  

**tracefile=Name_Of_Logfile**  

Name of the logfile.  
Could contain dynamic value with %keyword% format :  

    now - current timestamp (Date + Time)  
    date - current date  
    time - current time  
    dayofyear - current day of year  
    day - current day  
    month - current month  
    year - current year  

**option=value,value**  

List of values in :  

    recursif - process subdirectories (opposite of *plat*)  
    execute - do the process (opposite of *simulation*)  
    force - do not confirm deletion (opposite of *confirmation*)  
    plat - process only directory level (opposite of *recursif*)  
    simulation - do not process files (opposite of *execute*)  
    confirmation - confirm deletion (opposite of *force*)  

## Notes  

It's a good uses to put a section to clean logfiles.  
As you can name tracefile whit whatever you want, each run of *cleanlogs* will create a log file o reuse it.   
if your ini files looks like to :  

    [:default]  
    tracefile=E:\Exploit\trace\CleanLogs-%year%%dayofyear%.log  
    options=recursif,execute,force  

    [:override]  
    ;options=simulation,confirmation  

    [E:\Exploit\Oracle\LOG]  
    criteres=(m)+8d[*.*]  

It could be interesting to put also a section with :  

    [e:\Exploit\trace]  
    criteres=(m)+5d[*.log]  

to clean old logfiles too  

In the :override section, I always put a commented option with **simulation,confirmation**  
when you design your rules file, you can un-comment this line and no deletion will be done and for every file selected a confirmation message will be displayed. It's a good rule to follow because cleanlogs could be very risky if you don't test it before running in real conditions.
