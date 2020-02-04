# Heating Brain

## Requirements

1. Elixir 1.10.x
1. Erlang (at least 22.x)

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

1. [Set the static IP address](https://thepihut.com/blogs/raspberry-pi-tutorials/how-to-give-your-raspberry-pi-a-static-ip-address-update).
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

1. [Install Erlang and Elixir](https://www.erlang-solutions.com/blog/installing-elixir-on-a-raspberry-pi-the-easy-way.html):

    ```
    wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb
    sudo dpkg -i erlang-solutions_2.0_all.deb
    rm erlang-solutions_2.0_all.deb
    sudo apt-get install -y elixir
    ```

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
    *.* @192.168.0.2:514

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

1. Application directories:

    ```
    mkdir -p /srv/backups /opt/heating_brain
    chown pi:pi /opt/heating_brain/ /srv/backups/
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
