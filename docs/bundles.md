Bundles are the way you modify Ranvier's functionality without having to touch the core code. They let you modify
basically everything about the game: how commands are interpreted, commands themselves, channels, items, rooms, NPCs,
quests, login flow, spell effects, even the network layer of your game.

[TOC]

Bundles live under the `bundles/` folder of your project. They can be a git submodule (as will happen when using the
`install-bundle` command) or just a normal folder containing the files.

## What's in a Bundle

A bundle can contain any or all of the following children though it's suggested that you keep your bundles as modular as
possible, i.e., try to keep input events out of the same bundle you're building your areas.

<dl>
<dt><strong>areas/</strong></dt>
<dd>Area definitions and their items, rooms, NPCs, and quests along with the scripts for those entities</dd>

<dt><strong>behaviors/</strong></dt>
<dd>Scripts that are shared between entities of the same type, e.g., a behavior to have an NPC wander around an area</dd>

<dt><strong>classes/</strong></dt>
<dd>Player classes</dd>

<dt><strong>commands/</strong></dt>
<dd>What it says on the tin, commands to add to the game</dd>

<dt><strong>effects/</strong></dt>
<dd>Effects that can be applied to characters (NPCs/Players)</dd>

<dt><strong>help/</strong></dt>
<dd>Helpfiles for commands</dd>

<dt><strong>skills/</strong></dt>
<dd>Player skills (Spells are included, they're just skills with the SPELL type)</dd>

<dt><strong>input-events/</strong></dt>
<dd>Scripts attached to a connected socket, this involves things like handling login and parsing incoming data for commands</dd>
<dd><strong>Warning:</strong> Because of input events' important role it is generally not advised to load more than one bundle with input events</dd>

<dt><strong>server-events/</strong></dt>
<dd>Scripts attached to the startup of Ranvier itself such as starting a telnet server</dd>

<dt><strong>quest-goals/</strong></dt>
<dd>Quest goal definitions that can be used by builders when writing quests</dd>

<dt><strong>quest-rewards/</strong></dt>
<dd>Quest reward definitions that can be used by builders when writing quests</dd>

<dt><strong>channels.js</strong></dt>
<dd>Communication channels</dd>

<dt><strong>player-events.js</strong></dt>
<dd>Scripts attached to the player such being hit, gaining experience, leveling, etc.</dd>

<dt><strong>attributes.js</strong></dt>
<dd>Definitions of available attributes to assign to NPCs or players</dd>
</dl>

## How bundles are loaded

Before writing your first bundle it's important to know how bundles work and how they are loaded into Ranvier so you are
aware of how and when to access game data.

### Initialization

Ranvier first reads the `ranvier.json` config to determine how data should get loaded into the game. By default game
entities (NPCs, areas, rooms, items, and quests) are stored in YAML; Player data is stored in JSON files. This can
be changed, however, by following the [Entity Loading](extending/loaders.md) guide.

Ranvier then looks at the enabled bundles and follows the steps described below for each bundle

#### Scripts

Ranvier starts loading Javascript files into classes called `Manager`s and `Factory`s:

* Quest goals/rewards to `QuestGoalManager` and `QuestRewardManager` respectively
* Attributes definitions get loaded into the `AttributeFactory`
* Entity behaviors to their respective `BehaviorManager`
* Channels to the `ChannelManager`
* Player class definitions to the `ClassManager`
* Commands to the `CommandManager`
* Effects to the `EffectFactory`
* Input and Server events to their respective `EventManager`
* Player events to the `PlayerManager`
* and finally Skills to the `SkillManager`

Some of these `Manager`s and `Factory`s are only used internally, the main ones you may interact with inside  a script
or command include: `CommandManager` for executing commands, `EffectFactory` for creating effects and adding them to
players or NPCs, and the `SkillManager` for having players or NPCs perform skills.

#### Entities

Definitions for all game entities are loaded into their respective `Factory`s, e.g., `AreaFactory`, `RoomFactory`, etc.
from the configured data source. At this point all the definitions are loaded but none of those entities actually exist
in the game. The distribution step handles that after all the bundles have finished the initialization step.

### Distribution

Once all the scripts and all the entity definitions from all bundles have been loaded:

* `Area` instances are created from their definitions and added to the `AreaManager`
* For each `Area` created the `hydrate` method is called. This will use all the entity definitions to create instances
of rooms, npcs, and items and put them in their appropriate place

### Startup

At this point Ranvier triggers the `startup` event, notifying any bundles with `server-events` that the server has
started.

## Installing a bundle

### From a git repository

To install a bundle from a git repository there is a helper command which will install the repository as a git
submodule. This is the recommended approach to install a bundle as it allows you to easily receive updates from the
original author, or fork the bundle and do work on it without having all of the files live inside your project folder.

From the root of your project run

```sh
npm install <git repository url>
# for example
npm install https://github.com/RanvierMUD/progressive-respawn
```

The bundle is now installed but not enabled, see the next section for enabling/disabling bundles

### From a plain folder

To install a bundle from a normal folder move or copy it into the `bundles/` directory of your project.

Again, at this point the bundle is installed but not enabled.

### Managing enabled bundles

To enable or disable you can use the helper command  `npm run enable-bundle <bundle name>` or
`npm run disable-bundle <bundle-name>`. This will add or remove the bundle from the `bundles` list in `ranvier.json`. If
you wish to manually manage the list of enabled bundles you may edit that file manually.

## Removing a bundle

It's not necessary to remove bundles as you can disable them instead. With that said if you really want to remove a
bundle, for a submodule bundle you can use the helper command `npm run remove-bundle <bundle name>`. For a normal folder
bundle you can just delete the folder.

## Creating a bundle

To create a bundle make a folder under the `bundles/` directory. The name should not contain spaces or special
characters. If you are so inclined you may also create the bundle as a separate repository and use the aforementioned
repository bundle installation commands to add it to the project. That should be used if you intend on sharing the
bundle with others. If you intend to keep the bundle only in your project a normal folder will do just fine.


### 3rd party node libraries in bundles

Bundles are meant to be self-contained folders. With that in mind if your bundle relies on a node module
not present the `package.json` that comes with Ranvier the suggested approach is the following:

1. Inside your bundle folder run `npm init` and fill out the appropriate fields
3. Now you can safely run `npm install --save some-3rd-party-package` while inside your bundle and that dependency will
   available inside the code of your bundle.

## Working in a bundle

For a normal folder bundle you can edit/commit following your normal workflow.

If you are working in a submodule bundle you will need a cursory understanding of how git submodules work. The official
git submodule guide is a good reference for this:
[https://git-scm.com/book/en/v2/Git-Tools-Submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules#_working_on_a_project_with_submodules).
If you installed someone else's shared bundle, for example `progressive-respawn` or one of the example bundles, and you
wish to make changes the suggested approach is to remove the original bundle, fork that repository, and add your fork
as the bundle. If you make and commit changes without forking you will likely not be able to push them to that remote,
as such you will not be able to carry your changes with you if you clone your project onto another server.

## Next steps

Now that you know how to install/create a bundle and enable it the next step is actually building your game.

If you are making your game from scratch, or have only installed a networking bundle follow the [From Scratch](from_scratch.md) guide.

If you used the starter kit mentioned in the [Get Started](../get_started.md) guide you can go directly to the
individual guides. The documentation is split into two parts: Building and Coding.

* Building is for... builders: the people creating areas, npcs, items, etc. Little to no programming experience is needed.
* Coding is for... coders: the people creating new commands, skills, effects, etc.

There is some overlap between the two; for example a coder will need to create the attribute definition for a builder to
use that attribute on an NPC, or for a builder to create a quest a coder may need to create the goal and reward types
for them to use. These may, in fact, be the same person but the guides arer separated to illustrate which bundle content
is stored in pure data and which is in Javascript files.
