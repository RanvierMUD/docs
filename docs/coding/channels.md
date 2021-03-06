Channels are any mode of communication between players in the game. This guide will go over creating 4 different
channels with different audiences as an example of how you may want to implement your own: say, yell, tell, and chat.

[TOC]

## channels.js

The first step to adding channels is to create the `channels.js` file in your bundle.

```
bundles/my-bundle/
  channels.js
```

Almost identical to all other bundle loaded `.js` files, channels.js instead returns an array of channels. The examples
below show only one channel per file but you can absolutely have multiple channels, hence returning an array.

```javascript
'use strict';

/* The Channel module also exports channel related Error classes, we only need
   the actual Channel class */
const { Channel } = require('ranvier').Channel;

module.exports = [ ];
```

## Example channels

### chat

This `chat` channel is an example of a game-wide communication channel. All players in the game see it.

```javascript
'use strict';

const { WorldAudience, PlayerRoles } = require('ranvier');
const { Channel } = require('ranvier').Channel;

module.exports = [
  new Channel({
    // the name of the channel is the command the player will use
    name: 'chat',

    // Aliases for the channel, in this example, if your command is ". Hello" is equivalent to "chat Hello"
    aliases: ['.'],

    // Information about this channel shown when player types channel name without a message
    description: 'Chat with everyone on the game',

    /*
    optional color of output from his channel.
    Available colors are: black, red, green, yellow, blue, magenta, cyan, and white.
    Additionally you can specify 'bold' as a color to make the text bold. e.g., color: ['bold', 'red'],
    */
    color: ['bold', 'green'],

    /*
    `audience` defines who will receive the message from this channel.
    */
    audience: new WorldAudience(),

    /*
    Optionally you can specify a minimum player role required to use the channel
    Note: This property is not used by the core to perform any restrictions, it is simply added as a
    public property to allow bundles to access it and do their own restriction.

    minRequiredRole: PlayerRoles.ADMIN,
    */
  }),
];
```

### say

`say` is a common MUD channel which communicates a message to other players in the same room as the player.

```javascript
'use strict';

const { RoomAudience } = require('ranvier');
const { Channel } = require('ranvier').Channel;

module.exports = [
  new Channel({
    name: 'say',
    color: ['cyan'],
    description: 'Send a message to all players in your room',
    audience: new RoomAudience(),

    /*
    formatter allows you to customize how message from this channel appear to the sender and receiver
    `sender` defines how the message appears the sender, and vice versa for target.
    Both functions get the `Player` who sent it, the `Player` receiving the message, the message itself
    and the `colorify` function to apply the channel's color to the message.
    */
    formatter: {
      sender: function (sender, target, message, colorify) {
        return colorify(`You say, '${message}'`);
      },

      target: function (sender, target, message, colorify) {
        return colorify(`${sender.name} says, '${message}'`);
      }
    }
  }),
];
```

### tell

`tell` is an example of a private channel. The message is only shown to the sender and target.

```javascript
'use strict';

const { PrivateAudience } = require('ranvier');
const { Channel } = require('ranvier').Channel;

module.exports = [
  new Channel({
    name: 'tell',
    color: ['bold', 'cyan'],
    description: 'Send a private message to another player',
    audience: new PrivateAudience(),
    formatter: {
      sender: function (sender, target, message, colorify) {
        return colorify(`You tell ${target.name}, '${message}'`);
      },

      target: function (sender, target, message, colorify) {
        return colorify(`${sender.name} tells you, '${message}'`);
      }
    }
  }),
];
```

### yell

`yell` is an example channel that sends a message only to players in the same area as the sender.

```javascript
'use strict';

const { AreaAudience } = require('ranvier');
const { Channel } = require('ranvier').Channel;

module.exports = [
  new Channel({
    name: 'yell',
    color: ['bold', 'red'],
    description: 'Send a message to everyone in your area',
    audience: new AreaAudience(),
    formatter: {
      sender: function (sender, target, message, colorify) {
        return colorify(`You yell, '${message}'`);
      },

      target: function (sender, target, message, colorify) {
        return colorify(`Someone yells from nearby, '${message}'`);
      }
    }
  }),
];
```

## Scripting

Game entities (Area, Room, NPC, Player) can be scripted based on the `channelReceive` event to react to messages. Below
is an example script for a `Room` which opens a locked door when the player says a specific word:

```js
'use strict';

const { Broadcast } = require('ranvier');

module.exports = {
  listeners: {
    channelReceive: state => function (channel, sender, message) {
      // we only care about the 'say' channel
      if (channel.name !== 'say') {
        return;
      }

      // check to see if they have spoken elvish "Friend"
      if (!message.toLowerCase().match(/\bmellon\b/)) {
        return;
      }

      // find the door to the next room. `this` is the current room
      const downExit = this.getExits().find(ex => ex.direction === 'down');
      const nextRoom = state.RoomManager.getRoom(downExit.roomId);

      Broadcast.sayAt(sender, 'You have spoken "friend", you may now enter.');

      nextRoom.unlockDoor(this);
      nextRoom.openDoor(this);

      Broadcast.sayAt(sender, 'A large stone rumbles out of the way, revealing a staircase downward.');
    }
  }
};
```

Because NPCs and Players get this event that means an `Effect` can listen for it. This allows for crazy things like
equipment that talks back to the player, damaging a player if they say a bad word, a charm effect that allows a player
to command an NPC by speaking to it. The sky's the limit.
