{
  config,
  lib,
  pkgs,
  ...
}: let
  ollama = lib.getExe config.services.ollama.package;

  # Derived models so open-webui and opencode both get the right context size
  # and prompt without per-client settings. opencode talks to ollama's
  # OpenAI-compatible API, which can't pass num_ctx.
  presets = {
    coder = pkgs.writeText "coder.Modelfile" ''
      FROM qwen3-coder:30b
      PARAMETER num_ctx 65536
      SYSTEM """You are a senior software engineer. Write complete, working code that matches the style of any code you are shown. Prefer small, readable changes over clever ones, and say which files and lines you would change. If a request is ambiguous, state the assumption you made."""
    '';
    reviewer = pkgs.writeText "reviewer.Modelfile" ''
      FROM qwen3.8:27b
      PARAMETER num_ctx 32768
      SYSTEM """You are reviewing code changes for a colleague. Look for bugs first: wrong logic, unhandled errors and edge cases, races, security problems, resource leaks. Then mention anything that will be hard to maintain. For each finding give the file and line, what goes wrong and in which situation, and a concrete fix. Rank findings by severity and skip praise and style nits. If you find nothing wrong, say so plainly."""
    '';
  };
in {
  services.ollama = {
    enable = true;
    package = pkgs.ollama-rocm;
    loadModels = [
      "qwen3.8:27b"
      # MoE with 3B active params, so it stays fast even though it spills past VRAM.
      "qwen3-coder:30b"
    ];
    environmentVariables = {
      OLLAMA_FLASH_ATTENTION = "1";
      # Halves the KV cache, which keeps long contexts mostly on the GPU.
      OLLAMA_KV_CACHE_TYPE = "q8_0";
      OLLAMA_CONTEXT_LENGTH = "32768";
      # Two of these never fit at once; evict instead of splitting both onto the CPU.
      OLLAMA_MAX_LOADED_MODELS = "1";
    };
  };

  systemd.services.ollama-presets = {
    description = "Create the coder and reviewer ollama models";
    wantedBy = ["multi-user.target"];
    after = ["ollama.service" "ollama-model-loader.service"];
    bindsTo = ["ollama.service"];
    environment.OLLAMA_HOST = config.systemd.services.ollama.environment.OLLAMA_HOST;
    script = lib.concatStringsSep "\n" (lib.mapAttrsToList (name: file: "${ollama} create ${name} -f ${file}") presets);
    serviceConfig = {
      Type = "oneshot";
      DynamicUser = true;
      # ollama isn't always accepting connections yet right after it starts.
      Restart = "on-failure";
      RestartSec = "30s";
      RestartMaxDelaySec = "30min";
      RestartSteps = "10";
    };
  };

  environment.persistence."/persist".directories = [
    "/var/lib/private/ollama"
  ];
}
