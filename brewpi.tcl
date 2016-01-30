# IMPORTANT!!!!
# You MUST install the tcllib package on your linux machine
# On a Debian/Raspbian system, this is done by typing:
# sudo apt-get install tcllib

# Set this to where your web server is running from
# It is commonly /var/www/ or /var/www/html
set basePath "/var/www/html"

# Set this to the channel you wish to announce on
# Set to "%" if you wish to use on all channels
set brewchan "#mybeer"

# Set this to the flags of people allowed to use commands
# Setting to * will allow anyone to use
# Setting to n will allow only bot owners, etc
set brewflag "*"


###################################
### Do not edit below this line ###
### unless you know what you    ###
###        are doing!!          ###
###################################
package require json
set timeDict [dict create]

bind pub $brewflag "$brewchan !beertemp" beertemp
bind pub $brewflag "$brewchan !beername" beername
bind pub $brewflag "$brewchan !profile" profile
bind pub $brewflag "$brewchan !done" timeLeft
bind pub $brewflag "$brewchan !help" help
bind pub $brewflag "$brewchan !clearbinds" clearBinds
#bind cron * "58 * * * *" readCSV
bind pub $brewflag !foo readCSV

proc help {nick user hand chan text} {
    putserv "PRIVMSG $chan :Available commands: !beertemp, !beername, !profile, !done"
}

proc lastmodified {dir ext} {
    foreach _file [glob -directory $dir *.${ext}] { 
        set _mtime [file mtime $_file]
        if {![info exists mtime] || $_mtime > $mtime} {
            set mtime $_mtime
            set file $_file
        } 
    }
    return $file
}

proc getJSON {} {
    global basePath
    set f [open "${basePath}/userSettings.json" r]
    set jsonStr [::json::json2dict [read $f]]
    close $f
    return $jsonStr
}

proc getEndDate {jsonStr} {
    global basePath
    set f [open ${basePath}/data/profiles/[getBeerProfile $jsonStr].csv]
    while {[gets $f line] >=0} {
      set lastline $line
    }
    set endDate [clock scan [lindex [split $lastline ","] 0] -format %Y-%m-%dT%H:%M:%S]
    close $f
    return $endDate
}

proc getunits {jsonStr} {
    set unit [dict get $jsonStr "tempFormat"]
    return $unit
}

proc getBeerProfile {jsonStr} {
    set profileName [dict get $jsonStr "profileName"]
    return $profileName
}

proc getBeerName {jsonStr} {
    set beerName [dict get $jsonStr "beerName"]
    return $beerName
}

#proc readCSV {min hour day mon wkday} {
proc readCSV {nick user hand chan text} {
    global basePath
    global timebinds
    global timeDict

    clearBinds a b c d f
    set jsonStr [getJSON]
    set f [open ${basePath}/data/profiles/[getBeerProfile $jsonStr].csv]
    while {[gets $f line] >=0} {
      if {[catch {set timePoint [clock scan [lindex [split $line ","] 0] -format %Y-%m-%dT%H:%M:%S]}]} {
        continue
      }
      set tgtTemp [lindex [split $line ","] 1]
      set min [clock format $timePoint -format "%M"]
      set hour [clock format $timePoint -format "%H"]
      set day [clock format $timePoint -format "%d"]
      set mon [format %02d [expr [clock format $timePoint -format "%m"] - 1] ]
      set moo [bind time * "$min $hour $day $mon *" [list announceTime $chan]]
      lappend timebinds "time * \"$moo\" {announceTime $chan}"
      dict set timeDict "$min $hour $day $mon" $tgtTemp
    }
    close $f
}

proc getNextTime {timeval} {
    global timeDict

    set currVal [lsearch [dict keys $timeDict] $timeval]
    return [dict get $timeDict [lindex [dict keys $timeDict] [expr $currVal + 1]]]
}

proc announceTime {chan min hour day month year} {
    global timeDict
    set timeval "$min $hour $day $month"
    putserv "PRIVMSG $chan :Reached set point of [dict get $timeDict "$min $hour $day $month"]. Beginning transition to [getNextTime $timeval]"
}

proc beername {nick user hand chan text} {
    set jsonStr [getJSON]
    set beerName [getBeerName $jsonStr]
    putserv "PRIVMSG $chan :The current beer being brewed is $beerName"
}

proc clearBinds {nick user hand chan text} {
    global timebinds
    global timeDict
    if {[info exists timebinds]} {
      foreach tbind $timebinds {
        unbind {*}$tbind
      }
      unset timebinds
      unset timeDict
    }
    putserv "PRIVMSG $chan :Binds cleared"
}

proc beertemp {nick user hand chan text} {
    global basePath
    set jsonStr [getJSON]
    set currentFile [lastmodified ${basePath}/data/[getBeerName $jsonStr] "csv"]
    set f [open $currentFile r]
    seek $f -100 end
    while {[gets $f line] >=0} {
      set lastline $line
    }
    set beerTemp [lindex [split $lastline ";"] 1]
    close $f
    putserv "PRIVMSG $chan :The current beer temperature is ${beerTemp}[getunits $jsonStr]"
}

proc profile {nick user hand chan text} {
    set jsonStr [getJSON]
    set profileName [getBeerProfile $jsonStr]
    putserv "PRIVMSG $chan :The current beer profile being followed is $profileName"
}

proc timeLeft {nick user hand chan text} {
    set jsonStr [getJSON]
    set endDate [getEndDate $jsonStr]
    set startDate [clock seconds]
    set diff [expr {$endDate - $startDate}]
    putserv "PRIVMSG $chan :Time remaining on this brew of [getBeerName $jsonStr]: [clock format $diff -gmt 1 -format "%d days, %H hours, %M minutes, %S seconds"]"
}
