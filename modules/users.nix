{ lib, ... }:

let
  trustedKeys = [
    # Primary public SSH key (Richard)
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBFMhAwmth99uLCtyQx9qr/oQn1nRfQY5vpTnpLFBacL"
  ];
in
{
  # Harden and enable OpenSSH daemon across all ecosystem hosts
  services.openssh = {
    enable = true;
    settings = {
      # Allow SSH keys only; strictly prohibit password authentication
      PermitRootLogin = lib.mkDefault "prohibit-password";
      PasswordAuthentication = lib.mkDefault false;
    };
  };

  # Authorize trusted keys for root on all machines
  users.users.root.openssh.authorizedKeys.keys = trustedKeys;
}
