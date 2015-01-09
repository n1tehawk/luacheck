local luacheck = require "luacheck"

describe("luacheck", function()
   describe("type checking", function()
      it("panics on bad files", function()
         assert.has_error(function() luacheck("foo") end,
            "bad argument #1 to 'luacheck' (table expected, got string)")
         assert.has_error(function() luacheck({123}) end,
            "bad argument #1 to 'luacheck' (array of paths or file handles expected, got number)")
      end)

      it("panics on bad options", function()
         assert.has_error(function() luacheck({"foo"}, "bar") end,
            "bad argument #2 to 'luacheck' (table or nil expected, got string)")
         assert.has_error(function() luacheck({"foo"}, {globals = "bar"}) end,
            "bad argument #2 to 'luacheck' (invalid value of option 'globals')")
         assert.has_error(function() luacheck({"foo"}, {{unused = 123}}) end,
            "bad argument #2 to 'luacheck' (invalid value of option 'unused')")
      end)
   end)

   it("works on empty list", function()
      assert.same({
         warnings = 0,
         errors = 0
      }, luacheck({}))
   end)

   it("works on files", function()
      assert.same({
         {},
         {
            {
               code = "211",
               name = "helper",
               line = 3,
               column = 16
            },
            {
               code = "212",
               name = "...",
               line = 3,
               column = 23,
               vararg = true
            },
            {
               code = "111",
               name = "embrace",
               line = 7,
               column = 10,
               top = true
            },
            {
               code = "412",
               name = "opt",
               line = 8,
               column = 10,
               prev_line = 7,
               prev_column = 18
            },
            {
               code = "113",
               name = "hepler",
               line = 9,
               column = 11
            }
         },
         {
            error = "syntax"
         },
         warnings = 5,
         errors = 1
      }, luacheck({
         "spec/samples/good_code.lua",
         "spec/samples/bad_code.lua",
         "spec/samples/python_code.lua"
      }))
   end)

   it("uses options", function()
      assert.same({
         {},
         {
            {
               code = "111",
               name = "embrace",
               line = 7,
               column = 10,
               top = true
            },
            {
               code = "412",
               name = "opt",
               line = 8,
               column = 10,
               prev_line = 7,
               prev_column = 18
            },
            {
               code = "113",
               name = "hepler",
               line = 9,
               column = 11
            }
         },
         {
            error = "syntax"
         },
         warnings = 3,
         errors = 1
      }, luacheck({
         "spec/samples/good_code.lua",
         "spec/samples/bad_code.lua",
         "spec/samples/python_code.lua"
      }, {
         unused = false
      }))
   end)

   it("uses option overrides", function()
      assert.same({
         {},
         {
            {
               code = "111",
               name = "embrace",
               line = 7,
               column = 10,
               top = true
            },
            {
               code = "113",
               name = "hepler",
               line = 9,
               column = 11
            }
         },
         {
            error = "syntax"
         },
         warnings = 2,
         errors = 1
      }, luacheck({
         "spec/samples/good_code.lua",
         "spec/samples/bad_code.lua",
         "spec/samples/python_code.lua"
      }, {
         nil,
         {
            global = true,
            unused = false,
            redefined = false
         },
         global = false
      }  ))
   end)
end)
