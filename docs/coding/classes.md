[TOC]

## Player Classes

It may sound strange but there is no such thing as Player or NPC classes in the Ranvier engine. The engine simply has
skills and how you decide to restrict the usage of those skills is up to you. There is an example implementation of
player classes as well as class selection during character creation in the example bundles if you wish to implement them
in your game.

## Skills/Spells

Skills and Spells both are defined as Skills (see `src/Skill.js`). Spells are just skills with a different `type`. In this guide
we'll implement 1 active skill and 1 passive skill to see a demo. You can see more complex examples abilities including
heals, DoTs (damage over time), and defensive abilities in the `bundle-example-classes` bundle.

Skills are defined in the `skills/` folder of a bundle:

### Active Skill: lunge

This is a simple damage skill that will deal 250% of the player's weapon damage.

```
bundles/my-bundle/
  skills/
    lunge.js
```

```javascript
'use strict';

// import necessary classes from core
const { Broadcast, Damage, SkillType } = require('ranvier');

// import custom lib from another bundle
const Combat = require('../../bundle-example-combat/lib/Combat');

// It's handy to define the different "tuning knobs" of skills right near the top all in one place so you can easily
// change them if you need to.
const damagePercent = 250;
const energyCost = 20;

function getDamage(player) {
  return Combat.calculateWeaponDamage(player) * (damagePercent / 100);
}

/**
 * Basic warrior attack
 */
module.exports = {
  // Friendly name of the skill, shown to the player on the skill list command.
  name: 'Lunge',

  // The type defines which of the ability managers you can find it in.
  // Either in state.SkillManager or state.SpellManager, respectively.
  type: SkillType.SKILL,

  /*
  If requiresTarget is true, the skill usage will fail if the player doesn't specify a target,
  unless you also add the `targetSelf: true` option, in which case if the player
  doesn't specify a target it will target themselves (for example, a healing spell).
  */
  requiresTarget: true,

  // If initiatesCombat is true, using the skill against a target will make the player
  // enter combat against them.
  initiatesCombat: true,

  /*
  The resource config defines the resource cost of the skill on use and is
  optional. Ranvier also supports multiple resource costs by defining an array
  with each entry in the array following the format of the single resource cost
  below.
  */
  resource: {
    // attribute to deduct the cost from
    attribute: 'energy',
    // amount to deduct
    cost: energyCost,
  },


  /*
  Cooldown let's you prevent immediate successive use of a skill by
  configuring the number of seconds between uses. This configuration will create
  a skill-specific cooldown of 6 seconds.
  */
  cooldown: 6,
  /*
  Cooldown can also be configured to be shared between multiple skills such
  that while any skill in the group is on cooldown no skills in the group may be
  used. It can be configured like so:

  cooldown: {
    length: 6,
    group: 'warrior-direct-attack',
  },

  In either case the core will throw a SkillErrors.CooldownError exception if
  execute() is called on a skill which cannot be used due to a cooldown.
  */

  /*
  The run method is where all the magic of skills happen and has a very similar layout to a
  command. A closure accepting GameState in 'state' and returning a function which,
  in this case takes the arguments to the skill, the player that executed the skill
  and the target of the skill
  */
  run: state => function (args, player, target) {
    // This is a simple damage skill so we'll create a new damage instance.
    // See the Attributes guide for more details
    const damage = new Damage('health', getDamage(player), player, this, {
      type: 'physical',
    });

    // Show some flashy effects to the player, target, and the other players in the room
    Broadcast.sayAt(player, '<red>You shift your feet and let loose a mighty attack!</red>');
    Broadcast.sayAtExcept(player.room, `<red>${player.name} lets loose a lunging attack on ${target.name}!</red>`, [player, target]);
    if (!target.isNpc) {
      Broadcast.sayAt(target, `<red>${player.name} lunges at you with a fierce attack!</red>`);
    }

    // apply the damage to the target
    damage.commit(target);
  },

  // the info function is used in `bundle-example-classes/commands/skill.js` to show details
  // about an ability to the player
  info: (player) => {
    return `Make a strong attack against your target dealing <bold>${damagePercent}%</bold> weapon damage.`;
  }
};
```

### Passive Skill: Second Wind

This will be an example implementation of a "passive" skill: one that is always working in the background that the
player doesn't type a command to use. The second wind passive ability is quite interesting: Once every 2 minutes, if the
player's energy drops below 30% it will restore 50% of their max. To do this we'll need to create two parts: first, the
skill file, and second the effect that will be applied to the player.

```
bundles/my-bundle/
  skills/
    secondwind.js
  effects/
    skill.secondwind.js
```

#### Skill file

```javascript
'use strict';

const { SkillFlag, SkillType } = require('ranvier');

// Again, tuning knobs are at the top to make changing them easier
const interval = 2 * 60;
const threshold = 30;
const restorePercent = 50;

/**
 * Basic warrior passive
 */
module.exports = {
  name: 'Second Wind',
  type: SkillType.SKILL,
  // This 'flags' key is the first important part, we want to mark our skill as passive
  flags: [SkillFlag.PASSIVE],

  // 'effect' is the second most important, here we tell the skill what effect to apply
  // to the player
  effect: "skill.secondwind",

  // This is a passive skill but you can still configure its cooldown and manually
  // force the skill to enter a cooldown as we'll see when we build the effect
  cooldown: interval,

  // configureEffect allows the skill to modify the effect before it's applied to the
  // player
  configureEffect: effect => {
    // in this case we're customizing the default threshold and restorePercent of
    // the 'skill.secondwind' effect that we will build later
    effect.state = Object.assign(effect.state, {
      threshold,
      restorePercent,
    });

    return effect;
  },

  info: function (player) {
    return `Once every ${interval / 60} minutes, when dropping below ${threshold} energy, restore ${restorePercent}% of your max energy.`;
  }
};
```

#### Effect file

This will be a brief refresher on effects. See the [Effect](effects.md) for more detail.

```javascript
'use strict';

const { EffectFlag, Heal } = require('ranvier');

/**
 * Implementation effect for second wind skill
 */
module.exports = {
  config: {
    name: 'Second Wind',
    type: 'skill:secondwind'
  },
  flags: [EffectFlag.BUFF],
  listeners: {
    // we want to listen for any type the player takes damage to one of their attributes
    damaged: function (damage) {
      // ignore any damage that isn't to energy
      if (damage.attribute !== 'energy') {
        return;
      }

      // manually check our cooldown
      if (this.skill.onCooldown(this.target)) {
        return;
      }

      // don't do anything if they have more than 30% of their max energy. Note that
      // 'threshold' was configured by the skill's configureEffect function
      if ((this.target.getAttribute('energy') / this.target.getMaxAttribute('energy')) * 100 > this.state.threshold) {
        return;
      }

      Broadcast.sayAt(this.target, "<bold><yellow>You catch a second wind!</bold></yellow>");
      // create the Heal to heal the player's energy
      const amount = Math.floor(this.target.getMaxAttribute('energy') * (this.state.restorePercent / 100));
      const heal = new Heal('energy', amount, this.target, this.skill);
      heal.commit(this.target);

      // manually start the cooldown of the skill
      this.skill.cooldown(this.target);
    }
  }
};
```

## Customizing Cooldowns

As demonstrated above a skill can be configured to have a cooldown length. The cooldown is implemented internally by an
effect with the id `cooldown`. You can customize the details of this effect by creating your own effect with the id
`cooldown` in a bundle which will override the default. See the [Effects](effects.md) guide for more detail.
