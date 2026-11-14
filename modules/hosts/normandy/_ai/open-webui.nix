# open-webui on http://localhost:8080. Settings come from Nix only: with
# persistent config off, the admin page can still change things but they
# reset on restart.
{
  config,
  pkgs,
  ...
}: let
  searxng = config.services.searx.settings.server;
  comfyui = config.services.comfyui;

  # The chat only offers a feature when the model's metadata lists the
  # capability, and ollama models have no metadata of their own.
  modelDefaults = {
    capabilities = {
      file_context = true;
      vision = true;
      file_upload = true;
      web_search = true;
      image_generation = true;
      code_interpreter = true;
      citations = true;
      status_updates = true;
      memory = true;
      builtin_tools = true;
    };
    # Image generation stays a per-chat toggle so it doesn't fight the chat
    # model for VRAM unless asked.
    defaultFeatureIds = ["web_search" "code_interpreter"];
  };

  # Which inputs of z-image-turbo.json open-webui fills in per request.
  workflowNodes = [
    {
      type = "prompt";
      key = "text";
      node_ids = ["5"];
    }
    {
      type = "model";
      key = "unet_name";
      node_ids = ["1"];
    }
    {
      type = "width";
      key = "width";
      node_ids = ["7"];
    }
    {
      type = "height";
      key = "height";
      node_ids = ["7"];
    }
    {
      type = "n";
      key = "batch_size";
      node_ids = ["7"];
    }
    {
      type = "steps";
      key = "steps";
      node_ids = ["8"];
    }
    {
      type = "seed";
      key = "seed";
      node_ids = ["8"];
    }
  ];
in {
  services.open-webui = {
    enable = true;
    # Unstable's python3Packages.posthog is marked broken against mcp 2.x.
    package = pkgs.stable.open-webui;
    environment = {
      SCARF_NO_ANALYTICS = "True";
      DO_NOT_TRACK = "True";
      ANONYMIZED_TELEMETRY = "False";

      ENABLE_PERSISTENT_CONFIG = "False";
      OLLAMA_BASE_URL = "http://127.0.0.1:${toString config.services.ollama.port}";
      DEFAULT_MODELS = "qwen3.8:27b";
      DEFAULT_MODEL_METADATA = builtins.toJSON modelDefaults;

      ENABLE_WEB_SEARCH = "True";
      WEB_SEARCH_ENGINE = "searxng";
      SEARXNG_QUERY_URL = "http://${searxng.bind_address}:${toString searxng.port}/search";
      WEB_SEARCH_RESULT_COUNT = "5";

      # pyodide runs the model's Python in the browser, not on normandy.
      ENABLE_CODE_INTERPRETER = "True";
      CODE_INTERPRETER_ENGINE = "pyodide";

      ENABLE_IMAGE_GENERATION = "True";
      IMAGE_GENERATION_ENGINE = "comfyui";
      COMFYUI_BASE_URL = "http://127.0.0.1:${toString comfyui.port}";
      COMFYUI_WORKFLOW = builtins.readFile ./z-image-turbo.json;
      COMFYUI_WORKFLOW_NODES = builtins.toJSON workflowNodes;
      IMAGE_GENERATION_MODEL = "z_image_turbo_bf16.safetensors";
      IMAGE_SIZE = "1024x1024";
      # Turbo is distilled for 8 steps; more doesn't help.
      IMAGE_STEPS = "8";
    };
  };

  environment.persistence."/persist".directories = [
    # DynamicUser, so accounts and chat history live under /var/lib/private.
    "/var/lib/private/open-webui"
  ];
}
