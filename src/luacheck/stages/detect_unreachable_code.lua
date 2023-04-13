local stage = {}

stage.warnings = {
   ["511"] = {message_format = "unreachable code", fields = {}},
   ["512"] = {message_format = "loop is executed at most once", fields = {}}
}

local function noop_callback() end

local function dump(o, level)
   if not level then level = 0 end
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         local val
         if level < 5 then
            val = dump(v, level + 1)
         else
            val = tostring(v)
         end
         s = s .. '['..k..'] = ' .. val .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end


local function detect_unreachable_code(chstate, line)
   local reachable_indexes = {}

   -- Mark all items reachable from the function start.
   line:walk(reachable_indexes, 1, noop_callback)

   -- All remaining items are unreachable.
   -- However, there is no point in reporting all of them.
   -- Only report those that are not reachable from any already reported ones.
   for item_index, item in ipairs(line.items) do
      if not reachable_indexes[item_index] then
         if item.node then
            dump(item)
            chstate:warn_range(item.loop_end and "512" or "511", item.node)
            -- Mark all items reachable from the item just reported.
            line:walk(reachable_indexes, item_index, noop_callback)
         end
      end
   end
end

function stage.run(chstate)
   for _, line in ipairs(chstate.lines) do
      detect_unreachable_code(chstate, line)
   end
end

return stage
