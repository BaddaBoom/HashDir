# HashDir
Hashes a directory (bad) and then compares it with an identical instance (good)


### **About**
This will certainly come in handy when, say, you have a corrupted system file but you dont want to go through the trouble of manuall tracking it down. Originally designed to use the C:\Windows directory (since that should almost never change), it can run in any directory. Obviously you need similar files in both test subjects but if there is a missing file (or extra files) then it will be noted as such in the output files. Uses SHA-512 (but you can override in the globals) to hash the files.

A brief history for the reason this exists at all, there was an application that was installed onto a users machine, and after it failed, the machine crashed. It couldnt come back online outside of safe mode either. In lieu of just wiping it (not an option apparently) I built and ran this script against his Windows dir vs my Windows dir. And, lo and behold, his AHCI driver was fubar. So I swapped it with mine. Boom, no more problems.

### **Usage**
hashdir.ps1 \[-compare \<prev run\>\] -WindowsDir \<path to dir\>

The **\<path to dir\>** is the _absolute_ path to the directory to hash. This will also iterate through the sub directories and generate hashes for all files.

If **-compare** is set, then the **\<prev run\>** will be the path to the file that was just run. This indicate the script should not just hash the files, but compare the hashes to it counterpart from the previous run.

**NOTE**: you must also supply the flags in the case-sensitive way listed above.

This will return either a) a file of names and hashes or b) a file of discrepencies between what was found and wht was compared against (if any exist).


-@BaddaBoom