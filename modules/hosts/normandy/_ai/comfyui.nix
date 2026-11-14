# ComfyUI for image generation. open-webui drives it through
# z-image-turbo.json; anything else (video, audio, other models) is for
# playing with in its own UI on http://localhost:8188.
{pkgs, ...}: let
  zImageTurbo = "https://huggingface.co/Comfy-Org/Z-Image-Turbo/resolve/6fc90a3b1b653e935a0d175e260736de25b84df5/split_files";
in {
  services.comfyui = {
    enable = true;
    package = pkgs.pkgsRocm.comfyui;
    # Move models back to RAM after each run so ollama can have the VRAM.
    extraArgs = ["--disable-smart-memory"];
    models = [
      {
        name = "z_image_turbo_bf16.safetensors";
        url = "${zImageTurbo}/diffusion_models/z_image_turbo_bf16.safetensors";
        hash = "sha256-JAdhMFC4Cf/f8YpKyZr4Pqa5VEPs69+A4GSnnIJVdKY=";
        installPaths = "diffusion_models";
      }
      {
        name = "qwen_3_4b.safetensors";
        url = "${zImageTurbo}/text_encoders/qwen_3_4b.safetensors";
        hash = "sha256-bGcUmFc6wvelUBUCzM6NKwjqbKL2YcRY5wjzazbt/Fo=";
        installPaths = "text_encoders";
      }
      {
        name = "ae.safetensors";
        url = "${zImageTurbo}/vae/ae.safetensors";
        hash = "sha256-r8jignLNFds5GbrNtpGM6cHtIulssSxNXtD7qCNSnjg=";
        installPaths = "vae";
      }
    ];
  };

  environment.persistence."/persist".directories = [
    {
      directory = "/var/lib/comfyui";
      user = "comfyui";
      group = "comfyui";
      mode = "0700";
    }
  ];
}
