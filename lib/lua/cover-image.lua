-- cover-image.lua
-- If 'cover-image' is set in metadata, injects an inline <style> that
-- sets it as the background of the PDF title block (#title-block-header).
-- Add this filter to settings/pdf.yml only.

local stringify = pandoc.utils.stringify

function Pandoc(doc)
  local meta = doc.meta
  if not meta['cover-image'] then return doc end

  local img_path = stringify(meta['cover-image'])
  local style = pandoc.RawBlock('html',
    '<style>\n' ..
    '#title-block-header {\n' ..
    '  background-image: url("' .. img_path .. '");\n' ..
    '}\n' ..
    '</style>')

  local new_blocks = pandoc.List({ style })
  new_blocks:extend(doc.blocks)
  return pandoc.Pandoc(new_blocks, doc.meta)
end
