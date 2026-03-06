# Pipeline Architecture

## Overview

The pipeline converts Markdown source files into three output formats — HTML
(website), PDF, and EPUB — in multiple languages. Everything is orchestrated by
`lantern.sh`, a bash script that calls Pandoc with different settings depending
on the target format.

```
text/en/plans/*.md          ┐
text/en/recipes/*.md        ├─► lantern.sh ─► public/en/  (HTML, PDF, EPUB)
text/en/general-instructions/*.md  ┘
text/de/...                 ────────────────► public/de/  (HTML, PDF, EPUB)
```

---

## The Two-Pass Build (PDF and EPUB)

HTML pages are built one file at a time — each Markdown file becomes one HTML
page independently. PDF and EPUB are different: all content for a plan must be
combined into a single document before Pandoc can generate the output.

The challenge is that Pandoc's Lua filters read per-file YAML frontmatter to
inject recipe metadata (prep time, servings, image, etc.). Once files are
concatenated, all that per-file YAML is gone.

The solution is a **two-pass build**:

### Pass 1 — Preprocess each file individually

Each file is run through Pandoc alone, so its YAML frontmatter is visible to the
Lua filter. The output is an intermediate Markdown file written to `_temp/build/<plan_slug>/`.

Files are numbered by type to control assembly order:

| Prefix | Content |
|--------|---------|
| `01_plan.md` | The plan file |
| `10_NN_<name>.md` | General instructions |
| `20_chapter-intro.md` | Recipe chapter intro |
| `21_NN_<slug>.md` | Individual recipes |

Recipes are also heading-shifted by +1 during Pass 1 (`--shift-heading-level-by=1`),
so recipe `# Title` (h1) becomes `## Title` (h2) in the combined document —
preserving the plan's h1 as the top-level heading.

### Pass 2 — Combine and generate final output

The numbered intermediate files are sorted and fed to Pandoc in one call with
`--defaults settings/pdf.yml` (or `epub.yml`). At this point, per-file metadata
has already been baked into the content by the Lua filter in Pass 1, so the
final Pandoc call only needs publication-level metadata (title, author) and
format settings.

```
_temp/build/my-plan/
  01_plan.md
  10_01_general_instructions.md
  20_chapter-intro.md
  21_00_chili_sin_carne.md
  21_01_green-dhal.md
  21_02_spicy-sweet-potato.md
        │
        ▼ Pass 2 (single Pandoc call)
  public/en/my-plan.pdf
```

---

## Lua Filters

Lua filters run inside Pandoc and manipulate the document AST (abstract syntax
tree) before output is written. They are the mechanism for injecting structured
content that Pandoc's template system can't handle on its own.

### `recipe-metadata.lua`

The main filter. Runs during Pass 1 on each individual recipe file.

**What it does:**
1. Reads YAML frontmatter fields: `prep_time`, `cook_time`, `servings`,
   `kcal_per_serving`, `image`
2. Builds a `<div class="recipe-meta">` bar with spans for each field
3. If an `image` field exists, builds a `<figure class="recipe-image">` block
4. Finds the first heading in the document and stamps it with class `recipe-title`
   (so CSS can style recipe titles differently from section headings even after
   heading levels are shifted)
5. Inserts the meta bar and image block immediately after that first heading

This filter is safe to run on non-recipe files (plan files, general instructions)
— it silently skips documents that don't have the recipe frontmatter fields.

### `cover-image.lua`

PDF-only. Runs during Pass 2.

Reads the `cover-image` metadata field (passed via `--metadata cover-image=...`
from `build_output()`) and injects an inline `<style>` block that sets the image
as the CSS background of `#title-block-header` — the element Pandoc generates
for the document title page.

### `questions.lua` and `siteurl.lua`

HTML-only (referenced in `settings/html.yml`). These are inherited from the
upstream Lantern project and handle Q&A-style content blocks and site URL
injection respectively.

---

## Config Structure

### `settings/build.yml`

Controls which language and which plans are built by default.

```yaml
language: en
plans:
  - 00_GGB-starter-week
```

`language` determines the default for `bash lantern.sh` with no arguments.
`plans` lists the plan slugs (filenames without `.md`) to build. Each plan is
built into its own PDF and EPUB file.

### `settings/metadata.<lang>.yml`

Publication-level metadata for the homepage and PDF/EPUB title page. One file
per language. Contains title, subtitle, author, description, keywords. Does
**not** contain cover images (those live in plan frontmatter) or geometry
(not used with WeasyPrint).

### `settings/config.yml`

Homepage-specific settings: `toc-title` and the `download:` list of buttons
shown on the homepage. Not passed to PDF or EPUB builds.

### `settings/pdf.yml`, `epub.yml`, `html.yml`

Pandoc defaults files for each format. Specify: input/output format, PDF engine
(`weasyprint`), Lua filters, CSS files, TOC settings, and format-specific
options. **Do not** hardcode metadata file paths — those are passed at runtime
by `lantern.sh` so they can be language-aware.

---

## CSS — Which File Does What

| File | Loaded by | Purpose |
|------|-----------|---------|
| `pico.min.css` | HTML only | Base CSS framework (Pico). Provides typography, forms, layout primitives, and `data-theme` dark/light mode. |
| `theme.css` | HTML only | CSS custom property overrides for GGB brand colors on top of Pico. |
| `theme-switcher.css` | HTML only | Styles the fixed top bar (dark background), sun/moon icons, HOME link, language switch, and hamburger button. |
| `menu.css` | HTML only | Styles the slide-in sidebar navigation (`<aside>`), hamburger button toggle, and nav links. |
| `home.css` | Homepage only | Styles the image slider, title card, TOC block, and details/summary elements on the home page. |
| `screen.css` | HTML only | Main content area layout: page padding, heading styles, content width, spacing. |
| `recipe.css` | HTML + PDF + EPUB | Shared styles that must look consistent across all formats: recipe meta bar, recipe image, ingredient tables (`.shopping-list`, `.sl-category`), `recipe-title` heading class. |
| `print.css` | PDF only | CSS Paged Media rules for WeasyPrint: `@page` margins, page breaks on h1, running headers via `string-set`, print-specific table sizing and link styling. |
| `epub.css` | EPUB only | E-reader safe styles. Similar to `recipe.css` but avoids properties that e-readers ignore or override. Uses `color: currentColor` for links. |

### Why `recipe.css` is shared

The ingredient tables and recipe metadata bar must render correctly in all three
formats. Putting those rules in `recipe.css` and loading it everywhere avoids
duplicating the same CSS across `screen.css`, `print.css`, and `epub.css`.

---

## Language Handling

Language flows through the whole pipeline:

1. Default language is read from `settings/build.yml` → `language`
2. `bash lantern.sh de` or `bash lantern.sh html de` overrides it
3. Source files are read from `text/<lang>/...`
4. Outputs go to `public/<lang>/...`
5. Publication metadata is loaded from `settings/metadata.<lang>.yml`, falling
   back to `settings/metadata.en.yml` if no language-specific file exists
6. Assets (CSS, JS, images) are copied into each language output directory so
   relative paths work correctly from `public/<lang>/index.html`

### Adding a new language

1. Create `text/<lang>/plans/`, `text/<lang>/recipes/`, and
   `text/<lang>/general-instructions/` with translated content files.
2. Add `language: <lang>` to the YAML frontmatter of every recipe file. This
   field is read by `recipe-metadata.lua` to select the correct labels for the
   metadata bar (Prep, Cook, Servings, kcal).
3. Add a labels entry to `lib/lua/recipe-metadata.lua`:
   ```lua
   local labels = {
     en = { prep = "Prep", cook = "Cook", servings = "Servings", kcal = "kcal/serving" },
     de = { prep = "Vorbereitung", cook = "Kochzeit", servings = "Portionen", kcal = "kcal/Portion" },
     fr = { prep = "Préparation", cook = "Cuisson", servings = "Portions", kcal = "kcal/portion" },
   }
   ```
   If no entry exists for a language code, the filter silently falls back to
   English — the build won't break, but labels will be in English.
4. Create `settings/metadata.<lang>.yml` (copy `metadata.en.yml` as a template)
   with the translated publication title, subtitle, and description.
5. Build: `bash lantern.sh <lang>` (builds HTML + PDF + EPUB for that language)
