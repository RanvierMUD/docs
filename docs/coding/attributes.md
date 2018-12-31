Attributes comprise the changing properties of an `Npc` or `Player` (both referred to simply as "character" from here
on). Things like health, strength, and mana. To be able to set an attribute on a character you must first write an
attribute definition.

It may seem cumbersome that you have to write code to create an attribute before a builder can use
it. The reason for this is that, in Ranvier, attributes can be more than a simple value; each can have a custom formula
depending on other attributes, e.g., "mana" may use the formula `floor(intellect + character.level * 0.33)`. You could
write all the helper functions yourself but that's what the engine is for!

[TOC]

## Defining Attributes

Attributes are defined in the `attributes.js` file in a bundle:

```
bundles/
  my-bundle/
    attributes.js
```

Each bundle may only have one attributes file but each file may define many attributes. The format of an attributes
definition is as follows:

```js
// the attributes.js file exports an array of attribute definitions
module.exports = [
  {
    // The two required properties of an attribute are 'name' and 'base'
    // name is how you will reference the attribute in code
    name: 'favor',

    // 'base' defines the starting and _maximum_ value for that attribute. This
    // may be changed at runtime with `character.setAttributeBase('attr', value)`
    // This will only change the base value for that character, not all characters
    // with that attribute.
    base: 10
  },
];
```

### Custom Metadata

Attributes also have a metadata property which you can use to store any additional info you may want like friendly
names, racial modifiers, etc.

```js
{
  name: 'strength',
  base: 0,

  metadata: {
    label: 'Strength',
  },
}
```
### Computed Attributes

Computed attributes allow you to have an attribute which depends on other attributes or character data to obtain its final value.

```js
{
  name: 'mana',
  base: 10,

  // To make an attribute computed you add the 'formula' config with the
  // 'requires' and 'fn' properties
  formula: {

    // 'requires' specifies which attributes the formula depends on for its
    // calculation. You may depend on attributes defined in a different bundle.
    requires: ['intellect'],

    // 'fn' is the formula function. The function will automatically receive
    // as arguments:
    //   1. The character the attribute belongs to
    //   2. The current value, after effects, of this attribute
    //   3+ One argument for each attribute in the `requires` list in the same
    //      order. For example, if your requires was:
    //        ['foo', 'bar', 'baz']
    //      Then your formula function would receive:
    //        function (character, mana, foo, bar, baz)
    //      Each is the value, after effects/formulas, of that attribute
    fn: function (character, mana, intellect) {
      // Using the example formula from before:
      return Math.floor(mana + intellect + character.level * 0.33);
      // it may seem strange to add mana as part of it
    }
  }
}
```

#### Circular References

A circular dependency check is done at startup to prevent attributes depending on each other. You will see the following
error when trying to run the server:

```
error: Attribute formula for [attribute-a] has circular dependency [attribute-a -> attribute-b -> attribute-a]
```

### Accessing Metadata
You've seen formula fn's use the `function (a) { return a; }` style instead of arrow syntax like `(a) => a`. The reason
is that `this` in a formula fn is the Attribute instance itself. Therefor you can use `this` to access the metadata of an
attribute.

```js
  {
    name: 'attack_power',
    base: 10,
    // We'll use the example that warriors get 2 points of attack power per
    // point of strength, whereas rogues and mages get less
    metadata: {
      // classModifiers is not special, it's just something I've made up.
      // Don't worry if your game doesn't plan on having classes. This could be
      // any data you like.
      classModifiers: {
        warrior: 2,
        rogue: 1,
        mage: 0.5,
        _default: 1,
      },
    },
    formula: {
      requires: ['strength'],
      fn: function (character, attack_power, strength) {
        const characterClass = character.getMeta('class') || '_default';
        const modifier = this.metadata.classModifiers[characterClass];
        return attack_power + (strength * modifier);
      },
    },
  },
];
```

## Modifying Attributes
