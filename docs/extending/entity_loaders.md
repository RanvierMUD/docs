Ranvier does not lock you down to storing your data in a specific way. Each entity in the game can be customized to be
loaded from a difference source. For example, the default Ranvier setup is to load areas from YAML files and
account/player data from JSON files. Suppose you wanted to store your areas in a Sqlite database and your account/player
data in a PostgreSQL database; that's where the Data and Entity Source system comes in.

Before data is loaded in Ranvier there are two pieces that fit together: a `DataSource` and an `EntityLoader`.

* a `DataSource` is a class which is used to actually connect to a source of data and retrieve records. Each configured
  `DataSource` is created once and shared among each `EntityLoader` configured to use it
* an `EntityLoader` connects a `DataSource` to a specific entity in the engine like NPCs, items, or accounts

First we'll cover how to configure a `DataSource` and `EntityLoader`, then we'll cover the creation of a new
`DataSource`, finally how one uses an `EntityLoader` in their code to, well, load entities.

[TOC]

## Configuration

Configuration of DataSources and EntityLoaders is done in the `ranvier.json` file in the root of the project. As
mentioned the default Ranvier setup is to load areas from YAML so we'll use that as our example:

```js
{
  // ...

  // the `dataSources` key is where we will register the sources available to use
  // for the entity loaders
  "dataSources": {
    // the key here names the DataSource for use in an EntityLoader
    "Yaml": {
      /*
      'require' specifies which file or package to require. It will follow the
      same API as the node require() method, which is to say you could either
      have the class locally or it could be from a node module.  If a node
      module exports more than one data source you may specify which export to
      use with <module>.<object>
      */
      "require": "ranvier-datasource-file.YamlDataSource",
      /*
      A require from a local file may look like:
      "require": "./lib/path/to/MyDataSource.js"
      */

      /* An arbitrary config passed to the DataSource constructor.  Each
      DataSorce might have a different config: file paths, database details, etc. */
      "config": {
        "bundlePath": "bundles",
      }
    }
  },

  "entityLoaders": {
    /* The keys here will be a specific list of game entities which the
    BundleManager will use to load data. However, you may also add additional
    entities if you have a bundle with some custom data like a vendor's
    product list or loot tables */
    "items": {
      /* specifies which registered DataSource to use */ 
      "source": "Yaml",
      /* Additional configuration for the datasource specific to this entity.
      Each `DataSource` may have have a different entity config such as a
      table name or, in this case, a file name. Refer to the documentation
      for that DataSource */
      "config": {
        "path": "items.yml",
      },
    },
  },
}
```

## Required EntityLoaders

The engine requires that you define entity loaders for the following keys: `accounts`, `players`, `areas`, `npcs`,
`items`, `rooms`, `quests`, and `help`. You may use whichever `DataSource` you like for each loader. However, the data
returned from the sources is expected to be of a certain type:

* `fetchAll()` for `npcs`, `items`, `rooms`, and `quests` should return an `Array` of objects. For the
  specific data in each object see the corresponding guide in the Building section of the documentation.
* `fetchAll()` for `accounts`, `players`, and `help` should return an `Object`, with each key representing their
  respective entity by id.

## Creating a new DataSource

A `DataSource` is simply a Javascript class that has specific methods; how you implement those methods is ultimately up
to you as long as the methods take the correct parameters and return the correct values from the methods.

```js
class ExampleDataSource {
  /**
   * The constructor of the DataSource takes two parameters:
   *   config: the value of 'config' from the `dataSources` configuration in
   *           ranvier.json
   *
   *   rootPath: A string representing the project root directory (the same
   *             directory that contains ranvier.json)
   */
  constructor(config = {}, rootPath) {
    this.config = config;
    this.root = rootPath;

    // this is not required, this is only for our example data source
    this._records = [
      { id: 1, foo: "bar" },
    ];
  }

  /*
  The first parameter of each method from here on will be the config defined in
  the the 'entityLoaders' entry. For example:

    "entityLoaders": {
      "items": {
        "source": "Yaml",
        "config": {
          "path": "foo.yml"
        },
      }
    }

    `config` would equal `{ path: "foo.yml" }`

    Each method also returns a `Promise`
  */

  /**
   * This is the only required method of a DataSource, all others are optional
   * but not implementing them will obviously limit its funtionality.
   *
   * Returns whether or not there is data for a given config. In the case of the
   * YamlDataSource this would be whether or not the configured file exists
   *
   * @param {object} config
   * @return {Promise<boolean>}
   */
  hasData(config = {}) {
    return Promise.resolve(true);
  }

  /**
   * Returns all entries for a given config.
   * @param {object} config
   * @return {Promise<any>}
   */
  fetchAll(config = {}) {
    return Promise.resolve(this._records);
  }

  /**
   * Gets a specific record by id for a given config
   * @param {Object} config
   * @param {string} id
   * @return {Promise<any>}
   */
  async fetch(config = {}, id) {
    const records = await this.fetchAll(config);

    if (!records.hasOwnProperty(id)) {
      throw new ReferenceError(`Record with id [${id}] not found.`);
    }

    return records[id];
  }

  /**
   * Perform a full replace of all data for a given config. This is the write
   * version of fetchAll
   * @param {Object} config
   * @param {any} data
   * @return {Promise}
   */
  replace(config = {}, data) {
    this._records = data;
    return Promise.resolve();
  }

  /**
   * Update specific record. Write version of `fetch`
   * @param {Object} config
   * @param {string} id
   * @param {any} data
   * @return {Promise}
   */
  update(config = {}, id, data) {
    this._records[id] = data;
    return Promise.resolve();
  }
}
```

As mentioned in the configuration section this class can either be local to your project or it can be part of a node
module, however you want to distribute it is up to you.

For a real-life implementation see [ranvier-datasource-file](https://github.com/RanvierMUD/datasource-file)

## Using an EntityLoader

Taking the example configuration from the start we have one `EntityLoader` defined: items. To use an `EntityLoader` you
retrieve it from the `EntityLoaderRegistry` from `state`:

```js
const itemsLoader = state.EntityLoaderRegistry.get('items');

/*
We don't have to pass a config to any of the EntityLoader methods because we
already defined that in the ranvier.json file
*/
const haveItems = await itemsLoader.hasData();

if (!haveItems) {
  return;
}

const items = itemsLoader.fetchAll();

for (const item of items) {
  console.log(item);
}
```

For a real life example of using a custom `EntityLoader` for your bundle see the
[lootable-npcs](https://github.com/RanvierMUD/lootable-npcs) bundle.
