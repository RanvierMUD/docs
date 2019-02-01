## Version 3: The Great Divide

Version 3 brings the biggest changes to the engine since its complete rewrite a bit over 2 years ago. There have been major changes not only to the engine in the form of features and bugfixes but also the project structure and the entire Ranvier ecosystem.

[TOC]

### Structure

To start, all things Ranvier now exist under a new [Ranvier](https://github.com/ranviermud) Github organization. This was necessary because the `ranviermud` repo has been hit with a big ol' axe and split into three main repos:

* `ranviermud` still acts as the "main" repository. If you want to use Ranvier, this is the repo you clone. It contains the skeleton of the project structure necessary to use the Ranvier engine. Think of it like the "starter kit" for using the core.
* `core` is the engine itself, whose code is no longer part of the `ranviermud` repository. Instead it is included as an NPM dependency
* `docs` now live in their own repo as well as being part of a nice new deployment runway that really only I care about. The docs being in their own repo makes it much easier for people to contribute doc changes if they are not programmers as they don't have to dig through code or setup the original project anymore

This split greatly lessens the considerable effort it took to merge in engine updates while simultaneously working on your game inside the `ranviermud` repo. Previously this required a very annoying dance involving rebasing, merging, and resolving sometimes dozens of conflicts. Now it's a simple `npm update`

Taking things a step further all the bundles previously included in the `ranviermud` repo have each been split into their own repository for the same reasons. The bundle installation and management strategy going forward is now handled through git submodules by default. Git submodules are a little tricky but best fit our project's needs for including subprojects while still allowing for modifying their code or receiving upstream updates. As always there are thorough docs on the new process.

Overall the new project structure, while very different, is much friendlier experience both from a version control perspective and this split allows for Ranvier code to be much cleaner and simpler as well.


### Major Features

#### Entity Loaders

The largest change in version 3, hands down, is the new entity loader system. Ranvier no longer locks you down into storing game data in YAML and/or JSON. You are now free to store/load your entities and account/player data in MySQL or Postgres or a CSV or any type of storage system you want. Each entity in the game can be customized to be loaded from a difference source; maybe you want to store game entities in JSON but account/player data in a database. Entity loaders are similar to the `TransportStream` adapter system released in version 2 which allowed you to customize the networking layer, in that it allows you to write simple adapter classes to customize the data layer.

#### New Script Structure

Because the core engine is now part of NPM the structure of script files is much simpler.

**Before**

```js
module.exports = (srcPath) => {
  const Broadcast = require(srcPath + 'Broadcast');
  const Logger = require(srcPath + 'Logger');

  return { /* some object */ };
};
```

**After**

```js
const { Broadcast, Logger } = require('ranvier');

module.exports = { /* some object */ };
```

For backwards compatibility the old format is still supported.

#### Room coordinates

Rooms in Ranvier now support having an optional 3D coordinate. This allows you to have areas in Euclidian space. The coordinates for a room are local to its area, rather than global to the entire game. This allows for builders of different areas to freely layout their area without having to worry about conflicts. You are still free to link any room to any other directly by id with an arbitrary exit name for maximum flexibility.

#### Attributes overhaul

Ranvier now supports computed attributes. From the very basic stats such as "mana is intelligence * 10" to the very complex "armor is the (greater of strength * 2 or dex * 2) + a racial bonus". The new system also allows for nested computed property, i.e., a computed property that relies on a computed property. This also allows for having percentage based bonuses.

#### Quest system overhaul

Quests no longer require builders to write code to create quests. The new system allows for builders to compose configurable `Goal` and `Reward` types created by coders to create exactly the workflow and rewards they want for the player.

#### Scriptable Areas

Areas, now joining the rest of the entities in the game, can have behaviors and/or a script. As part of this the core engine no longer has any concept of respawn. This has been moved under the control of bundles. This allows you to write the respawn system you want, even having different areas use different techniques.

#### Scriptable Channels

You can now hook into the usage of channels as well as the output of channels in your scripts.
