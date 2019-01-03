## Player Events

Player events scripts are identical to scripts you would create for an NPC, Room, or Item except that they listen for events
emitted on the player. You can have one Player Events script per bundle:

```
bundles/my-bundle/
  player-events.js
```

The structure of the file is identical to entity scripts, see the documentation for those in the
[Scripting](../building/scripting.md)

## Input Events

Input events are a bit more complex and arguably the most crucial scriptable part of Ranvier, they are events that fire on
the _socket_ of the player, not the Player instance.  This covers things like the user connecting to the game, logging
in, typing commands, anything that deals with _input_ itself before it gets to an actual command.

Each input event is defined in its own file inside the `input-events/` folder like so:

```
bundles/my-bundle/
  input-events/
    intro.js
```

## File Structure

In this example we'll implement the first event that ever gets fired once a player connects to Ranvier: 'intro'. This is the first input event
and the only one that _must_ be implemented if you choose to disable the default `bundle-example-input-events` bundle.

```javascript
'use strict';

// EventUtil has some helpers for outputing to the socket
const { EventUtil } = require('ranvier');

// Very similar structure to all of our bundle loaded javascript files.
module.exports = {
  /*
  The functionality of the input event is defined in the value of the 'event' key.  Again
  similar to entity scripts it is a closure that accepts the GameState in the state arg
  but returns a function accepting the socket
  */
  event: state => socket => {
    EventUtil.genSay(socket)('Welcome to my game!');

    /*
    Here we pass the socket to the next step of the connection process, the login event.
    Just as this file was defined in intro.js, the login event would be defined in login.js
    */
    return socket.emit('login', socket);
  }
};
```
