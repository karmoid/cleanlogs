# cleanlogs

## Description

Tool to remove old files on directory following some rules.
rules are common file specifications (with * and ?) and age values based on Acces, Create and Modified file timestamp.

Format : [(Acces|Modify|Create)]+value[Day|Week|Month|Year][filespec [,filespec]...]
Sample : criteres=(c)+3d[*.log;*.trc] (m)+3w[PY*.tmp]

## Settings

cleanlogs use an ini file to get rules

### section :default

Set "default" values for other entries

### section :override

Set "override" values for other entries after default and specific values are set.

### section DIRECTORY

set "specific" values for a specific place (local directory or share on UNC format)

### parameters

criteres
tracefile
option
