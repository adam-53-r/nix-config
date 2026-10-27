# Local LLM stack: ollama (rocm) behind open-webui.
{pkgs, ...}: {
  services.ollama = {
    enable = true;
    package = pkgs.ollama-rocm;
  };

  services.open-webui = {
    enable = true;
    # Unstable's python3Packages.posthog is marked broken against mcp 2.x.
    package = pkgs.stable.open-webui;
  };

  environment.persistence."/persist".directories = [
    "/var/lib/private/ollama"
    # open-webui runs with DynamicUser and keeps accounts/chat history under
    # /var/lib/private too; it was never persisted on main, so its state was
    # silently wiped on every reboot.
    "/var/lib/private/open-webui"
  ];
}
