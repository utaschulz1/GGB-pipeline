# Testing the Output

There is no automated test suite. Testing is done by building and inspecting the
output visually and structurally. This document describes what to check and how.

---

## Local development server (HTML)

The fastest way to check the HTML output is a local web server. Python 3 has one
built in:

```bash
bash lantern.sh html
cd public/en
python3 -m http.server 8000
```

Then open `http://localhost:8000` in a browser. Rebuild and reload to see changes.

Alternatively, the built-in `server` command does this in one step (opens the /public folder for all languages,
no language argument):

```bash
bash lantern.sh server
```

> VS Code's Live Server extension also works — right-click `public/en/index.html`
> and choose "Open with Live Server".

---

## What to check after an HTML build

**Homepage (`index.html`)**
- [ ] Title and subtitle match `settings/metadata.<lang>.yml`
- [ ] Image slider loads and advances with arrow buttons
- [ ] Light/dark mode toggle works and persists when navigating to another page
- [ ] Chapter list in TOC shows correct order: plan → general instructions → recipes
- [ ] Hamburger menu opens and shows the same list
- [ ] Language switcher links are present (may 404 if other language not built yet)
- [ ] Download buttons in the "Read" block point to existing PDF/EPUB files

**Plan page**
- [ ] Plan title and content render correctly
- [ ] Shopping list table is formatted with right-aligned quantities
- [ ] Recipe links in the "Recipes in this plan" section resolve (or are plain text)
- [ ] Sidebar shows chapter list

**Recipe pages**
- [ ] Recipe metadata bar shows prep time, cook time, servings, kcal
- [ ] Recipe image loads
- [ ] Ingredient table is formatted correctly (quantity right-aligned, ingredient left-aligned)
- [ ] Instructions render as numbered list

**General instructions page**
- [ ] Page exists and is linked from the sidebar
- [ ] Content is readable

---

## What to check after a PDF build

Open `public/en/<plan-slug>.pdf` in a PDF viewer.

- [ ] Cover image appears on the title page
- [ ] Title, subtitle, and author are correct
- [ ] Table of contents is present and entries are correct
- [ ] Plan content appears first, then general instructions, then recipes
- [ ] Recipe titles are h2 (not h1) — they appear as subsections under the plan
- [ ] Recipe metadata bar (prep/cook/servings) appears under each recipe title
- [ ] Recipe image appears
- [ ] Ingredient table columns are correctly aligned
- [ ] Page breaks occur before each recipe title (not mid-paragraph)
- [ ] Running header in the top margin shows the current recipe title
- [ ] Internal links in the recipe list (if present) do not cause errors

**WeasyPrint warnings** — the following are harmless and can be ignored:
```
WARNING: Ignored `gap: min(4vw, 1.5em)` — Pico CSS uses a CSS function WeasyPrint doesn't support
WARNING: Ignored `overflow-x: auto` — screen-only property
ERROR: No anchor #... for internal URI reference — a broken internal link in the source
```

The PDF is generated even if these warnings appear.

---

## What to check after an EPUB build

Open `public/en/<plan-slug>.epub` in an e-reader or EPUB validator.

**Quick check with an e-reader:**
- Calibre (desktop) — drag and drop the `.epub` file
- Moon Reader (Android) — copy file to device
- VS Code EPUB viewer extension — right-click the file

**What to look for:**
- [ ] Cover image appears
- [ ] Chapter navigation works
- [ ] Recipe metadata bar is visible
- [ ] Ingredient tables render (font size may vary by reader)
- [ ] Links use the page text color (not bright blue — `currentColor` in epub.css)
- [ ] No broken images

**EPUB validation (optional):**

```bash
# Install epubcheck (requires Java)
epubcheck public/en/00_GGB-starter-week.epub
```

The EPUB is EPUB3 format. Some validators will flag WeasyPrint-generated EPUBs
for minor spec deviations that don't affect reading.

---

## Checking the intermediate files (debugging)

If something looks wrong in the PDF or EPUB, inspect the Pass 1 output in
`_temp/build/<plan-slug>/`. These are the preprocessed Markdown files before
they are combined.

```bash
bash lantern.sh pdf
ls _temp/build/00_GGB-starter-week/
# 01_plan.md
# 10_01_general_instructions.md
# 20_chapter-intro.md
# 21_00_chili_sin_carne.md
# 21_01_green-dhal.md
# 21_02_spicy-sweet-potato-with-berries-and-beans.md
```

Open any of these files to check:
- The recipe metadata bar HTML was injected correctly after the heading
- Headings are at the right level (h2 for recipes, h1 for plan)
- The `recipe-title` class is on the recipe heading

To see full Pandoc output including all warnings, change the top of `lantern.sh`:

```bash
pandoc_command='pandoc --verbose'
```

---

## Rebuilding cleanly

If the output looks stale or something seems wrong from a previous build:

```bash
bash lantern.sh reset
bash lantern.sh
```

`reset` deletes `public/` and `_temp/` entirely. The next build starts from scratch.

---

## Checking both languages

```bash
bash lantern.sh        # builds public/en/
bash lantern.sh de     # builds public/de/

# Serve both at once on different ports
cd public/en && python3 -m http.server 8000 &
cd public/de && python3 -m http.server 8001 &
```

Check that:
- [ ] Titles and descriptions are in the correct language
- [ ] Recipe content is translated
- [ ] Metadata bar labels (Prep, Cook, Servings)
