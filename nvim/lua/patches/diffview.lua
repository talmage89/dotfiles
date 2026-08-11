-- Override diffview's PathLib:expand so a `$<name>` segment that isn't an
-- env var stays literal instead of having its `$` stripped. Without this,
-- Remix dynamic-route paths like `programs+/$programId+/foo.tsx` get
-- corrupted to `programs+/programId+/foo.tsx`, and the file renders as
-- fully deleted in any diffview window.
--
-- Upstream PR: https://github.com/sindrets/diffview.nvim/pull/557
-- Drop this file once that PR lands and the lockfile is bumped past it.
--
-- Also override GitAdapter.untracked_files to pass the view's pathspecs to
-- `ls-files`. Upstream ignores ctx.path_args there, so untracked files leak
-- into every pathspec-filtered view (which breaks diff-layers rings). Body
-- copied from upstream with only the path_args lines added.

local function patch_untracked_files()
  local async = require("diffview.async")
  local GitAdapter = require("diffview.vcs.adapters.git").GitAdapter
  local Job = require("diffview.job").Job
  local FileEntry = require("diffview.scene.file_entry").FileEntry
  local RevType = require("diffview.vcs.rev").RevType
  local utils = require("diffview.utils")
  local await = async.await

  -- Upstream only lists untracked files for index↔worktree views, which
  -- hides brand-new files from any rev-pinned review (and from diff-layers
  -- rings). Whenever the right side is the working tree, lift the rev gate;
  -- range diffs keep upstream behavior.
  local orig_show_untracked = GitAdapter.show_untracked
  function GitAdapter:show_untracked(opt)
    if opt and opt.revs and opt.revs.right.type == RevType.LOCAL then
      -- tbl_extend can't clear a key (nil overlay values are no-ops), so
      -- copy and remove the rev gate explicitly
      opt = vim.tbl_extend("force", {}, opt)
      opt.revs = nil
    end
    return orig_show_untracked(self, opt)
  end

  GitAdapter.untracked_files = async.wrap(function(self, left, right, opt, callback)
    local args = utils.vec_join(self:args(), "-c", "core.quotePath=false", "ls-files", "--others", "--exclude-standard")
    if next(self.ctx.path_args or {}) then
      args = utils.vec_join(args, "--", self.ctx.path_args)
    end

    local job = Job({
      command = self:bin(),
      args = args,
      cwd = self.ctx.toplevel,
      log_opt = { label = "GitAdapter:untracked_files()" },
    })

    local ok = await(job)

    if not ok then
      callback(job.stderr or {}, nil)
      return
    end

    -- a commit rev can't render a file it never contained; give untracked
    -- entries an empty left side instead
    local left_rev = left.type == RevType.STAGE and left or self.Rev.new_null_tree()

    local files = {}
    for _, s in ipairs(job.stdout) do
      table.insert(
        files,
        FileEntry.with_layout(opt.default_layout, {
          adapter = self,
          path = s,
          status = "?",
          kind = "working",
          revs = {
            a = left_rev,
            b = right,
          },
        })
      )
    end

    callback(nil, files)
  end)
end

return function()
  local PathLib = require("diffview.path").PathLib
  local uv = vim.loop

  patch_untracked_files()

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
