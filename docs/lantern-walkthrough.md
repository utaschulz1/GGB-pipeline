# lantern.sh — Code Walkthrough

`lantern.sh` is the build orchestrator. It defines all build functions and
dispatches to them based on command-line arguments. It does not do any
conversion itself — everything is delegated to Pandoc.

---

## Top-level variables

```bash
output_filename='ggb-starter-plan'   # used by legacy docx/markdown functions
output_directory='public'            # all output goes here
siteurl=''                           # injected into HTML pages as metadata
pandoc_command='pandoc --quiet'      # change to --verbose to see all warnings
```

---

## `output_formats()`

```bash
output_formats() {
    html
    pdf
    epub
}
```

Called when `bash lantern.sh` runs with no arguments. Lists which formats to
build by default. Comment out lines here to skip a format.

---

## `convert()`

Converts original manuscript files (`.docx`, `.odt`, `.tex`) from the `original/`
folder to Markdown and moves them into `text/`. A one-time utility — not called
in the default build. Run manually with `bash lantern.sh convert`.

---

## Python helper functions

Three functions use embedded Python 3 scripts (heredoc `<< 'PYEOF'`) to parse
YAML without requiring PyYAML or any external dependency.

### `_parse_build_yml <field>`

Reads `settings/build.yml` and prints either the `language` value or each
entry in the `plans` list (one per line). Falls back to `en` if the file
doesn't exist.

Used by `build_output()` to know which language and which plans to build.

### `_get_plan_field <file> <field>`

Reads the YAML frontmatter of a plan file and prints the value of a single
scalar field. Used to extract `cover-image` per plan.

### `_get_included_recipes <file>`

Reads the `included_recipes` list from a plan's YAML frontmatter and prints
each slug on a separate line. Used by `build_output()` to know which recipe
files to include and in what order.

---

## `build_output <format> [lang]`

The core of the PDF and EPUB pipeline. Called by `pdf()` and `epub()`.

**Arguments:**
- `format` — `pdf` or `epub`
- `lang` — optional language override; defaults to value from `build.yml`

**Step by step:**

```
1. Resolve language → set $lang and $lang_dir (e.g. public/en/)
2. Read plan slugs from build.yml (via _parse_build_yml plans)
3. For each plan slug:
   a. Find plan file at text/$lang/plans/<slug>.md
   b. Read included recipe slugs (via _get_included_recipes)
   c. Create isolated temp dir: _temp/build/<slug>/
   d. Pass 1 — preprocess each section:
      - 01_plan.md          ← plan file, no heading shift
      - 10_NN_*.md          ← general instructions, no heading shift
      - 20_chapter-intro.md ← recipe intro page, no heading shift
      - 21_NN_<slug>.md     ← each recipe, +1 heading shift
   e. Sort temp files and collect into array
   f. Extract cover-image from plan frontmatter
   g. Pass 2 — single Pandoc call:
      - Input: all temp .md files in order
      - --defaults settings/<format>.yml
      - --metadata-file settings/metadata.<lang>.yml
      - --metadata cover-image=... (PDF) or --epub-cover-image=... (EPUB)
      - Output: public/<lang>/<slug>.<format>
```

**Why the isolated temp dir per plan?**
Each plan gets `_temp/build/<plan_slug>/` wiped and recreated. This prevents
files from a previous plan build leaking into the next one when multiple plans
are built in sequence.

**Why sort the temp files?**
The numeric prefixes (`01_`, `10_`, `20_`, `21_`) ensure assembly order. The
sort is done by `find ... | sort -z` (null-delimited for filename safety).

---

## `pdf()` and `epub()`

```bash
pdf()  { build_output pdf  "${1:-}"; }
epub() { build_output epub "${1:-}"; }
```

Thin wrappers that pass the format name and optional language override to
`build_output()`.

---

## `copy_assets <dest>`

```bash
copy_assets() {
    local dest="${1:-$output_directory}"
    cp -r images "$dest"
    cp -r lib/css/ "$dest"
    cp -r lib/js/ "$dest"
}
```

Copies the `images/`, `css/`, and `js/` directories into the output directory.
Called with the language-specific output path (e.g. `public/en/`) so that
relative paths from HTML pages resolve correctly.

---

## `extract_metadata <lang>`

Builds one temp file per source document:
- `_temp/<prefix><basename>.metadata.json` — full metadata as JSON, used for
  the chapter list on the homepage and sidebar

Files are written with numeric prefixes to control sort order in
`build_chapter_index()`:

| Prefix | Section |
|--------|---------|
| `01_` | Plans |
| `10_` | General instructions |
| `21_` | Recipes |

Stale files from previous builds are deleted at the start (`rm -f _temp/*.metadata.json`) to prevent wrong ordering when switching languages.

---

## `build_chapter_index()`

Concatenates all `_temp/*.metadata.json` files into a single JSON object:

```json
{ "chapter_list": [ {...}, {...}, {...} ] }
```

Written to `_temp/chapters.json`. This file is passed to every HTML page build
via `--metadata-file _temp/chapters.json`, which makes `$chapter_list$` available
in Pandoc templates — used to render the sidebar nav and homepage TOC.

The alphabetical sort of `*.metadata.json` gives the correct order because of
the `01_` / `10_` / `21_` prefixes added by `extract_metadata()`.

---

## `_build_html_page <file> <out_dir>`

Builds a single HTML page from a Markdown source file. Called for each plan,
general instruction, and recipe file.

Key metadata passed to Pandoc:
- `_temp/chapters.json` → `$chapter_list$` for sidebar
- `settings/metadata.<lang>.yml` → title, author, lang for page `<title>` and `<html lang="">`
- `settings/config.yml` → toc-title, download links
- `chapter_title` → extracted from the file's h1 heading by grep
- `updatedtime` → file modification date (or last git commit date on CI)
- `htmlfile` → the output filename, used for self-referencing in templates

Output goes to `$out_dir/<basename>.html` — all files flat in one directory.

---

## `html <lang>`

Orchestrates the full HTML build:

```
1. Resolve language
2. copy_assets → public/<lang>/
3. extract_metadata → _temp/*.metadata.json, *.category.txt
4. build_chapter_index → _temp/chapters.json
5. _build_html_page for each plan
6. _build_html_page for each general instruction
7. _build_html_page for each recipe (skips 00_chapter-intro.md)
8. Build index.html from _temp/empty.txt + templates/home.html
9. Assemble _temp/search.json and copy to output
```

Recipe files starting with `0` (like `00_chapter-intro.md`) are excluded from
HTML page generation by the glob `[^0]*.md` — the chapter intro only belongs
in the PDF/EPUB document, not as a standalone HTML page.

---

## `reset()`

```bash
reset() {
    rm -rf $output_directory
    rm -rf _temp
}
```

Deletes all build output. Run with `bash lantern.sh reset` before a clean build.

---

## Dispatch logic (bottom of file)

```bash
if [ -z "$1" ]; then
    output_formats          # no args → build all formats

elif [[ "$1" =~ ^[a-z]{2}$ ]] && ! declare -f "$1" > /dev/null 2>&1; then
    html "$1"               # two-letter code (de, fr...) → build all formats
    pdf "$1"                # for that language
    epub "$1"

else
    "$@"                    # anything else → call as function with args
                            # e.g. bash lantern.sh pdf de
                            #      bash lantern.sh html en
                            #      bash lantern.sh reset
fi
```

The `declare -f "$1"` check prevents a two-letter function name (like `en` if
it were ever defined) from being misrouted to the language shorthand path.
