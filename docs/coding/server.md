Server events allow you to hook into the startup and shutdown of Ranvier to do things like start a networking server to
accept player connections, host an API, or maybe a secure website for remote building.

### Folder Structure

```
bundles/my-bundle/
  server-events/
    my-events.js
```

The game server supports two events by default: `startup` and `shutdown`. As such the file structure will be as follows
(similar to all other event scripts):

### File Structure

```javascript
'use strict'

module.exports = {
  listeners: {
    /**
     * The startup event is passed the `commander` variable which lets you access command line arguments used to start
     * the server. As with all entity scripts/commands/etc. you also have access to the entire game state.
     */
    startup: state => function (commander) {
      // startup tasks here
    },

    shutdown: state => function () {
      // shutdown tasks here
    },
  }
};
```

See the [Networking](../extending/networking.md) guide for an example usage of server events
