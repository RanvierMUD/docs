Attributes comprise the changing numerical properties of an `Npc` or `Player` (both referred to simply as "character"
from here on). Things like health, strength, and mana. An `Attribute` should be used (instead of say, metadata) if you
have a numerical property that can change over time (by damage or some other process) or be modified by an `Effect` from
something like a potion or piece of equipment.

[TOC]


## Defining Attributes

To be able to set an attribute on a character you must first write an attribute definition.  It may seem cumbersome that
you have to write code to create an attribute before a builder can use it. The reason for this is that, in Ranvier,
attributes can be more than a simple value; each can have a custom formula depending on other attributes, e.g., "mana"
may use the formula `floor(intellect + character.level * 0.33)`. You could write all the helper functions yourself but
that's what the engine is for!

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

Defining an attribute does not assign it to any characters, the attribute is simply now available to add.

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

    metadata: {
      // some custom constant we'll use in the formula
      levelMultiplier: 0.33,
    },

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
      return Math.floor(
        mana +
        intellect +
        // to access the `metadata` inside the formula use `this.metadata`
        character.level * this.metadata.levelMultiplier
      );
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

### Recipes

#### Class/race modifiers

Example computed attribute which uses metadata to change the formula
depending on the character's class.

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

Because the modifiers are stored in the attribute metadata you can access this
value outside of the formula as well. For example, if you wanted to create a
command which shows the AP bonus for a character:

```js
const ap = character.getAttribute('attack_power');
const characterClass = character.getMeta('class') || '_default';
const modifier = ap.metadata.classModifiers[characterClass];
Broadcast.sayAt(character, `You get ${modifier} AP per point of strength`);
```

So with that attribute a warrior with 20 `strength`, and a ring of +15 `attack_power` will have

```
   10 (base)
+  15 (ring effect)
+  20 (strength) * 2 (modifier)
-----
   65 attack_power
```

#### % bonuses

It's a common RPG pattern to have an attribute like `health` both static `+20 max health` and `+5%
max health` bonuses. To accomplish this we will use two attributes: `health` and `health_percent`.

* `health` will act as the base health attribute and handle static `+20 max health` style bonuses. This attribute will also
  be used for the player taking damage/being healed.
* `health_percent` will exist only to handle  `+5% max health` style bonuses and will generally only be modified by effects

We'll use the formula:

```
(health + static bonus) * percentage bonus
```

```js
[
  {
    name: 'health',
    base: 100,
    formula: {
      requires: ['health_percent'],
      fn: function (character, health, health_percent) {
        // `health` will be our health pool after modified by our static bonuses
        // like +20 max health

        // health_percent will be a whole number like 25 so we've gotta turn
        // 25 into 1.25
        const modifier = (1 + (health_percent / 100));

        return Math.round(health * modifier);
      },
    }
  },

  { name: 'health_percent', base: 0 },
]
```

Let's take the following scenario:

* Base `health` of 100
* Wearing a ring with `+20 max health`
* Has an effect that gives `+30% max health`
* So the formula will look like:

```
(100 + 20) * (1 + (30 / 100))
            =
        120 * 1.30
            =
           156
```

If, however, you want to have the formula:

```
(health * percentage bonus) + static bonus`
```

We'll need to change  our formula slightly:

```js
// ...
fn: function (character, health, health_percentage) {
  // get the static bonus amount from the difference of base and current max health
  const staticBonus = health  - this.base;

  // again, health_percent will be a whole number like 25 so we've gotta turn
  // 25 into 1.25
  const modifier = (1 + (health_percent / 100));

  return Math.round(health * modifier + staticBonus);
},
// ...
```

Now, given the same scenario:

* Base `health` of 100
* Wearing a ring with `+20 max health`
* Has an effect that gives `+30% max health`
* So the formula will look like:

```
(100 * (1 + (30 / 100))) + 20
            =
        130 + 20
            =
           150
```

## Giving Characters Attributes

As mentioned above, defining attributes does not assign them to any character. By default characters have no attributes.
You must add them either in their definition in the case of NPCs, or at runtime in the case of player creation.

### NPCs

For NPCs setting attributes is just a matter of using the `attributes` property in their definition. For example:

```yaml
- id: rat
  name: A Rat
  level: 2
  attributes:
    # each key is the attribute you want to add, and the value will be the
    # base for that attribute
    health: 100
```

### Players

Attributes must be added to players at runtime. This is generally done during player creation though it can be done any
time.

```js
// First you create an instance of that attribute, in this case strength. The
// second parameter is the base value, in this case 10
const strength = state.AttributeFactory.create('strength', 10);

// then add it to the player
player.addAttribute(strength);
```

That's it. When the player is saved they will retain that attribute until you remove it

## How Attributes are evaluated

An attribute's current value is actually represented by 4 pieces working together: the `base` property, the `delta`
property, its formula if it has one, and any active effects a character has which modify the attribute.

#### The pieces

`base`
:    The maximum value for the attribute before any effects or formulas. This should rarely, if ever, change. An
exception case may be, for example, if you have a system that allows characters invest points to raise the base value.
Base should never change if your intent is to temporarily modify the value. The attribute's value cannot exceed `base`
without formulas or effects. `base` can also not be negative. If you want a negative attribute, use a positive attribute
with a formula that inverts the value.

Effects
:    Effects may have their own function which modify one or more attributes. More detail for writing such effects can
be found in the [Effects](effects.md) guide.

Formula
:    As already described in this guide an attribute may have a custom formula to obtain its final value.

`delta`
:    This property is used to keep track of how much the attribute has changed. Delta is always <= 0.  Meaning that
without an effect or custom formula an attribute can never have a value above its base. The value of `delta` is changed
via `Damage`, `Heal`, or direct calls to `character.lowerAttribute`/`character.raiseAttribute`. The usage of which is
described in the [Modifying Attributes](#modifying-attributes) section.

#### The process

Therefor, getting the current value for an attribute happens like this:

* Taking the `base` value
* Feeding it to the character's effects which may increase or decrease it. This is called the "effective base"
* If the attribute has a formula the effective base is fed to the formula, this is called the "formulated base." If it
  doesn't have a formula the formulated base is the same as the effective base
* Adding `delta` to the formulated base

## Displaying Attributes

Displaying the current and maximum value for a character is done via the `getAttribute` and `getMaxAttribute` methods of
that character. For example, if you have a command that displayed a player's current and maximum health to the player:

```js
const current = player.getAttribute('health');
const max = player.getMaxAttribute('health');
Broadcast.sayAt(player, `You have ${current} of ${max} health.`);
```

If you try to access an attribute the character does not have both methods will throw a `RangeError`.

## Modifying Attributes


The whole point of attributes is that their value changes over time. There are 3 ways to modify an attribute's value:
change the `base` value, lower/raise it (changing the `delta`), or through [Effects](effects.md). Modifying attributes
in an effect is covered in that guide. As described above the `base` will rarely, if ever, change but can be done with
`character.setAttributeBase(attr, value)`. What remains is how to change the delta, of which there are two techniques:
using Damage/Heal, or directly calling `lowerAttribute`/`raiseAttribute`.

### Direct Modification

Consider this the low-level API, mainly used internally by Ranvier itself. You can use it, but it's not recommended.
Using `character.lowerAttribute(attr, value)` or `character.raiseAttribute` will change the `delta` of an attribute
directly. Let's look at a character with a basic `health` attribute with a base of 100 and no effects:

```js
character.getAttribute('health'); // 100

character.lowerAttribute('health', 10);
// `delta` is now -10, therefor the calculation is 100 + -10 = 90

character.getAttribute('health'); // 90

character.raiseAttribute('health', 20);
// delta is always <= 0, so even though we asked to raise by 20 the maximum health is 100

character.getAttribute('health'); // 100
```

The current value of the attribute will be updated but nothing will be notified of this change. Effects will also not be
able to increase or decrease the change. If you want scripts to be notified of an attribute being raised/lowered, or you
want an effect to be able to modify the amount you will want to use `Damage` or `Heal`

### Damage/Heal

`Damage` and `Heal` do exactly what they say on the tin. `Damage` is the equivalent of `lowerAttribute` and `Heal` the
equivalent of `raiseAttribute`. Damage and Heal are classes that allow you to attach additional information to an
attribute changing such as what is causing damage, the type of damage, or whether it should be displayed to the player.
The additional benefits of `Damage` and `Heal` are that they emit events which scripts can listen for and they hook into
the target and attacker's effects to increase or decrease the damage.

#### Damage

Let's take an example of a script where we want an NPC to deal damage to a player

```js
const { Damage } = require('ranvier');

const somedamage = new Damage({
  // amount is self-explanatory and is required
  amount: 20,

  // attribute is another required config which specifies which attribute we are
  // causing damage to. Damage/Heal aren't limited to health. You can, and should,
  // use them for any time _any_ attribute is lowered
  attribute: 'health',

  // attacker is an optional property. It can be any game entity: an Area, Room,
  // NPC, Player, or Item. It will be the recipient of the 'hit' event
  attacker: someNPC,

  // Another optional property is `metadata` which acts as a place for you to
  // put any extra info about this damage that is not a core property.
  // For example:
  metadata: {
    type: 'fire',
    critical: false,
  },
});

// Our Damage object now exists but has not been dealt to any character, to do
// that you use the `commit` method
somedamage.commit(target);
```

Before the player ultimately takes damage any effects the attacker has which have `outgoingDamage` modifiers will
evaluate and modify the amount, then any of the target's effects with `incomingDamage` modifiers will modify the amount.
Then `lowerAttribute` will be called and player's health will lower by 20.  At this point if the damage has an
`attacker` configured (as ours does) they will receive a 'hit' event because they caused some damage.  Next the player
will receive at 'damaged' event.

The `hit` event receives the target that was hit, the `Damage` object, and the final amount of damage that was caused to that
target after effects

The `damaged` event receives the `Damage` object, and the final amount caused

> Insight: Skills internally use `Damage` to deduct their costs because this allows for things like effects that say
> "Lowers the mana cost of Fireball by 20%"

#### Heal

Heal is use identically to `Damage`, the only difference is that instead of the `hit` for landing a hit there is `heal`,
and instead of `damaged` for taking damage, there is `healed`.

Here's an example of a potion healing the player

```js
const { Heal } = require('ranvier');

const someheal = new Heal({
  amount: 20,
  attribute: 'health',
  attacker: this, // `this` here being the potion Item
});

someheal.commit(player);
```
