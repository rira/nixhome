{ config, lib, ... }:

let
  cfg = config.diskConfig;
in
{
  options.diskConfig = {
    device = lib.mkOption {
      type = lib.types.str;
      default = "/dev/nvme0n1";
      description = "Target physical disk device (e.g. /dev/nvme0n1 or /dev/sda)";
    };
  };

  config = {
    disko.devices = {
      disk = {
        main = {
          type = "disk";
          device = cfg.device;
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                size = "512M";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [ "umask=0077" ];
                };
              };
              luks = {
                size = "100%";
                content = {
                  type = "luks";
                  name = "crypted";
                  settings = {
                    allowDiscards = true; # SSD TRIM support
                  };
                  content = {
                    type = "filesystem";
                    format = "ext4";
                    mountpoint = "/";
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
