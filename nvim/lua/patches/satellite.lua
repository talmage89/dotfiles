-- Override satellite's util.winbuf_pred so a suspended handler also bails
-- when its window now shows a different buffer. Upstream only checks that
-- the buffer is unchanged and the window still exists, but the bar math
-- resolves the buffer through the window. Diffview opens every view with
-- `tab split` and then swaps its 1-line null buffer into those windows, so
-- a diagnostic row from the split-off file gets measured against the null
-- buffer and nvim_win_text_height throws "Line index out of bounds".
--
-- Drop this file once upstream winbuf_pred checks the window's buffer.

return function()
  local api = vim.api
  local util = require("satellite.util")
  local winbuf_pred = util.winbuf_pred

  function util.winbuf_pred(bufnr, winid)
    local pred = winbuf_pred(bufnr, winid)
    return function()
      if pred() == false then
        return false
      end
      if bufnr and winid and api.nvim_win_get_buf(winid) ~= bufnr then
        return false
      end
    end
  end
end
