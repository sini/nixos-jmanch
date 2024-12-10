{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    ns
    mkIf
    hiPrio
    mkBefore
    optional
    ;
  cfg = config.${ns}.hardware.graphics.amd;
  davinciResolve = config.hm.${ns}.programs.davinci-resolve.enable or false;
in
mkIf (config.${ns}.device.gpu.type == "amd") {
  boot.initrd.kernelModules = mkBefore [ "amdgpu" ];

  # Copied from https://github.com/Atemu/nixos-config/blob/7beb94aec277fb4cbf31360bdbd0a3e9e635a619/modules/amdgpu/module.nix
  # https://github.com/Atemu/nixos-config/blob/master/LICENSE
  boot.extraModulePackages = mkIf (cfg.kernelPatches != [ ]) [
    (pkgs.callPackage ./amdgpu-kernel-module.nix {
      inherit (config.boot.kernelPackages) kernel;
      patches = cfg.kernelPatches;
    })
  ];

  userPackages = [
    pkgs.amdgpu_top
    (hiPrio (
      pkgs.runCommand "amdgpu_top-desktop-rename" { } ''
        mkdir -p $out/share/applications
        substitute ${pkgs.amdgpu_top}/share/applications/amdgpu_top.desktop $out/share/applications/amdgpu_top.desktop \
          --replace-fail "Name=AMDGPU TOP (GUI)" "Name=AMDGPU Top"
      ''
    ))
  ];

  services.xserver.videoDrivers = [ "modesetting" ];

  # TODO: Use hardware.amdgpu option when I update my flake

  # Make radv the default driver
  environment.sessionVariables.AMD_VULKAN_ICD = "RADV";

  # There are two main AMD user drivers: AMDVLK and RADV. AMDVLK is the offical
  # open source driver provided by AMD whilst RADV is made by Valve. Depending
  # on the application, one may perform better than the other so it's useful to
  # have both installed and toggle between them. RADV is installed as part of
  # the Mesa driver package which is installed by default when
  # hardware.graphics is enabled. AMDVLK can be installed through the
  # extraPackages option. There is also the kernel module driver component
  # which is amdgpu.
  hardware.graphics = {
    enable = true;
    extraPackages = optional davinciResolve pkgs.rocmPackages.clr.icd;
  };

  persistenceHome.directories = [ ".cache/AMD" ];
}
