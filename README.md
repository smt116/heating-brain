# Heating Brain

Heating Brain is a hobby project and kind of a playground. It means the code may change a lot, and there are several places for improvements.

I've started the project because I was very disappointed about "the industry device" for controlling the floor heating system in my house. It turned out that it is highly inefficient and lacks features that I would like to have. I decided to buy a Raspberry PI Zero, a Relay controller, a few 1-wire sensors and put it together. I created this application to:

- allow checking the temperatures, valves state, and gas stove via UI (i.e., heating-brain.local),
- ensure the controller won't enable gas stove until there is a sufficient heating extraction (i.e., enough floor sections are opened),
- allow introducing a complex "expected temperates time-table" for all sections.

In the future, I would like to improve the system by teaching it when to start the gas stove to achieve the expected temperature on a given hour in a given section (handling the thermal inertia of the floor).

The controller already gave my 20-30% better performance than "the industry device" in terms of gas consumption.

## Requirements

See `.tool-versions` file.

## Deployment

```bash
./server/deploy
```

## Raspberry Pi Zero Setup

### On the memory card

1. Install [Raspbian Buster Lite](https://www.raspberrypi.org/downloads/raspbian/) on the memory card. See [official documentation](https://www.raspberrypi.org/documentation/installation/installing-images/README.md) for details.
1. Copy `server/config.txt` into the card (as `config.txt`).
1. Configure network connection by creating `wpa_supplicant.conf` file on the card with the following content (adjust the credentials):

    ```
    country=PL
    ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
    update_config=1
    network={
        ssid="[wifi-name]"
        psk="[wifi-password]"
        key_mgmt=WPA-PSK
    }
    ```
1. Enable SSH by creating `ssh` file.

### From host system after booting the server:

1. [Allow password-less SSH connections](https://www.raspberrypi.org/documentation/remote-access/ssh/passwordless.md):

    ```
    ssh-copy-id pi@[ip]
    ```

### On the server

1. [Set the hostname](https://thepihut.com/blogs/raspberry-pi-tutorials/19668676-renaming-your-raspberry-pi-the-hostname):

    ```
    sudo sed -i 's/raspberrypi/heating-brain/g' /etc/hostname
    sudo sed -i 's/raspberrypi/heating-brain/g' /etc/hosts
    ```

1. [Fix the `cannot change locale (en_US.UTF-8)` issue](https://www.jaredwolff.com/raspberry-pi-setting-your-locale/):

    ```
    sudo sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
    sudo locale-gen en_US.UTF-8
    sudo update-locale en_US.UTF-8
    ```

1. Set the new password:

    ```
    sudo passwd pi
    ```

1. Upgrade distro:

    ```
    sudo apt-get update
    sudo apt-get dist-upgrade
    sudo apt-get autoclean
    ```

1. Install Erlang and Elixir.

1. Configure [rsyslog](https://www.rsyslog.com/doc/master/tutorials/reliable_forwarding.html) (optional):

    ```
    # /etc/rsyslog.d/01-ignore-rngd.conf
    if $programname == 'rngd' then /var/log/rngd.log
    & stop

    if $programname == 'rng-tools' then /var/log/rngd.log
    & stop

    # /etc/rsyslog.d/02-cron.conf
    if $programname == 'cron' then /var/log/cron.log
    & stop

    # /etc/rsyslog.d/99-nas.conf
    use local address like "rsyslog.local"
    *.* @192.168.2.10:514

    $ActionQueueFileName queue
    $ActionQueueMaxDiskSpace 1g
    $ActionQueueSaveOnShutdown on
    $ActionQueueType LinkedList
    $ActionResumeRetryCount -1

    # /etc/logrotate.d/rsyslog
    /var/log/rngd.log
    {
      rotate 4
      weekly
      missingok
      notifempty
      compress
      delaycompress
      sharedscripts
      postrotate
        /usr/lib/rsyslog/rsyslog-rotate
      endscript
    ```

1. Create application directories:

    ```
    mkdir -p /srv/backups /opt/heating_brain
    chown pi:pi /opt/heating_brain/ /srv/backups/
    ```

1. Configure backups:

    ```
    # Add in crontab:

    0 * * * * /opt/heating_brain/_build/prod/rel/heating_brain/bin/heating_brain rpc ':ok = Collector.Storage.create_backup()'
    15 10 * * * find /srv/backups -type f -mtime +14 -ls -exec rm -f -- {} \;
    ```

### From host system after setting up the server:

1. Deploy the code:

    ```
    ./server/deploy
    ```

    The first deployment will be significantly longer.

## Resources

* (Mnesia manual)[http://erlang.org/doc/man/mnesia.html]
* (Raspberry Pi Pinout)[https://pinout.xyz/]
* (Installing OS on the memory card)[https://www.raspberrypi.org/documentation/installation/installing-images/README.md]
