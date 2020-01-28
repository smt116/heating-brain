# Heating Brain

## Requirements

1. Elixir 1.9.x
1. Erlang 22.0.x

## Server configuration

* `/usr/bin/mix` (can be symlinked to `/home/pi/.asdf/shims/mix`)
* systemd for the user:

    ```bash
    # as root
    loginctl enable-linger pi

    # as user
    echo "export XDG_RUNTIME_DIR=/run/user/$(id -u)" >> ~/.bashrc
    ```

## Deployment

```bash
./server/deploy
```

## Restoring Mnesia backup

```bash
rm -rf /opt/heating_brain/mnesia/*
tar -xzvf /srv/backups/mnesia.2020.01.28.21.20.tar.gz --strip-components=3 -C /opt/heating_brain/mnesia/
```

## Resources

* (Mnesia manual)[http://erlang.org/doc/man/mnesia.html]
* (Raspberry Pi Pinout)[https://pinout.xyz/]
