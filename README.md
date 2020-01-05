# Brain

## Requirements

1. Elixir 1.9.x
1. Erlang 22.0.x

## Server configuration

* `/usr/bin/mix` (can be symlinked to `/home/pi/.asdf/shims/mix`)
* systemd for the user:

    ```bash
    # as root
    loginctl enable-linger app

    # as app
    echo "export XDG_RUNTIME_DIR=/run/user/$(id -u)" >> ~/.bashrc

    # symlink the service
    ln -sf /opt/brain/server/systemd/user/brain.service ~/.config/systemd/user/brain.service
    ```

## Deployment

```bash
./server/deploy
```

Make sure to reload systemd daemon after updating service file:

```bash
ssh brain "/bin/systemctl --user daemon-reload"
```

## Resources

* (Mnesia manual)[http://erlang.org/doc/man/mnesia.html]
* (Raspberry Pi Pinout)[https://pinout.xyz/]
