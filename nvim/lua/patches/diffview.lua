-- Override diffview's PathLib:expand so a `$<name>` segment that isn't an
-- env var stays literal instead of having its `$` stripped. Without this,
-- Remix dynamic-route paths like `programs+/$programId+/foo.tsx` get
-- corrupted to `programs+/programId+/foo.tsx`, and the file renders as
-- fully deleted in any diffview window.
--
-- Upstream PR: https://github.com/sindrets/diffview.nvim/pull/557
-- Drop this file once that PR lands and the lockfile is bumped past it.

return function()
  local PathLib = require("diffview.path").PathLib
  local uv = vim.loop

  function PathLib:expand(path)
    local segments = self:explode(path)
    local idx = 1

    if segments[1] == "~" then
      segments[1] = uv.os_homedir()
      idx = 2
    end

    for i = idx, #segments do
      local env_var = segments[i]:match("^%$(%S+)$")
      if env_var then
        local val = uv.os_getenv(env_var)
        if val then
          segments[i] = val
        end
      end
    end

    return self:join(unpack(segments))
  end
end
