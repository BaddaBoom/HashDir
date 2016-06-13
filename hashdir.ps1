# 
# HashDir
#
#  This script will hash all the files in a directory and then
#  compare it with a similar directory from another machine.
#  Useful for finding if files have been modified when they
#  shouldn't have been.
#
#
#  Copyright 2015 @BaddaBoom
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

# cli args
Param ([string]$compare = "", [string]$WindowsDir, [switch]$h, [switch]$help)

# some globals
$G_HASH = "SHA512"
$G_SPLITON = "|||"
$G_FILEND1 = "_hashcheck.txt"
$G_FILEND2 = "_discrepencies.txt"

Function usage {
    Write-Host 'USAGE:' $MyInvocation.ScriptName ' [{-h|-help}|-compare <hashfile.txt>] -WindowsDir <windows directory>'
    Write-Host "`t-h or -help`t`tshow this help prompt"
    Write-Host "`t<hashfile.txt>`t`tOptional. A previous run of this script for comparison"
    Write-Host "`t<windows directory>`tthe windows directory you want to hash (absolute path).`n`n"
    Exit
}

# header
Write-Host "`n`nGREETINGZ EARTHLING!"
Write-Host "Use this script to determine what has happened to your directory."
Write-Host '(C) 2015 BaddaBoom'"`n"

If($h -Or $help -Or $MyInvocation.BoundParameters.Count -lt 1) {
    # show usage
    usage
}

# test required vars
If($WindowsDir -eq $null) {
    Write-Host '[!] ERROR: no -WindowsDir path set.'"`n"
    usage
}
If(-Not(Test-Path $WindowsDir)) {
    Write-Host '[!] ERROR: -WindowsDir path does not exist.'"`n"
    usage
}
# test optional arg
If($compare -ne "") {
    $compare = Resolve-Path $compare
    If(-Not(Test-Path $compare)) {
        Write-Host '[!] NOTICE: -compare was set to an invalid file. Continuing on as first run.'
        $compare = ""
    }
}
    

# lets go!
$orig = Get-Location

if($WindowsDir[-1] -ne "\") {
    $WindowsDir += "\"
}

# set pwd to the windows directory
Set-Location -Path $WindowsDir

$sdate = Get-Date
$datestr = ($sdate.Month -as [string]) + '/' + ($sdate.Day -as [string]) + '/' + ($sdate.Year -as [string]) + ' ' + ($sdate.Hour -as [string]) + ':' + ($sdate.Minute -as [string]) + ':' + ($sdate.Second -as [string])
Write-Host '[+] Starting at' $datestr
Write-Host '[+] Using' ($WindowsDir -as [string]) 'as the target directory'

#
# file supplied
#
If($compare -ne "") {
    Write-Host '[+] Reading Content in from file' $compare
	try {
		$filecontents = Get-Content $compare -ErrorAction Stop
	}
	Catch {
		Write-Host '[!] ERROR: could not process file.'
		Break
	}
	Finally {
		# split lines into array
		$prevrun = @{}
		$prevcount = 0
		$filecontents | foreach {
			$pn,$ph = $_.split($G_SPLITON,[System.StringSplitOptions]::RemoveEmptyEntries)
			$prevrun.Add($pn, $ph)
			$prevcount++
		}
		Write-Host '[+] Will compare against' ($prevcount -as [string]) 'file hashes'

		# now create new hashes and compare
		$dt = Get-Date
		$outfile = ($orig -as [string]) + '\' + ($dt.Year -as [string]) + ($dt.Month -as [string]) + ($dt.Day -as [string]) + ($dt.Hour -as [string]) + ($dt.Minute -as [string]) + ($dt.Second -as [string]) + $G_FILEND2
		$counter = 0
		$badcount = 0
		Get-ChildItem -File -Recurse -Filter *.* -ErrorAction SilentlyContinue | ForEach-Object {
			$name = $_.FullName.Substring($WindowsDir.Length)
            try {
			    $hash = Get-FileHash -Algorithm $G_HASH $name -ErrorAction SilentlyContinue
            }
            catch {
                Continue
            }
			# found in previous run
            If($name.Length -gt 2 -And $hash.Hash.length -gt 8) {
		        If($prevrun.ContainsKey($name)) {
			        # hash was different. UH OH.
			        If ($prevrun[$name] -notmatch $hash.Hash) {
				        $msg = "Incorrect Hash: " + ($name -as [string]) + " (" + ($hash.Hash -as [string]) + ")"
				        $msg | Add-Content $outfile
				        $badcount++
			        }
		        }
		        # not found (a new file?) so log it
		        Else {
                    if ($name.FullName -ne $compare.FullName) {
                        $msg = "File not found for comparison: " + ($name -as [string])
                        $msg | Add-Content $outfile
                        $badcount++
                    }
		        }
		        $counter++
            }
            Write-Progress -Activity 'Hashing: ' $name
		}
		$finalcount = ($counter -as [string])
		$finalbad = ($badcount -as [string])
		Write-Host '[+] Hashed' $finalcount 'files and found' $finalbad 'errors (look in' $outfile')'
	}
}
#
# no file. first run
#
Else {
	# create timestamp file
	$dt = Get-Date
	$outfile = ($orig -as [string]) + '\' + ($dt.Year -as [string]) + ($dt.Month -as [string]) + ($dt.Day -as [string]) + ($dt.Hour -as [string]) + ($dt.Minute -as [string]) + ($dt.Second -as [string]) + $G_FILEND1
	Write-Host '[+] Creating hashes file' $outfile

	$counter = 0
	Get-ChildItem -File -Recurse -Filter *.* -ErrorAction SilentlyContinue | ForEach-Object {
		$name = $_.FullName.Substring($WindowsDir.Length)
		try {
			$hash = Get-FileHash -Algorithm $G_HASH $name -ErrorAction SilentlyContinue 
			$msg = ($name -as [string]) + $G_SPLITON + ($hash.Hash -as [string])
		}
		catch {
            Continue
		}
        If($name.Length -gt 2 -And $hash.Hash.length -gt 8) {
		    $msg | Add-Content $outfile
		    $counter++
        }
        Write-Progress -Activity 'Hashing: ' $name
	}
	$finalcount = ($counter -as [string])
	Write-Host '[+] Hashed' $finalcount 'files'
}

$fdate = Get-Date
$datestr = ($fdate.Month -as [string]) + '/' + ($fdate.Day -as [string]) + '/' + ($fdate.Year -as [string]) + ' ' + ($fdate.Hour -as [string]) + ':' + ($fdate.Minute -as [string]) + ':' + ($fdate.Second -as [string])
Write-Host '[+] Finished at' $datestr
Write-Host "`n`n"

# revert to where we were
Set-Location -Path $orig