local ansicolors = require "ansicolors"

local message_formats = {
   ["111"] = function(w)
      if w.module then return "setting non-module global variable %s"
         else return "setting non-standard global variable %s" end end,
   ["112"] = "mutating non-standard global variable %s",
   ["113"] = "accessing undefined variable %s",
   ["131"] = "unused global variable %s",
   ["211"] = function(w)
      if w.func then return "unused function %s"
         else return "unused variable %s" end end,
   ["212"] = function(w)
      if w.vararg then return "unused variable length argument"
         else return "unused argument %s" end end,
   ["213"] = "unused loop variable %s",
   ["221"] = "variable %s is never set",
   ["231"] = "variable %s is never accessed",
   ["232"] = "argument %s is never accessed",
   ["233"] = "loop variable %s is never accessed",
   ["311"] = "value assigned to variable %s is unused",
   ["312"] = "value of argument %s is unused",
   ["313"] = "value of loop variable %s is unused",
   ["321"] = "accessing uninitialized variable %s",
   ["411"] = "variable %s was previously defined on line %s",
   ["412"] = "variable %s was previously defined as an argument on line %s",
   ["413"] = "variable %s was previously defined as a loop variable on line %s",
   ["421"] = "shadowing definition of variable %s on line %s",
   ["422"] = "shadowing definition of argument %s on line %s",
   ["423"] = "shadowing definition of loop variable %s on line %s",
   ["511"] = "unreachable code",
   ["521"] = "unused label %s"
}

local function get_message_format(warning)
   local message_format = message_formats[warning.code]

   if type(message_format) == "function" then
      return message_format(warning)
   else
      return message_format
   end
end

local function plural(number)
   return (number == 1) and "" or "s"
end

local function format_color(fmt, str, color)
   return color and ansicolors(fmt .. str) or str
end

local function format_name(name, color)
   return color and ansicolors("%{bright}" .. name) or ("'" .. name .. "'")
end

local function format_number(number, limit, color)
   return format_color("%{bright}" .. (number > limit and "%{red}" or ""), number, color)
end

local function capitalize(str)
   return str:gsub("^.", string.upper)
end

local function format_file_report_header(report, file_name, color)
   local label = "Checking " .. file_name
   local status

   if report.error then
      status = format_color("%{bright}", capitalize(report.error) .. " error", color)
   elseif #report == 0 then
      status = format_color("%{bright}%{green}", "OK", color)
   else
      status = format_color("%{bright}%{red}", "Failure", color)
   end

   return label .. (" "):rep(math.max(50 - #label, 1)) .. status
end

local function format_file_report(report, file_name, color)
   local buf = {format_file_report_header(report, file_name, color)}

   if not report.error and #report > 0 then
      table.insert(buf, "")

      for _, warning in ipairs(report) do
         local location = ("%s:%d:%d"):format(file_name, warning.line, warning.column)
         local message_format = get_message_format(warning)
         local message = message_format:format(warning.name and format_name(warning.name, color), warning.prev_line)
         table.insert(buf, ("    %s: %s"):format(location, message))
      end

      table.insert(buf, "")
   end

   return table.concat(buf, "\n")
end

--- Formats a report. 
-- Recognized options: 
--    `options.quiet`: integer in range 0-3. See CLI. Default: 0. 
--    `options.limit`: See CLI. Default: 0. 
--    `options.color`: should use ansicolors? Default: true. 
local function format(report, file_names, options)
   local quiet = options.quiet or 0
   local limit = options.limit or 0
   local color = options.color ~= false

   local buf = {}

   if quiet <= 2 then
      for i, file_report in ipairs(report) do
         if quiet == 0 or file_report.error or #file_report > 0 then
            table.insert(buf, (quiet == 2 and format_file_report_header or format_file_report) (
               file_report, type(file_names[i]) == "string" and file_names[i] or "stdin", color))
         end
      end

      if #buf > 0 and buf[#buf]:sub(-1) ~= "\n" then
         table.insert(buf, "")
      end
   end

   table.insert(buf, ("Total: %s warning%s / %s error%s in %d file%s"):format(
      format_number(report.warnings, limit, color), plural(report.warnings),
      format_number(report.errors, 0, color), plural(report.errors),
      #report, plural(#report)
   ))

   return table.concat(buf, "\n")
end

return format
