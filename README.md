# Candfans-ripper
Script to download entire profiles from Candfans utilizing yt-dlp, gallery-dl and cookies from firefox.

The script isn't very dynamic, requires a candfans subscription to the creator and that you are logged in through firefox since yt-dlp and gallery-dl is hardcoded to use cookies from firefox.

## Usage

```powershell
. Candfans-ripper.ps1

download-candfans -path "C:\candfans" -user "hioRIN" -gallerydlPath "C:\Program Files\gallerydl\gallery-dl.exe" -ytdlpPath "C:\Program Files\ytdlp\yt-dlp.exe"
```

The user parameter is based on the profile url on candfans: https://candfans.jp/**hioRIN**.

The path parameter is the destination folder.
