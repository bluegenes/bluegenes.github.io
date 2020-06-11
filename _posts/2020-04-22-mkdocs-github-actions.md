---
title: Deploying Mkdocs via Github Actions
date: 2020-04-22
authors: 
  - N. Tessa Pierce
comments: true
---

I need to edit some documentation for our workflow projects [dammit](https://dib-lab.github.io/dammit) and [elvers](https://dib-lab.github.io/elvers). These docs are set up in [mkdocs](https://www.mkdocs.org), which I love for it's simplicity: I can write all my documentation in markdown, and mkdocs will take care of formatting and building html for web display. Thanks to Charles Reid for getting the lab on mkdocs a few years ago and for building us a [custom
theme](https://github.com/dib-lab/mkdocs-material-dib) back in 2018!

`GitHub Actions` can now be used to automate the manual part of building and deploying `mkdocs` documentation: time to set this up.

Looks like we can start from [GitHub Actions for GitHub Pages](https://github.com/peaceiris/actions-gh-pages). Since dammit and elvers are both project repositories, I'll just go through the `project` instructions.

First, add a workflow file: `.github/workflows/gh-pages.yml` that contains the build and deploy instructions.

This particular file works with the [material theme](https://github.com/squidfunk/mkdocs-material):

```
name: build and deploy mkdocs to github pages
on:
  push:
    branches:
      - master
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
        with:
          submodules: "recursive" 
          fetch-depth: 0       # Fetch all history for .GitInfo and .Lastmod
      - name: Setup Python
        uses: actions/setup-python@v1
        with:
          python-version: '3.7'
          architecture: 'x64'
      - name: Install dependencies
        run: |
          python3 -m pip install --upgrade pip     # install pip
          python3 -m pip install mkdocs            # install mkdocs 
          python3 -m pip install mkdocs-material   # install material theme
      - name: Build site
        run: mkdocs build
      - name: Deploy
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./site
```

Commit, push, and watch the magic happen. Commit a change to your documentation to double check that your site builds properly. 

And... Done! Wow, I really thought there would be more to this - happy to report that something that went _faster_ than expected.


## References and Links

The gh-actions file (containing the code above) can be found [here](https://github.com/dib-lab/dammit/blob/master/.github/workflows/gh-pages.yml); the site builds to `http://dib-lab.github.io/dammit`.


The `mkdocs.yml` file for the documentation website is [here](https://github.com/dib-lab/dammit/blob/master/mkdocs.yml), also reproduced below:

```
site_name: dammit
site_url: http://dib-lab.github.io/dammit
repo_name: dammit
repo_url: https://github.com/dib-lab/dammit
edit_uri: ""

copyright: 'Copyright &copy; 2020 <a href="http://ivory.idyll.org/lab/">Lab for Data Intensive Biology</a> at UC Davis'

# change directory names here
docs_dir: doc
site_dir: site

theme:
  name: material

  # pretty colors! see https://squidfunk.github.io/mkdocs-material/getting-started/#primary-colors
  palette:
    primary: 'green'
    accent: 'purple'
  
  # fun logos! see https://material.io/icons/
  icon:
    logo: material/dns

  font:
    text: 'Roboto'
    code: 'Roboto Mono'

# give a title for each page
nav:
  - 'Home': 'index.md'
  - 'About': 'about.md'
  - 'Installation':
    - 'Requirements': 'system_requirements.md'
    - 'Bioconda': 'install.md'
  - 'Databases':
    - 'Basic Usage': 'database-usage.md'
    - 'About the Databases': 'database-about.md'
    - 'Advanced Database Handling': 'database-advanced.md'
  - 'Tutorial': 'tutorial.md'
  - 'For developers':
    - 'Notes for developers': 'dev_notes.md'
```

