# GGB Meal Prep Publishing Pipeline

https://utaschulz1.github.io/GGB-pipeline/

A local publishing pipeline that turns Markdown recipe and meal plan files into a
website, a PDF, and an EPUB — in multiple languages.

Built on top of [Lantern](https://github.com/nulib-oer/lantern) by Northwestern
University Libraries. The shell skeleton and utility functions are Lantern's; the
build logic for multi-plan, multi-language, two-pass PDF/EPUB generation and the
HTML frontend is custom.

---

## What it does

You write meal plans and recipes in Markdown. Running a single command produces:

- **A website** — a home page with image slider, individual plan and recipe pages,
  light/dark mode, hamburger navigation, and a language switcher
- **A PDF** — print-ready, with a cover image, table of contents, recipe metadata
  bar (prep time, cook time, servings), and ingredient tables
- **An EPUB** — e-reader compatible, with the same structure as the PDF

All outputs are multilingual. Adding a new language means adding a folder of
translated files and a metadata file — the build system picks it up automatically.

---

## Content structure

```
text/
  en/
    plans/               ← one .md file per meal plan
    recipes/             ← one .md file per recipe
    general-instructions/← instructions shared across plans
  de/
    plans/
    recipes/
    general-instructions/

images/                  ← recipe photos, slider images

settings/
  build.yml              ← which language and plans to build
  metadata.en.yml        ← publication title, author, description (English)
  metadata.de.yml        ← same for German
  config.yml             ← TOC title, download links for homepage
  pdf.yml                ← PDF build settings
  epub.yml               ← EPUB build settings
  html.yml               ← HTML build settings
```

### Plan files

Each plan file (`text/en/plans/my-plan.md`) has a YAML frontmatter block that
controls what gets built:

```yaml
---
title: "My Meal Plan"
cover-image: "images/my-cover.jpg"
included_recipes:
  - recipe-slug-one
  - recipe-slug-two
---
```

`included_recipes` lists the recipe file slugs (filenames without `.md`) in the
order they should appear in the PDF and EPUB.

### Recipe files

Each recipe file (`text/en/recipes/my-recipe.md`) has frontmatter for the
metadata bar shown in the PDF:

```yaml
---
title: "My Recipe"
category: "Dinner"
prep_time: "15 min"
cook_time: "30 min"
servings: 4
kcal_per_serving: 550
image: "images/my-recipe/photo.jpg"
---
```

---

## Build commands

```bash
bash lantern.sh               # builds HTML + PDF + EPUB (default language from build.yml)
bash lantern.sh html          # HTML only, default language
bash lantern.sh html de       # HTML only, German
bash lantern.sh de            # builds HTML + PDF + EPUB in de
bash lantern.sh pdf           # PDF only, default language
bash lantern.sh pdf de        # PDF only, German
bash lantern.sh epub          # EPUB only
bash lantern.sh reset         # delete all build output and start fresh
```

Output goes to `public/en/` or `public/de/` depending on the language.

To change the default build language, edit `settings/build.yml`:

```yaml
language: en   # change to 'de' to default to German
plans:
  - 00_GGB-starter-week
```

---

## Requirements

- **[Pandoc](https://pandoc.org/installing.html)** — the document converter at
  the heart of everything
- **[WeasyPrint](https://weasyprint.org)** — for PDF generation
  (install with `pip install weasyprint`, ideally in a virtual environment)
- **Python 3** — used by WeasyPrint and by the build script's YAML parsing helpers

To set up a Python virtual environment for WeasyPrint:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install weasyprint
```

Activate the environment before running PDF builds:

```bash
source .venv/bin/activate
bash lantern.sh pdf
```

---

## Adding a new language

1. Create `text/<lang>/plans/`, `text/<lang>/recipes/`,
   `text/<lang>/general-instructions/` with translated files
2. Add `language: <lang>` to the YAML frontmatter of every recipe file in that
   language (e.g. `language: fr`). This is what the recipe metadata bar uses to
   select the correct labels (Prep, Cook, Servings).
3. Add a labels entry for the new language in `lib/lua/recipe-metadata.lua`:
   ```lua
   fr = { prep = "Préparation", cook = "Cuisson", servings = "Portions", kcal = "kcal/portion" },
   ```
4. Create `settings/metadata.<lang>.yml` with translated title, subtitle, and
   description (copy `settings/metadata.en.yml` as a starting point)
5. Run `bash lantern.sh <lang>` to build all formats for that language

If a language code has no entry in `recipe-metadata.lua`, the bar falls back to
English labels silently — so the build won't break, just the labels will be wrong.

---

## Publishing to GitHub Pages

The `public/` folder is excluded from the main branch by `.gitignore` — source
files are what you version-control, not build output. To publish, push to a
separate `gh-pages` branch.

The layout is: **English at the root**, German in a `de/` subfolder. The
language switcher uses absolute URLs based on `siteurl` in `lantern.sh`, so
it always points to the right place regardless of which page you're on.

```bash
# Build both languages
bash lantern.sh
bash lantern.sh de

# Assemble gh-pages content in a temp folder
mkdir -p _ghpages/de
cp -r public/en/. _ghpages/
cp -r public/de/. _ghpages/de/

# Push to gh-pages
cd _ghpages
git init
git add -A
git commit -m "Publish"
git push --force https://github.com/YOUR_USERNAME/YOUR_REPO.git HEAD:gh-pages
cd ..
rm -rf _ghpages
```

Then in GitHub go to **Settings → Pages** → source: `gh-pages` branch, root folder.

> The language switcher uses absolute URLs from the `siteurl` variable in
> `lantern.sh`. Update it if you rename your repo or move to a custom domain.

---

## License

**Content** (text, recipes, meal plans, images) — © Uta Schulz. All rights
reserved. Not licensed for unaltered redistribution. Only for cooking.

**Code** (scripts, templates, stylesheets, build system) — MIT License, following
the license of the upstream [Lantern](https://github.com/nulib-oer/lantern)
project from Northwestern University Libraries.
