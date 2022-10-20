# Duplicati Manual Setup Instructions

## Email Headers

```
Subject: Duplicati Setup on Mac
From: Aaron Sterr (home) <asterr@pobox.com>
Date: Thu, 28 Sep 2017 08:43:26 +0900
```

---
## Install Duplicati

  * Download Package and install:
    * duplicati-2.0.2.1_beta_2017-08-01.dmg

See: https://github.com/duplicati/duplicati/releases


---
## Run Duplicati as a Service


  * Create the net.duplicati.plist under LaunchAgents

```
    cd ~
    $ cat ~/Library/LaunchAgents/net.duplicati.plist
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>Label</key>
        <string>net.duplicati</string>
        <key>ProgramArguments</key>
        <array>
            <string>/Applications/Duplicati.app/Contents/MacOS/duplicati-server</string>
            <string>--webservice-port=8200</string>
            <string>--log-file=/Users/asterr/Library/Logs/duplicati.log</string>
            <string></string>
            <string>&amp;</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
    </dict>
    </plist>
```

  * Load net.duplicati.plist

```
    launchctl load -w ~/Library/LaunchAgents/net.duplicati.plist
```

---
## Mount Disks

  * Create mount-duplicati001.sh and mount-duplicati002.sh scripts

```
    vi ~/Library/Scripts/mount-duplicati001.sh
    vi ~/Library/Scripts/mount-duplicati002.sh
```

See: files/ for the scripts.


Note:

  * The script mounts the primary volume referenced
  * Checks if on the home network:
    * if so, resumes paused duplicati
    * if not, pauses duplicati

  * Create launchctl jobs to run the scripts every 60 seconds.

```
    cat ~/Library/LaunchAgents/com.mount.duplicati001.plist
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <!-- ~/Library/LaunchAgents/com.mount.duplicati001.plist -->
    <dict>
      <key>Label</key>
      <string>com.mount.duplicati001</string>
      <key>ProgramArguments</key>
      <array>
        <string>/Users/asterr/Library/Scripts/mount-duplicati001.sh</string>
      </array>
      <key>RunAtLoad</key>
      <true/>
      <key>StartInterval</key>
      <integer>60</integer>
    </dict>
    </plist>
```

```
    launchctl load -w ~/Library/LaunchAgents/com.mount.duplicati001.plist
```

```
    cat ~/Library/LaunchAgents/com.mount.duplicati002.plist
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <!-- ~/Library/LaunchAgents/com.mount.duplicati002.plist -->
    <dict>
      <key>Label</key>
      <string>com.mount.duplicati002</string>
      <key>ProgramArguments</key>
      <array>
        <string>/Users/asterr/Library/Scripts/mount-duplicati002.sh</string>
      </array>
      <key>RunAtLoad</key>
      <true/>
      <key>StartInterval</key>
      <integer>60</integer>
    </dict>
    </plist>
```

```
    launchctl load -w ~/Library/LaunchAgents/com.mount.duplicati002.plist
```
