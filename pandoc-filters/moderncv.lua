local List = require('pandoc.List')

-- Helper function: trim whitespace
local function trim(s)
  if not s then return '' end
  return s:match('^%s*(.-)%s*$')
end

-- Helper function: escape LaTeX special characters
local function escape_tex(text)
  if not text then return '' end
  text = tostring(text)
  -- Order matters: backslash first
  text = text:gsub('\\', '\\textbackslash{}')
  text = text:gsub('[%$%&#_%^{}]', function(c)
    if c == '$' then return '\\$'
    elseif c == '&' then return '\\&'
    elseif c == '#' then return '\\#'
    elseif c == '_' then return '\\_'
    elseif c == '%' then return '\\%'
    elseif c == '^' then return '\\^{}'
    elseif c == '{' then return '\\{'
    elseif c == '}' then return '\\}'
    end
  end)
  return text
end

-- Helper function: convert list of inlines to LaTeX (handles nesting internally)
local function inlines_to_tex(inlines)
  local result = {}
  for _, inline in ipairs(inlines) do
        -- DEBUG
    if inline.t == 'Link' then
      io.stderr:write("DEBUG: Found Link inline: " .. tostring(inline.target) .. "\n")
    end
    if inline.t == 'Str' then
      table.insert(result, escape_tex(inline.text))
    elseif inline.t == 'Space' then
      table.insert(result, ' ')
    elseif inline.t == 'SoftBreak' or inline.t == 'LineBreak' then
      table.insert(result, ' ')
    elseif inline.t == 'Strong' then
      table.insert(result, '\\textbf{' .. inlines_to_tex(inline.content) .. '}')
    elseif inline.t == 'Emph' then
      table.insert(result, '\\textit{' .. inlines_to_tex(inline.content) .. '}')
    elseif inline.t == 'Code' then
      table.insert(result, '\\texttt{' .. escape_tex(inline.text) .. '}')
    elseif inline.t == 'Link' then
      table.insert(result, '\\href{' .. escape_tex(inline.target) .. '}{' .. inlines_to_tex(inline.content) .. '}')
    else
      table.insert(result, escape_tex(pandoc.utils.stringify(inline)))
    end
  end
  return table.concat(result, '')
end

local function list_to_tex(list)
  local env = list.t == 'BulletList' and 'itemize' or 'enumerate'
  local result = {'\\begin{' .. env .. '}'}
  for idx, item_blocks in ipairs(list.content) do
    io.stderr:write("DEBUG list_to_tex: Processing item " .. idx .. " with " .. #item_blocks .. " blocks\n")
    local item_text = {}
    for bi, block in ipairs(item_blocks) do
      io.stderr:write("  Block " .. bi .. ": type=" .. block.t .. "\n")
      if block.t == 'Para' then
        io.stderr:write("    Para has " .. #block.content .. " inlines\n")
        table.insert(item_text, inlines_to_tex(block.content))
      elseif block.t == 'BulletList' or block.t == 'OrderedList' then
        table.insert(item_text, list_to_tex(block))
      else
        table.insert(item_text, escape_tex(pandoc.utils.stringify(block)))
      end
    end
    table.insert(result, '\\item ' .. table.concat(item_text, ' '))
  end
  table.insert(result, '\\end{' .. env .. '}')
  local final_result = table.concat(result, '\n')
  io.stderr:write("DEBUG list_to_tex output:\n" .. final_result .. "\n---END---\n")
  return final_result
end

-- Helper function: convert blocks to LaTeX description text with inline support
local function blocks_to_description_tex_with_inlines(blocks)
  local result = {}
  for _, block in ipairs(blocks) do
    if block.t == 'Para' then
      table.insert(result, inlines_to_tex(block.content))
    elseif block.t == 'BulletList' or block.t == 'OrderedList' then
      table.insert(result, list_to_tex(block))
    else
      table.insert(result, escape_tex(pandoc.utils.stringify(block)))
    end
  end
  return table.concat(result, '\n')
end

-- Helper: split inlines by pipe character, converting each segment to TeX
local function split_inlines_by_pipe(inlines)
  local segments = {}
  local current_segment = {}
  
  for _, inline in ipairs(inlines) do
    if inline.t == 'Str' and inline.text:find('|') then
      -- Split this string on pipes
      local parts = {}
      for part in inline.text:gmatch('[^|]+') do
        table.insert(parts, part)
      end
      
      for pi, part in ipairs(parts) do
        if pi > 1 then
          -- End current segment, start new one
          if #current_segment > 0 then
            table.insert(segments, inlines_to_tex(current_segment))
          else
            table.insert(segments, '')
          end
          current_segment = {}
        end
        
        -- Add non-empty part as Str inline to current segment
        if part ~= '' then
          table.insert(current_segment, {t='Str', text=part})
        end
      end
    else
      -- No pipe in this inline, add to current segment
      table.insert(current_segment, inline)
    end
  end
  
  -- Emit final segment
  if #current_segment > 0 then
    table.insert(segments, inlines_to_tex(current_segment))
  else
    table.insert(segments, '')
  end
  
  return segments
end

-- Pandoc filter function
function Pandoc(doc)
  local result = {}
  local i = 1
  
  while i <= #doc.blocks do
    local block = doc.blocks[i]
    
    if block.t == 'Header' and block.level == 3 then
      local header_text = pandoc.utils.stringify(block.content)
      
      if i + 1 <= #doc.blocks and doc.blocks[i + 1].t == 'Para' then
        local pipe_para = doc.blocks[i + 1]
        local pipe_text = pandoc.utils.stringify(pipe_para.content)
        
        if pipe_text:find('|') then
          -- Split pipe_text to get plain field count
          local plain_fields = {}
          for part in pipe_text:gmatch('[^|]+') do
            table.insert(plain_fields, trim(part))
          end
          
          -- Now parse inlines to extract formatted fields (preserving links, bold, etc.)
          local formatted_fields = split_inlines_by_pipe(pipe_para.content)
          
          -- Find next header at level <= 3
          local next_header_index = #doc.blocks + 1
          for j = i + 2, #doc.blocks do
            if doc.blocks[j].t == 'Header' and doc.blocks[j].level <= 3 then
              next_header_index = j
              break
            end
          end
          
          -- Collect description blocks
          local description_blocks = {}
          for j = i + 2, next_header_index - 1 do
            table.insert(description_blocks, doc.blocks[j])
          end
          
          -- Check if any block is not a Header
          local has_description = false
          for _, dblock in ipairs(description_blocks) do
            if dblock.t ~= 'Header' then
              has_description = true
              break
            end
          end
          
          if has_description then
            -- cventry format
            local desc_tex = blocks_to_description_tex_with_inlines(description_blocks)
            local cmd = string.format(
              '\\cventry{%s}{%s}{%s}{%s}{%s}{%s}',
              escape_tex(header_text),
              formatted_fields[1] or '',
              formatted_fields[2] or '',
              formatted_fields[3] or '',
              formatted_fields[4] or '',
              desc_tex
            )
            table.insert(result, pandoc.RawBlock('latex', cmd))
          else
            -- cvitem format variants
            local nd = #formatted_fields
            local cmd
            if nd == 0 then
              cmd = string.format('\\cvitem{%s}{}', escape_tex(header_text))
            elseif nd == 1 then
              cmd = string.format('\\cvitem{%s}{%s}', escape_tex(header_text), formatted_fields[1])
            elseif nd == 2 then
              cmd = string.format('\\cvitemwithcomment{%s}{%s}{%s}', escape_tex(header_text), formatted_fields[1], formatted_fields[2])
            elseif nd == 3 then
              cmd = string.format('\\cvdoubleitem{%s}{%s}{%s}{%s}', escape_tex(header_text), formatted_fields[1], formatted_fields[2], formatted_fields[3])
            else
              -- Combine fields 3+ with literal pipes
              local combined = table.concat({table.unpack(formatted_fields, 3)}, ' | ')
              cmd = string.format('\\cvdoubleitem{%s}{%s}{%s}{%s}', escape_tex(header_text), formatted_fields[1], formatted_fields[2], combined)
            end
            table.insert(result, pandoc.RawBlock('latex', cmd))
          end
          
          i = next_header_index
        else
          table.insert(result, block)
          i = i + 1
        end
      else
        table.insert(result, block)
        i = i + 1
      end
    else
      table.insert(result, block)
      i = i + 1
    end
  end
  
  doc.blocks = List(result)
  return doc
end

-- Helper: split inlines by pipe character, converting each segment to TeX
local function split_inlines_by_pipe(inlines)
  local segments = {}
  local current_segment = {}
  
  for _, inline in ipairs(inlines) do
    if inline.t == 'Str' and inline.text:find('|') then
      -- Split this string on pipes
      local parts = {}
      for part in inline.text:gmatch('[^|]+') do
        table.insert(parts, part)
      end
      
      for pi, part in ipairs(parts) do
        if pi > 1 then
          -- End current segment, start new one
          if #current_segment > 0 then
            table.insert(segments, inlines_to_tex(current_segment))
          else
            table.insert(segments, '')
          end
          current_segment = {}
        end
        
        -- Add non-empty part as Str inline to current segment
        if part ~= '' then
          table.insert(current_segment, {t='Str', text=part})
        end
      end
    else
      -- No pipe in this inline, add to current segment
      table.insert(current_segment, inline)
    end
  end
  
  -- Emit final segment
  if #current_segment > 0 then
    table.insert(segments, inlines_to_tex(current_segment))
  else
    table.insert(segments, '')
  end
  
  return segments
end

-- Meta filter function for frontmatter injection
function Meta(meta)
  local blocks = {}
  
  -- Helper to stringify meta values
  local function mstr(key)
    if meta[key] then
      return pandoc.utils.stringify(meta[key])
    end
    return nil
  end
  
  -- Helper to split name on first space
  local function split_name(s)
    if not s then return nil, nil end
    local firstname, lastname = s:match('^(%S+)%s+(.+)$')
    if not firstname then
      return s, nil
    end
    return firstname, lastname
  end
  
  -- Helper to split by commas and trim
  local function split_comma(s)
    if not s then return {} end
    local result = {}
    for part in s:gmatch('[^,]+') do
      table.insert(result, trim(part))
    end
    return result
  end
  
  -- Name
  local firstname = mstr('firstname')
  local lastname = mstr('lastname')
  if not firstname and not lastname then
    firstname, lastname = split_name(mstr('name'))
  end
  if firstname or lastname then
    table.insert(blocks, string.format('\\name{%s}{%s}', escape_tex(firstname or ''), escape_tex(lastname or '')))
  end
  
  -- Title
  local title = mstr('title')
  if title then
    table.insert(blocks, string.format('\\title{%s}', escape_tex(title)))
  end
  
  -- Address
  local address_str = mstr('address')
  if address_str then
    local addr_parts = split_comma(address_str)
    local street = addr_parts[1] or ''
    local city = addr_parts[2] or ''
    local country = addr_parts[3] or ''
    table.insert(blocks, string.format('\\address{%s}{%s}{%s}', escape_tex(street), escape_tex(city), escape_tex(country)))
  end
  
  -- Phone
  local phone = mstr('phone')
  if phone then
    table.insert(blocks, string.format('\\phone[mobile]{%s}', escape_tex(phone)))
  end
  
  -- Phones (table/map format)
  if meta.phones and type(meta.phones) == 'table' then
    for k, v in pairs(meta.phones) do
      local v_str = pandoc.utils.stringify(v)
      table.insert(blocks, string.format('\\phone[%s]{%s}', escape_tex(k), escape_tex(v_str)))
    end
  end
  
  -- Email
  local email = mstr('email')
  if email then
    table.insert(blocks, string.format('\\email{%s}', escape_tex(email)))
  end
  
  -- Homepage/URL
  local homepage = mstr('homepage')
  local url = mstr('url')
  if homepage then
    table.insert(blocks, string.format('\\homepage{%s}', escape_tex(homepage)))
  elseif url then
    table.insert(blocks, string.format('\\homepage{%s}', escape_tex(url)))
  end
  
  -- Social
  if meta.social and type(meta.social) == 'table' then
    for k, v in pairs(meta.social) do
      local v_str = pandoc.utils.stringify(v)
      table.insert(blocks, string.format('\\social[%s]{%s}', escape_tex(k), escape_tex(v_str)))
    end
  end
  
  -- Append to header-includes
  meta['header-includes'] = meta['header-includes'] or pandoc.MetaList({})
  for _, block_str in ipairs(blocks) do
    table.insert(meta['header-includes'], pandoc.RawBlock('latex', block_str))
  end
  
  return meta
end