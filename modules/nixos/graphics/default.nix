{ lib, config, ... }:
let
  facterLib = import ../../../lib/lib.nix lib;
  cfg = config.facter.detected.graphics;
in
{
  imports = [
    ./amd.nix
  ];
  options.facter.detected = {
    graphics.enable = lib.mkEnableOption "Enable the Graphics module" // {
      default = builtins.length (config.facter.report.hardware.monitor or [ ]) > 0;
      defaultText = "hardware dependent";
    };
    boot.graphics.kernelModules = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      # We currently don't auto import nouveau, in case the user might want to use the proprietary nvidia driver,
      # We might want to change this in future, if we have a better idea, how to handle this.
      default = lib.remove "nouveau" (
        facterLib.stringSet (facterLib.collectDrivers (config.facter.report.hardware.graphics_card or [ ]))
      );
      defaultText = "hardware dependent";
      description = ''
        List of kernel modules to load at boot for the graphics card.
      '';
    };
  };

  config = lib.mkIf cfg.enable (
    {
      boot.initrd.kernelModules = config.facter.detected.boot.graphics.kernelModules;
    }
    // (
      if lib.versionOlder lib.version "24.11pre" then
        { hardware.opengl.enable = lib.mkDefault true; }
      else
        { hardware.graphics.enable = lib.mkDefault true; }
    )
  );
}
