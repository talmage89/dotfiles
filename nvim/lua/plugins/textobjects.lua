local function select(query)
  return function()
    require("nvim-treesitter-textobjects.select").select_textobject(query, "textobjects")
  end
end

local function move(dir, query)
  return function()
    require("nvim-treesitter-textobjects.move")["goto_" .. dir](query, "textobjects")
  end
end

return {
  "nvim-treesitter/nvim-treesitter-textobjects",
  branch = "main",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  keys = {
    { "af", select("@function.outer"), mode = { "x", "o" }, desc = "Function (outer)" },
    { "if", select("@function.inner"), mode = { "x", "o" }, desc = "Function (inner)" },
    { "ac", select("@class.outer"), mode = { "x", "o" }, desc = "Class (outer)" },
    { "ic", select("@class.inner"), mode = { "x", "o" }, desc = "Class (inner)" },
    { "aa", select("@parameter.outer"), mode = { "x", "o" }, desc = "Parameter (outer)" },
    { "ia", select("@parameter.inner"), mode = { "x", "o" }, desc = "Parameter (inner)" },
    { "]f", move("next_start", "@function.outer"), mode = { "n", "x", "o" }, desc = "Next function start" },
    { "[f", move("previous_start", "@function.outer"), mode = { "n", "x", "o" }, desc = "Prev function start" },
    { "]F", move("next_end", "@function.outer"), mode = { "n", "x", "o" }, desc = "Next function end" },
    { "[F", move("previous_end", "@function.outer"), mode = { "n", "x", "o" }, desc = "Prev function end" },
  },
  opts = {
    select = { lookahead = true },
    move = { set_jumps = true },
  },
}
