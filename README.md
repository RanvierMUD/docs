Docs for the Ranvier game engine.

## Building

You will need a directory like the following:

```
docs/ # this repo
core/ # the core repo
site/ # docs build goes here, should target this dir to serve
```

Additionally you'll need to install mkdocs and the required deps. You'll need Python 2.7.x and `pip`

From the docs directory run

```
pip install -r docs/_mkdocs/requirements.txt
pip install mkdocs==0.17.3
touch docs/{index,contributing}.md
```

Finally run `./build.sh`

## Serving

If you are using a webserver to serve the site dir described above. To serve locally run `mkdocs serve`
which will start a temporary webserver on `localhost:8000`
