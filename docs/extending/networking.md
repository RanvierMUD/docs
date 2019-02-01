Traditionally changing the network layer in MUDs is nigh impossible. But with Ranvier the server, like everything else,
is event based and the core code has no opinions on what network layer is used. 

This guide will walk through creating an example websocket networking bundle.

> Note: There is already a websocket networking bundle available for you to use as well as a telnet networking bundle.
> See the [Community Bundles](../community_bundles.md) page for a full list.

### The Transport Stream

First we will have to create a custom `TransportStream` to act as an adapter between the `WebSocket` and Ranvier. To do
this inside your bundle directory create a folder called `lib/` and in that folder let's create a file called
`WebsocketStream.js`

```
bundles/my-bundle/
  lib/
    WebsocketStream.js
```

In this file we will use the `TransportStream` class provided by the core as the base for our adapter.

```javascript
'use strict';

const { TransportStream } = require('ranvier');

/**
 * Essentially we want to look at the methods of WebSocket and match them to the
 * appropriate methods on TransportStream
 */
class WebsocketStream extends TransportStream
{
  attach(socket) {
    super.attach(socket);

    // websocket uses 'message' instead of the 'data' event net.Socket uses
    socket.on('message', message => {
      this.emit('data', message);
    });
  }

  /**
   * A WebSocket is writable if its readyState is 1
   */
  get writable() {
    return this.socket.readyState === 1;
  }

  write(...args) {
    if (!this.writable) {
      return;
    }

    // this.socket will be set when we do `ourWebsocketStream.attach(websocket)`
    this.socket.send(...args);
  }

  pause() {
    this.socket.pause();
  }

  resume() {
    this.socket.resume();
  }

  end() {
    // 1000 = normal close, no error
    this.socket.close(1000);
  }
}

module.exports = WebsocketStream;
```

### Starting the Server

To actually start the server we'll want to create our server event script. We will need a third party Node library
called `ws` so inside your bundle folder run `npm init` to create a package.json file for your bundle then `npm install
--save ws`.

```
bundles/my-bundle/
  server-events/
    websocket-server.js
```

```javascript
'use strict';

// import 3rd party websocket library
const WebSocket = require('ws');

// import core logger
const { Logger } = require('ranvier');

// import our adapter
const WebsocketStream = require('../lib/WebsocketStream');

module.exports = {
  listeners: {
    startup: state => function (commander) {
      // create a new websocket server using the port command line argument
      const wss = new WebSocket.Server({ port: commander.port });

      // This creates a super basic "echo" websocket server
      wss.on('connection', function connection(ws) {

        // create our adapter
        const stream = new WebsocketStream();
        // and attach the raw websocket
        stream.attach(ws);

        // this attaches out stream to the input events which handle direct input
        // from the player, everything from login to commands
        state.InputEventManager.attach(stream);

        stream.write("Connecting...\n");
        Logger.log("User connected via websocket...");

        // fire off the intro event to be handled by an input-event listener
        stream.emit('intro', stream);
      });
    },

    shutdown: state => function () {
      // no need to do anything special in shutdown
    },
  }
};
```

### Enabling our bundle

Finally inside `ranvier.json` in the root of the project add `my-bundle` to this enabled bundles list and Bob's your
uncle, as they say. Completely rewriting the network layer of the game engine in less than 100 lines of code including
comments: not bad at all.

