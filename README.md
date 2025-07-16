# Bash AI Assistant

An LLM-based smart assistant that integrates with your bash terminal to perform context-aware command execution and provide answers to general questions.

## Getting Started

1.  Clone this repository:

    ```bash
    git clone https://github.com/noveky/bash-ai.git
    ```

2.  Run the installation script:

    ```bash
    chmod +x install.sh
    ./install.sh
    ```

3.  Source the updated `.bashrc` file:

    ```bash
    source ~/.bashrc
    ```

4.  Try it out!

    ```
    $ ai Why is my boot time so long
    To diagnose long boot times, you'll want to analyze the system's boot logs for delays. The tool systemd-analyze and systemd-analyze blame are helpful for this.

    systemd-analyze; systemd-analyze blame | head -20; ai proceed

    AI suggests running this command:
      systemd-analyze; systemd-analyze blame | head -20; ai proceed
    Approve? [y/n] y

    Executing approved command (1/1):
      systemd-analyze; systemd-analyze blame | head -20; ai proceed
    Startup finished in 9.688s (firmware) + 6.527s (loader) + 5.306s (kernel) + 23.035s (userspace) = 44.557s
    graphical.target reached after 22.694s in userspace.
    3min 17.980s apt-daily-upgrade.service
         13.423s e2scrub_reap.service
         10.553s snapd.seeded.service
          9.964s snapd.service
          9.663s man-db.service
          7.784s systemd-suspend.service
          6.670s NetworkManager.service
          5.441s dpkg-db-backup.service
          5.245s logrotate.service
          4.509s systemd-journal-flush.service
          4.482s sysstat-summary.service
          4.360s dev-sda4.device
          3.809s gnome-remote-desktop.service
          3.539s udisks2.service
          3.006s accounts-daemon.service
          2.536s power-profiles-daemon.service
          2.469s ModemManager.service
          2.336s polkit.service
          2.298s avahi-daemon.service
          2.294s bluetooth.service

    Your boot time is mainly delayed by apt-daily-upgrade.service, which takes over 3 minutes during boot. This is much higher than other services. Disabling or changing the scheduling of this service can significantly reduce your boot time.
    ```

## Contributing

Pull requests are welcome! Please open an issue first to discuss what you'd like to change.

## License

[MIT](https://opensource.org/license/mit)
