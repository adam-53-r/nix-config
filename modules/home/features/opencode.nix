# opencode, a terminal coding agent, pointed at the local ollama models
# (normandy's _ai). It discovers ollama on localhost by itself.
{...}: {
  flake.homeModules.homeOpencode = {
    lib,
    pkgs,
    ...
  }: {
    programs.opencode = {
      enable = true;
      validateFiles.config = true;
      settings = {
        model = "ollama/coder";
        share = "disabled";
        update = "disable";
        # The built-in search only knows paid APIs; SearXNG comes in over MCP.
        websearch = false;
        mcp.servers.searxng = {
          type = "local";
          command = [(lib.getExe pkgs.mcp-searxng)];
          environment.SEARXNG_URL = "http://127.0.0.1:8888";
        };
        agents.reviewer = {
          description = "Reviews code changes without editing them";
          mode = "all";
          model = "ollama/reviewer";
          permissions = [
            {
              action = "edit";
              resource = "*";
              effect = "deny";
            }
          ];
        };
        commands.review = {
          description = "Review uncommitted changes, or a given ref or range";
          agent = "reviewer";
          template = ''
            Review $ARGUMENTS. With no argument, review the uncommitted changes (`git diff HEAD`).
            Read the surrounding code where the diff alone doesn't show whether something is wrong.
            List bugs first, then maintainability problems, each with file, line, what breaks and a fix.
          '';
        };
      };
    };

    home.persistence."/persist".directories = [
      ".local/share/opencode"
      ".local/state/opencode"
    ];
  };
}
