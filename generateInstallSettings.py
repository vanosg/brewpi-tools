#!/usr/bin/python
import sys
import git

changed = False
scriptPath = "/home/brewpi"
webPath = "/var/www"

try:
    if not os.path.isdir("/etc/brewpi"):
        os.makedirs("/etc/brewpi")
except OSError:
    print "Unable to read /etc/brewpi. Aborting"
    sys.exit(1)

### Set scriptPath
for i in range(3):
    correctRepo = False
    try:
        scriptRepo = git.Repo(scriptPath)
        gitConfig = open(scriptPath + '/.git/config', 'r')
        for line in gitConfig:
            if "url =" in line and "brewpi-script" in line:
                correctRepo = True
                break
        gitConfig.close()
    except git.NoSuchPathError:
        print "The path '%s' does not exist" % scriptPath
        scriptPath = raw_input("What path did you install the BrewPi python scripts to?")
        continue
    except (git.InvalidGitRepositoryError, IOError):
        print "The path '%s' does not seem to be a valid git repository" % scriptPath
        scriptPath = raw_input("What path did you install the BrewPi python scripts to?")
        continue

    if not correctRepo:
        print "The path '%s' does not seem to be the BrewPi python script git repository" % scriptPath
        scriptPath = raw_input("What path did you install the BrewPi python scripts to?")
        continue
    break
else:
    print "Maximum number of tries reached, updating BrewPi settings aborted"
    sys.exit(1)

with open(scriptPath+"/settings/.installSettings", "w") as f:
    f.write("scriptPath="+scriptPath+"\n")

### Set webPath
    for i in range(3):
        correctRepo = False
        try:
            webRepo = git.Repo(webPath)
            gitConfig = open(webPath + '/.git/config', 'r')
            for line in gitConfig:
                if "url =" in line and "brewpi-www" in line:
                    correctRepo = True
                    break
            gitConfig.close()
        except git.NoSuchPathError:
            print "The path '%s' does not exist" % webPath
            webPath = raw_input("What path did you install the BrewPi web interface scripts to? ")
            continue
        except (git.InvalidGitRepositoryError, IOError):
            print "The path '%s' does not seem to be a valid git repository" % webPath
            webPath = raw_input("What path did you install the BrewPi web interface scripts to? ")
            continue
        if not correctRepo:
            print "The path '%s' does not seem to be the BrewPi web interface git repository" % webPath
            webPath = raw_input("What path did you install the BrewPi web interface scripts to? ")
            continue
        break
    else:
        print "Maximum number of tries reached, updating BrewPi settings aborted"
        sys.exit(1)
    f.write("webPath="+webPath+"\n"

### Set logging paths
    f.write("stdoutLogging="+$scriptPath+"/logs/stdout.txt\n"
    f.write("stderrLogging="+$scriptPath+"/logs/stderr.txt\n"

