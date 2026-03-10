# YaDus - Yet another Discord update script

## Setup
1. Install the script
```bash
sudo cp update-discord.sh /usr/local/bin/update-discord.sh
sudo chmod +x /usr/local/bin/update-discord.sh
```

2. (Optional) Allow it to run without a password prompt (add this via `sudo visudo`):
```
yourusername ALL=(ALL) NOPASSWD: /usr/bin/tar, /usr/bin/tee, /usr/bin/touch, /usr/bin/chmod
```

3. Install the systemd units
```bash
sudo cp discord-update.service /etc/systemd/system/
sudo cp discord-update.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now discord-update.timer
```

4. Verify it's active
```bash
systemctl list-timers discord-update.timer
journalctl -u discord-update.service   # view logs
cat /var/log/discord-update.log        # human-readable log
```


## How the version check works:

It sends a HEAD request to the Discord download URL and reads the redirect URL, which contains the version number (e.g. discord-0.0.123.tar.gz)
It compares that against /opt/Discord/.installed_version (a small cache file it creates after each update)
Only if versions differ does it download the new tarball

The timer runs daily at 09:00, but with Persistent=true — so if your machine was off at that time, it catches up on next boot. No service interruption since the running Discord process keeps its old file handles until you restart it.