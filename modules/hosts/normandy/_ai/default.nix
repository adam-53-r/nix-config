# Local AI playground: ollama (rocm) for chat and code, open-webui in front of
# it, SearXNG for web search and ComfyUI for image generation. Everything
# listens on localhost only.
#
# The 9070 XT's 16G of VRAM fits one big model at a time, so a chat model and
# an image model take turns rather than running side by side.
{...}: {
  imports = [
    ./ollama.nix
    ./open-webui.nix
    ./searxng.nix
    ./comfyui.nix
  ];
}
