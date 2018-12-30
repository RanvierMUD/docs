[TOC]

## Installation

```sh
git clone git://github.com/shawncplus/ranviermud
cd ranviermud
npm install
```

At this point you will have a very empty Ranvier install. From here there are two approaches: from scratch, or use the
starter kit.

### Starter kit

To install the starter kit run `npm run init` and choose `Y` to install the example bundles. This will install a series
of bundles which demonstrate various features of the engine. You can use them as-is to make your own game or clone them
to customize them to your liking.

> NOTE: Be sure to read the [Bundles](extending/bundles.md) guide before editing the example bundles

Once the command is finished start the server as described below. You will then be able to connect through `telnet`
at hostname `localhost` on port 4000. The default login is `admin` for the username and `ranviermud` for the password.

### From scratch

If you wish to create a Ranvier game from scratch it's recommended that at minimum you install a server bundle to
allow connections to your game. Being the `telnet-connections` or `websocket-connections` (or both) bundles. For details
on installing and managing bundles see the [Bundles](extending/bundles.md) guide.

## Starting the server

Once you've installed (or not) the bundles you like to start the server run

```
./ranvier
```

This will start the server but it may stop when you close your terminal. To keep the server running after you close your
terminal there are various tools like [PM2](http://pm2.keymetrics.io/),
[systemd](https://nodesource.com/blog/running-your-node-js-app-with-systemd-part-1/), and many others depending on your
operating system/preference.

## Development workflow

When you make changes to bundles or the `ranvier.json` config you will generally need to restart the server to see the
changes in game. This makes coding "on live" a Very Bad Idea&trade; as it would be very annoying for players. As such
the recommended workflow is to have one checkout of `ranviermud` for development and another for your live server.

### Hotfixing commands

While we do not support "hotbooting" the entire game without restarting the server it is possible to reload your
commands from disk without restarting the server. If you have the `debug-commands` bundle enabled the `hotfix`
admin command will allow you to reload a command in game by doing `hotfix <command name>`.


## Next step

The next step is understanding what a bundle is, how they are loaded into the game, and how to manage and edit them. For
this follow the [Bundles](extending/bundles.md) guide.
