All entities in Ranvier can be scripted: Items, NPCs, Rooms, and Areas. There are two ways to script an entity: a unique
script, or a behavior.  A unique script is a non-configurable script attached directly to that entity. Each entity can
only have one unique script. Behaviors, on the other hand, are configurable, reusable, and an entity may have many
behaviors.

[TOC]

## Unique Script

Unique scripts are stored under the `scripts/` folder for a given area with a subfolder for each entity type, like so:

```
bundles/my-area/areas/limbo/
  scripts/
    limbo.js // area script
    npcs/
      rat.js
    items/
      sword.js
    rooms/
      test.js
```

As a matter of convention scripts are named, `<entity id>.js`. It's not _required_ but it will help a
lot when trying to figure out what script goes to what entity.

See the relevant entity's guide section on how to set this in the yaml file.

### File Structure

```javascript
'use strict';

module.exports = {
  listeners: {
    someEvent: state => (/* event args: see the docs for said event to see its args */) {
      // do stuff here
    },
  },
};
```


## Behaviors

Behaviors are created inside the `behaviors/` directory inside your bundle _outside_ of your `areas/` directory. Another
key difference is that they are configurable in the entity's .yaml definition (see each entity type's documentation for
some examples).

```
bundles/my-bundle/
  areas/
    limbo/
    ...
  behaviors/
    npc/
      aggro.js
    item/
    room/
    area/
```

### File Structure

The first argument to a behavior listener is always the config object defined in the entity yaml file

```javascript
'use strict';

module.exports = {
  listeners: {
    someEvent: state => (config, /* event args */) => {
      /* given the example items.yml below `config` would be equal to
      { hello: "World" }
      */
    }
  }
};
```

Example behavior configuration for an item:
```yaml
- id: 9
  name: 'My Item'
  behaviors:
    test:
      hello: "World"
    # if your behavior has no configuration, simply use 'true' as its config
    some-behavior: true
```

## Behaviors as Flags &amp; metadata

In previous versions of Ranvier it was suggested to use a behavior without a script as a way to "flag" entities. This is
no longer needed as all entities now have a `metadata` property. As such you can use the metadata to create the flag
instead:

```yaml
- id: 9
  name: 'My Item'
  behaviors:
    # normal behavior
    test:
      hello: "World"
  # you may now use the metadata field to set any flags you wish to have
  metadata:
    cursed: true
    otherThing: "foobar"
    someDeep:
      metaObject:
        bar: "baz"
```

The old way will still work but will issue a warning on server startup.

You can access the metadata in scripts/commands with the `getMeta()` method:

```js
const isCursed = someItem.getMeta('cursed'); // true
const badMeta = someItem.getMeta('doesntExist'); // undefined
const otherThing = someItem.getMeta('otherThing'); // "foobar"
const deepBar = someItem.getMeta('someDeep.metaObject.bar') // "baz"
```

## Triggering a script/behavior

You may have something like the following in your code. It could be in a command or skill or even another script

```javascript
// trigger the 'foo' listener attached to `myItem`
myItem.emit('foo', player, 'baz');
```

**NOTE**: When writing an `emit` call to activate a behavior you DO NOT have to manually pass the `config` argument,
the engine automatically prepends it for behaviors.

## Core events

For a list of events the core emits for any given entity see the "Events" section in the [Source docs](../jsdoc/)
