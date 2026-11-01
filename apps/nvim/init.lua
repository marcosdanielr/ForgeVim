-- Keep the entry point small; modules own their lifecycle.
local directory = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
vim.opt.rtp:prepend(directory)
require("forge").setup(directory)
