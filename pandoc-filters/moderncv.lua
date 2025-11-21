-- pandoc-filters/moderncv.lua
-- Convert a bullet list directly following a header into a sequence of \cventry LaTeX commands.
--
-- Usage:
--   pandoc resume.md --template=moderncv.tex --lua-filter=pandoc-filters/moderncv.lua -o resume.pdf
--
-- Markdown convention expected for each list item under a section:
--   - years | title | institution | city | grade | description
-- Any of the six fields may be left empty (use consecutive pipes). The "description"
-- field may contain more text; additional paragraphs or nested lists in the item will
-- be concatenated and used as the last argument of \cventry.

local List = require('pandoc.List')

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function escape_tex(s)
  -- minimal TeX escaping for special characters
  s = s or ""
  s = s:gsub('\\', '\\textbackslash{}')
  s = s:gsub('{','\\{')
  s = s:gsub('}','\\}')
  s = s:gsub('%$', '\\$')
  s = s:gsub('%%','\\%')
  s = s:gsub('#','\\#')
  s = s:gsub('&','\\&')
  s = s:gsub('_','\\_')
  s = s:gsub('%^','\\^{}')
  s = s:gsub('~','\\~{}')
  return s
end

local function para_text(blocks)
  -- concatenate block content into plain text
  local parts = {}
  for _, b in ipairs(blocks) do
    table.insert(parts, pandoc.utils.stringify(b))
  end
  return table.concat(parts, "\n")
end

local function escape_tex_inline(s)
  return escape_tex(s):gsub('\n','\\\\')
end

local function list_item_to_tex(item_blocks)
  -- item_blocks is an array of blocks forming one list item
  -- stringify the non-list parts and convert nested lists recursively
  local parts = {}
  for _, b in ipairs(item_blocks) do
    if b.t == 'BulletList' or b.t == 'OrderedList' then
      -- nested list: convert recursively
      table.insert(parts, list_to_tex(b))
    else
      table.insert(parts, pandoc.utils.stringify(b))
    end
  end
  return table.concat(parts, ' ')
end

function list_to_tex(list_block)
  -- converts a BulletList or OrderedList block to LaTeX itemize/enumerate
  local env = (list_block.t == 'OrderedList') and 'enumerate' or 'itemize'
  local out = {'\\begin{' .. env .. '}'}
  for _, item in ipairs(list_block.content) do
    -- item is an array of blocks
    local txt = list_item_to_tex(item)
    table.insert(out, '\\item ' .. escape_tex_inline(txt))
  end
  table.insert(out, '\\end{' .. env .. '}')
  return table.concat(out, '\n')
end

function Pandoc(doc)
  local blocks = doc.blocks
  local out = List{}
  local i = 1
  while i <= #blocks do
    local b = blocks[i]
    if b.t == 'Header' then
      table.insert(out, b)
      -- check next block is a bullet list
      local nextb = blocks[i+1]
      if nextb and nextb.t == 'BulletList' then
        -- convert each list item to a \cventry raw LaTeX block
        for _, item in ipairs(nextb.content) do
          -- item is a list of blocks; first paragraph expected to contain the pipe-separated fields
          local first = item[1]
          local fields = {}
          if first and first.t == 'Para' then
            local s = pandoc.utils.stringify(first)
            -- split by pipe
            for part in s:gmatch("[^|]+") do
              table.insert(fields, trim(part))
            end
          else
            -- fallback: stringify whole item
            local s = para_text(item)
            for part in s:gmatch("[^|]+") do
              table.insert(fields, trim(part))
            end
          end

          -- collect description: everything except first paragraph (or the remainder of the first para after the 6th field)
          local description = ''
          if #item > 1 then
            description = para_text({table.unpack(item,2)})
          else
            -- if the first paragraph had more than 6 pipe parts, join parts[7..] into description
            if #fields > 6 then
              local rest = {}
              for k = 7, #fields do table.insert(rest, fields[k]) end
              description = table.concat(rest, ' | ')
              for _ = 7, #fields do table.remove(fields) end
            end
          end

          -- ensure six fields
          for _ = #fields+1, 6 do table.insert(fields, '') end

          local years = escape_tex(fields[1])
          local title = escape_tex(fields[2])
          local institution = escape_tex(fields[3])
          local city = escape_tex(fields[4])
          local grade = escape_tex(fields[5])
          local desc = escape_tex(description ~= '' and description or fields[6])

          local tex = string.format("\\cventry{%s}{%s}{%s}{%s}{%s}{%s}", years, title, institution, city, grade, desc)
          table.insert(out, pandoc.RawBlock('latex', tex))
        end
        i = i + 2
      elseif nextb and nextb.t == 'DefinitionList' then
        -- handle Pandoc definition lists where term is years and definition contains the details
        for _, entry in ipairs(nextb.content) do
          local term_inlines = entry[1]
          local defs = entry[2] -- defs is a list of definition blocks (each definition is a list of blocks)
          local years = escape_tex(pandoc.utils.stringify(term_inlines))
          if #defs >= 1 then
            local def_blocks = defs[1] -- first definition (array of blocks)
            local fields = {}
            local first = def_blocks[1]
            if first and first.t == 'Para' then
              local s = pandoc.utils.stringify(first)
              for part in s:gmatch("[^|]+") do table.insert(fields, trim(part)) end
            else
              local s = para_text(def_blocks)
              for part in s:gmatch("[^|]+") do table.insert(fields, trim(part)) end
            end

            -- description: blocks after the first para inside the definition
            local description_tex = ''
            if #def_blocks > 1 then
              local parts = {}
              for idx = 2, #def_blocks do
                local db = def_blocks[idx]
                if db.t == 'BulletList' or db.t == 'OrderedList' then
                  table.insert(parts, list_to_tex(db))
                else
                  table.insert(parts, escape_tex(pandoc.utils.stringify(db)))
                end
              end
              description_tex = table.concat(parts, '\n')
            else
              -- if too many pipe fields, take ones beyond 6 as description
              if #fields > 6 then
                local rest = {}
                for k = 7, #fields do table.insert(rest, fields[k]) end
                description_tex = escape_tex(table.concat(rest, ' | '))
                for _ = 7, #fields do table.remove(fields) end
              end
            end

            for _ = #fields+1, 6 do table.insert(fields, '') end

            local title = escape_tex(fields[2])
            local institution = escape_tex(fields[3])
            local city = escape_tex(fields[4])
            local grade = escape_tex(fields[5])
            local desc = description_tex ~= '' and description_tex or escape_tex(fields[6])

            local tex = string.format("\\cventry{%s}{%s}{%s}{%s}{%s}{%s}", years, title, institution, city, grade, desc)
            table.insert(out, pandoc.RawBlock('latex', tex))
          end
        end
        i = i + 2
      else
        i = i + 1
      end
    else
      table.insert(out, b)
      i = i + 1
    end
  end
  doc.blocks = out
  return doc
end

-- End of filter
