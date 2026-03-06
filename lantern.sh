#!/usr/bin/bash

# custom settings

output_filename='ggb-starter-plan'
output_directory='public'
siteurl=''

output_formats() {
    html
    pdf
    epub
    #docx
}

# utilities

pandoc_command='pandoc --quiet' # change to 'pandoc --verbose' for debugging

# setup

mkdir -p _temp/
mkdir -p $output_directory

# convert manuscript files to markdown

convert() {
    local docx_files=`ls -1 original/*.docx 2>/dev/null | wc -l`
    local odt_files=`ls -1 original/*.odt 2>/dev/null | wc -l`
    local latex_files=`ls -1 original/*.tex 2>/dev/null | wc -l`

    if [ $docx_files != 0 ] ; then 
    for FILE in original/*.docx
        do 
            $pandoc_command "$FILE" \
                --to markdown \
                --wrap=none \
                --extract-media=images \
                --standalone \
                --output "${FILE%.*}.md"
            mv "${FILE%.docx}.md" text
        done
    fi

    if [ $odt_files != 0 ] ; then 
    for FILE in original/*.odt
        do 
            $pandoc_command "$FILE" \
                --to markdown \
                --wrap=none \
                --extract-media=images \
                --standalone \
                --output "${FILE%.*}.md"
            mv "${FILE%.docx}.md" text
        done
    fi

    if [ $latex_files != 0 ] ; then 
    for FILE in original/*.tex
        do 
            $pandoc_command "$FILE" \
                --to markdown \
                --wrap=none \
                --extract-media=images \
                --standalone \
                --output "${FILE%.*}.md"
            mv "${FILE%.docx}.md" text
        done
    fi
}

# ── Config-driven build (PDF / EPUB) ─────────────────────────────────────
#
# settings/build.yml controls: language, plans list.
# Each plan's `included_recipes` frontmatter field lists which recipes to include
# and in what order. Preprocessing is done per-file (Pass 1) so each file's
# YAML is visible to the Lua filter before the files are combined (Pass 2).

# Parse settings/build.yml — field: "language" or "plans" (one per line)
_parse_build_yml() {
    python3 - "$1" << 'PYEOF'
import sys, re
field = sys.argv[1]
try:
    content = open('settings/build.yml').read()
except FileNotFoundError:
    if field == 'language': print('en')
    sys.exit(0)
if field == 'language':
    m = re.search(r'^language:\s*["\']?(\S+?)["\']?\s*$', content, re.MULTILINE)
    if m: print(m.group(1))
elif field == 'plans':
    in_plans = False
    for line in content.splitlines():
        if re.match(r'^plans:', line):
            in_plans = True
        elif in_plans:
            m = re.match(r'^[ \t]+-\s*["\']?(.+?)["\']?\s*$', line)
            if m: print(m.group(1))
            elif line.strip() and line[0] not in (' ', '\t'): break
PYEOF
}

# Extract a single scalar field from a plan file's YAML frontmatter
_get_plan_field() {
    python3 - "$1" "$2" << 'PYEOF'
import sys, re
try:
    content = open(sys.argv[1]).read()
except FileNotFoundError:
    sys.exit(0)
m = re.match(r'^---\n(.*?)\n---', content, re.DOTALL)
if m:
    field = re.escape(sys.argv[2])
    for line in m.group(1).splitlines():
        fm = re.match(r'^' + field + r':\s*["\']?(.+?)["\']?\s*$', line)
        if fm:
            print(fm.group(1).strip())
            break
PYEOF
}

# Extract included_recipes slugs from a plan file's YAML frontmatter
_get_included_recipes() {
    python3 - "$1" << 'PYEOF'
import sys, re
try:
    content = open(sys.argv[1]).read()
except FileNotFoundError:
    sys.exit(0)
m = re.match(r'^---\n(.*?)\n---', content, re.DOTALL)
if m:
    in_recipes = False
    for line in m.group(1).splitlines():
        if line.startswith('included_recipes:'):
            in_recipes = True
        elif in_recipes:
            rm = re.match(r'^[ \t]+-\s*["\']?(.+?)["\']?\s*$', line)
            if rm: print(rm.group(1).strip())
            elif line.strip() and line[0] not in (' ', '\t'): break
PYEOF
}

# Build PDF or EPUB for each plan defined in settings/build.yml.
# Pass 1: preprocess each file individually into _temp/build/<plan_slug>/.
# Pass 2: combine preprocessed files and run Pandoc for the final output.
build_output() {
    local format="$1"
    local lang_override="${2:-}"
    local lang
    if [ -n "$lang_override" ]; then
        lang="$lang_override"
    else
        lang=$(_parse_build_yml language)
        lang="${lang:-en}"
    fi
    local lang_dir="$output_directory/$lang"
    mkdir -p "$lang_dir"

    while IFS= read -r plan_slug; do
        [ -z "$plan_slug" ] && continue
        local plan_file="text/$lang/plans/$plan_slug.md"
        if [ ! -f "$plan_file" ]; then
            echo "⚠️  Plan not found: $plan_file"; continue
        fi
        echo "📋 Building $format: $plan_slug (lang: $lang)"

        # Collect recipe slugs from plan frontmatter
        local recipes=()
        while IFS= read -r slug; do
            [ -n "$slug" ] && recipes+=("$slug")
        done < <(_get_included_recipes "$plan_file")
        echo "   Recipes: ${recipes[*]:-none}"

        # Isolated temp dir per plan
        local temp_dir="_temp/build/$plan_slug"
        rm -rf "$temp_dir" && mkdir -p "$temp_dir"

        # 1. Plan file (no heading shift)
        $pandoc_command "$plan_file" \
            --lua-filter=lib/lua/recipe-metadata.lua \
            --to markdown --wrap=none --markdown-headings=atx \
            --output "$temp_dir/01_plan.md"

        # 2. General instructions (no heading shift)
        local gi_n=0
        for FILE in "text/$lang/general-instructions/"*.md; do
            [ -f "$FILE" ] || continue
            gi_n=$((gi_n + 1))
            $pandoc_command "$FILE" \
                --lua-filter=lib/lua/recipe-metadata.lua \
                --to markdown --wrap=none --markdown-headings=atx \
                --output "$(printf '%s/10_%02d_%s' "$temp_dir" "$gi_n" "$(basename "$FILE")")"
        done

        # 3. Recipes chapter intro (no heading shift, no metadata filter)
        local intro="text/$lang/recipes/00_chapter-intro.md"
        if [ -f "$intro" ]; then
            $pandoc_command "$intro" \
                --to markdown --wrap=none --markdown-headings=atx \
                --output "$temp_dir/20_chapter-intro.md"
        fi

        # 4. Recipe files in order from included_recipes (with heading shift)
        local r_n=0
        for slug in "${recipes[@]}"; do
            local recipe_file="text/$lang/recipes/$slug.md"
            if [ -f "$recipe_file" ]; then
                $pandoc_command "$recipe_file" \
                    --lua-filter=lib/lua/recipe-metadata.lua \
                    --shift-heading-level-by=1 \
                    --to markdown --wrap=none --markdown-headings=atx \
                    --output "$(printf '%s/21_%02d_%s.md' "$temp_dir" "$r_n" "$slug")"
                r_n=$((r_n + 1))
            else
                echo "   ⚠️  Recipe not found: $recipe_file"
            fi
        done

        # Assemble sorted file list and run Pandoc (Pass 2)
        local -a files=()
        while IFS= read -r -d '' f; do
            files+=("$f")
        done < <(find "$temp_dir" -maxdepth 1 -name '*.md' -print0 | sort -z)

        # Collect plan-level metadata for Pass 2
        local cover_image
        cover_image=$(_get_plan_field "$plan_file" "cover-image")
        local -a cover_args=()
        if [ -n "$cover_image" ]; then
            if [ "$format" = "pdf" ]; then
                cover_args+=(--metadata "cover-image=$cover_image")
            elif [ "$format" = "epub" ]; then
                cover_args+=("--epub-cover-image=$cover_image")
            fi
        fi

        local out_file="$lang_dir/$plan_slug.$format"
        echo "⚙️  Generating $out_file..."
        $pandoc_command "${files[@]}" \
            --defaults "settings/$format.yml" \
            --metadata-file "settings/metadata.${lang}.yml" \
            "${cover_args[@]}" \
            --output "$out_file"
        if [ $? -ne 0 ]; then echo "❌ $format generation failed for $plan_slug."; exit 1; fi
        echo "📖 $format ready: $out_file"

    done < <(_parse_build_yml plans)
}

pdf() { build_output pdf "${1:-}"; }

docx() {
    $pandoc_command text/*.md -o _temp/chapters.md
    $pandoc_command _temp/chapters.md \
        --defaults settings/docx.yml \
        -o $output_directory/$output_filename.docx
    echo "📖 The DOCX edition is now available in the $output_directory folder"
}

epub() { build_output epub "${1:-}"; }

oai() {
    touch _temp/empty.txt
    $pandoc_command _temp/empty.txt \
        --to plain \
        --metadata-file metadata.yml \
        --template templates/oai.xml \
        -o $output_directory/oai.xml
    echo "🌐 The OAI-PMH record is now available in the $output_directory folder"
}

markdown() {
    $pandoc_command text/*.md \
        --metadata-file metadata.yml \
        --wrap=none \
        -s -o $output_directory/$output_filename.md
    echo "📖 The Markdown file is now available in the $output_directory folder";
}

# these next set of functions help build the website

copy_assets() {
    local dest="${1:-$output_directory}"
    echo "Copying assets to $dest..."
    [ -d "images" ] && cp -r images "$dest" || echo "No images directory. Skipping..."
    cp -r lib/css/ "$dest"
    cp -r lib/js/ "$dest"
}

extract_metadata() {
    local lang="${1:-en}"
    echo "Extracting chapter metadata..."
    # Clean stale metadata from previous builds to ensure correct sort order
    rm -f _temp/*.metadata.json
    local FILE chapter_title basename

    for FILE in "text/$lang/plans/"*.md; do
        [ -f "$FILE" ] || continue
        chapter_title="$(grep '^# ' "$FILE" | head -1 | sed 's/# //')"
        basename="$(basename "$FILE" .md)"
        $pandoc_command "$FILE" --metadata chapter_title="$chapter_title" \
            --metadata htmlfile="$basename.html" \
            --template templates/metadata.template.json --to html \
            --output "_temp/01_${basename}.metadata.json"
    done

    for FILE in "text/$lang/general-instructions/"*.md; do
        [ -f "$FILE" ] || continue
        chapter_title="$(grep '^# ' "$FILE" | head -1 | sed 's/# //')"
        basename="$(basename "$FILE" .md)"
        $pandoc_command "$FILE" --metadata chapter_title="$chapter_title" \
            --metadata htmlfile="$basename.html" \
            --template templates/metadata.template.json --to html \
            --output "_temp/10_${basename}.metadata.json"
    done

    for FILE in "text/$lang/recipes/"[^0]*.md; do
        [ -f "$FILE" ] || continue
        chapter_title="$(grep '^# ' "$FILE" | head -1 | sed 's/# //')"
        basename="$(basename "$FILE" .md)"
        $pandoc_command "$FILE" --metadata chapter_title="$chapter_title" \
            --metadata htmlfile="$basename.html" \
            --template templates/metadata.template.json --to html \
            --output "_temp/21_${basename}.metadata.json"
    done
}

build_chapter_index() {
    echo "Building the chapter index..."
    echo "{\"chapter_list\": [" > _temp/chapters.json
    local SEPARATOR=""
    for FILE in _temp/*.metadata.json; do
        printf '%s' "$SEPARATOR" >> _temp/chapters.json
        cat "$FILE" >> _temp/chapters.json
        SEPARATOR=","
    done
    echo "]}" >> _temp/chapters.json
}


_build_html_page() {
    local FILE="$1"
    local out_dir="$2"
    local basename="$(basename "$FILE" .md)"
    local chapter_title="$(grep '^# ' "$FILE" | head -1 | sed 's/# //')"
    if [[ "$GITHUB_ACTIONS" = true ]]; then
        local UPDATED_AT="$(git log -1 --date=short-local --pretty='format:%cd' "$FILE")"
    else
        local UPDATED_AT="$(date -r "$FILE" "+%Y-%m-%d")"
    fi
    echo "⚙️  Processing $FILE..."
    $pandoc_command "$FILE" \
        --metadata-file _temp/chapters.json \
        --metadata-file "settings/metadata.${lang}.yml" \
        --metadata-file settings/config.yml \
        --metadata siteurl="$siteurl" \
        --metadata updatedtime="$UPDATED_AT" \
        --metadata htmlfile="$basename.html" \
        --metadata chapter_title="$chapter_title" \
        --defaults settings/html.yml \
        --toc --toc-depth=3 \
        --output "$out_dir/$basename.html"
}

html() {
    local lang_override="${1:-}"
    local lang
    if [ -n "$lang_override" ]; then
        lang="$lang_override"
    else
        lang=$(_parse_build_yml language)
        lang="${lang:-en}"
    fi

    local lang_dir="$output_directory/$lang"
    local TIME_START=$(date +%s)
    mkdir -p _temp "$lang_dir"
    touch _temp/empty.txt

    copy_assets "$lang_dir"
    extract_metadata "$lang"
    build_chapter_index

    echo "Building plan pages..."
    for FILE in "text/$lang/plans/"*.md; do
        [ -f "$FILE" ] || continue
        _build_html_page "$FILE" "$lang_dir"
    done

    echo "Building general instruction pages..."
    for FILE in "text/$lang/general-instructions/"*.md; do
        [ -f "$FILE" ] || continue
        _build_html_page "$FILE" "$lang_dir"
    done

    echo "Building recipe pages..."
    for FILE in "text/$lang/recipes/"[^0]*.md; do
        [ -f "$FILE" ] || continue
        _build_html_page "$FILE" "$lang_dir"
    done

    echo "Building the home page..."
    local meta_file="settings/metadata.${lang}.yml"
    [ -f "$meta_file" ] || meta_file="settings/metadata.en.yml"
    $pandoc_command _temp/empty.txt \
        --metadata-file _temp/chapters.json \
        --metadata-file "$meta_file" \
        --metadata-file settings/config.yml \
        --template templates/home.html \
        --metadata updatedtime="$(date "+%Y-%m-%d")" \
        --standalone \
        --output "$lang_dir/index.html"

    echo "Assembling search index..."
    echo "[" > _temp/search.json
    local SEPARATOR=""
    for F in _temp/*.metadata.json; do
        printf '%s' "$SEPARATOR" >> _temp/search.json
        cat "$F" >> _temp/search.json
        SEPARATOR=","
    done
    echo "]" >> _temp/search.json
    cp _temp/search.json "$lang_dir/"

    local TIME_END=$(date +%s)
    echo "🚀 All done after $((TIME_END-TIME_START)) seconds!"
}

 reset() {
    rm -rf $output_directory
    rm -rf _temp
    echo "🗑️ Let's start over.";
}

server() {
    # runs a local development server for testing
    # requires Python 3.x installed on the machine
    html;
    python3 -m http.server --directory $output_directory;
}

# If no arguments are specified in the $ bash lantern.sh command,
# then run the output_formats function (which builds all formats)
if [ -z "$1" ]
then
    output_formats
elif [[ "$1" =~ ^[a-z]{2}$ ]] && ! declare -f "$1" > /dev/null 2>&1; then
    # Allow 'bash lantern.sh de' to build all formats for that language
    html "$1"
    pdf "$1"
    epub "$1"
else
    "$@"
fi
