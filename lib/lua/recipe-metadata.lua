-- recipe-metadata.lua
-- Injects a recipe metadata bar (prep time, cook time, servings) from
-- YAML frontmatter into the document body before all other content.
--
-- Only runs when the relevant frontmatter fields are present, so it is
-- safe to include in settings files that process combined documents
-- (chapters.md) where per-recipe metadata is not available.
--
-- Ingredients are NOT injected here — they live in the markdown body
-- so they appear correctly in all output formats (HTML, EPUB, PDF).

local stringify = pandoc.utils.stringify

-- Labels per language. Add a new block here to support additional languages.
local labels = {
  en = { prep = "Prep", cook = "Cook", servings = "Servings", kcal = "kcal/serving" },
  de = { prep = "Vorbereitung", cook = "Kochzeit", servings = "Portionen", kcal = "kcal/Portion" },
}

function Pandoc(doc)
  local meta = doc.meta

  -- Skip if no recipe metadata present (e.g. plan overview, combined docs)
  if not meta.prep_time and not meta.cook_time and not meta.servings then
    return doc
  end

  -- Pick label set based on language field; fall back to English
  local lang = meta.language and stringify(meta.language) or "en"
  local l = labels[lang] or labels["en"]

  local parts = {}

  if meta.prep_time then
    table.insert(parts,
      '<span class="recipe-prep-time">' .. l.prep .. ': ' .. stringify(meta.prep_time) .. '</span>')
  end

  if meta.cook_time then
    table.insert(parts,
      '<span class="recipe-cook-time">' .. l.cook .. ': ' .. stringify(meta.cook_time) .. '</span>')
  end

  if meta.servings then
    table.insert(parts,
      '<span class="recipe-servings">' .. l.servings .. ': ' .. stringify(meta.servings) .. '</span>')
  end

  if meta.kcal_per_serving then
    table.insert(parts,
      '<span class="recipe-kcal">' .. stringify(meta.kcal_per_serving) .. ' ' .. l.kcal .. '</span>')
  end

  local bar = pandoc.RawBlock('html',
    '<div class="recipe-meta">\n' ..
    table.concat(parts, '\n') ..
    '\n</div>')

  -- Build image block if image field is present
  local img_block = nil
  if meta.image then
    local img_path = stringify(meta.image)
    local img_title = meta.title and stringify(meta.title) or ''
    img_block = pandoc.RawBlock('html',
      '<figure class="recipe-image">\n' ..
      '<img src="' .. img_path .. '" alt="' .. img_title .. '" />\n' ..
      '</figure>')
  end

  -- Insert bar (and optional image) after the first h1 heading.
  -- Also stamp the heading with class "recipe-title" so CSS can target it
  -- after heading levels are shifted (# -> ##) during preprocessing.
  local new_blocks = pandoc.List({})
  local inserted = false
  for _, block in ipairs(doc.blocks) do
    if not inserted and block.t == "Header" then
      local classes = pandoc.List(block.attr.classes)
      classes:insert("recipe-title")
      local stamped = pandoc.Header(
        block.level, block.content,
        pandoc.Attr(block.attr.identifier, classes, block.attr.attributes)
      )
      -- (level will be whatever Pandoc shifted it to before running this filter)
      new_blocks:insert(stamped)
      new_blocks:insert(bar)
      if img_block then new_blocks:insert(img_block) end
      inserted = true
    else
      new_blocks:insert(block)
    end
  end
  if not inserted then
    -- Fallback: no h1 found, prepend
    new_blocks = pandoc.List({ bar })
    if img_block then new_blocks:insert(img_block) end
    new_blocks:extend(doc.blocks)
  end

  return pandoc.Pandoc(new_blocks, doc.meta)
end
