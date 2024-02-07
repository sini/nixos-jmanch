{ lib
, pkgs
, config
, username
, ...
} @ args:
let
  inherit (lib) mkIf mkMerge mkVMOverride;
  cfg = config.modules.system.virtualisation;
in
mkMerge [
  {
    # We configure the vmVariant regardless of whether or not the host has
    # virtualisation enabled because it is possible to create a vm of any host
    virtualisation.vmVariant = {
      device = mkVMOverride {
        monitors = [{
          name = "Virtual-1";
          number = 1;
          refreshRate = 60.0;
          width = 1920;
          height = 1080;
          position = "0x0";
          workspaces = [ 1 2 3 4 5 6 7 8 9 ];
        }];
        gpu.type = null;
      };

      modules = {
        system = {
          networking = {
            tcpOptimisations = mkVMOverride false;
            wireless.enable = mkVMOverride false;
            firewall.enable = mkVMOverride false;
          };
          bluetooth.enable = mkVMOverride false;
          audio.enable = mkVMOverride false;
          virtualisation.enable = mkVMOverride false;
        };
      };

      users.users.${username} = {
        password = mkVMOverride "test";
        hashedPasswordFile = mkVMOverride null;
      };

      home-manager.extraSpecialArgs = mkIf config.usrEnv.homeManager.enable { vmVariant = true; };

      virtualisation =
        let
          desktopEnabled = config.usrEnv.desktop.enable;
        in
        {
          # TODO: Make this modular based on host spec. Ideally would base this
          # on the host we are running the VM on but I don't think that's
          # possible? Could be logical to simulate the exact specs of the host
          # we are replicating, although that won't always be feasible
          # depending the actual host we are running the vm on. Could work
          # around this by instead modifying the generated launch script in our
          # run-vm zsh function.
          memorySize = 4096;
          cores = 8;
          graphics = desktopEnabled;
          qemu = {
            options = lib.lists.optionals desktopEnabled [
              # Allows nixos-rebuild build-vm graphical session
              # https://github.com/NixOS/nixpkgs/issues/59219
              "-device virtio-vga-gl"
              "-display gtk,show-menubar=off,gl=on"
            ];
          };
          # Forward all TCP and UDP ports that are opened in the firewall
          # Should make the majority of the VMs services accessible from host
          forwardPorts =
            let
              forward = proto: port: {
                from = "host";
                # Attempt to map host port to a unique value between 50000-65000
                # Might need manual intervention
                host = { port = (lib.trivial.mod port 15001) + 50000; address = "127.0.0.1"; };
                guest.port = port;
                proto = proto;
              };
            in
            lib.lists.map (forward "tcp") config.networking.firewall.allowedTCPPorts
            ++
            lib.lists.map (forward "udp") config.networking.firewall.allowedUDPPorts;
        };
    };
  }

  (mkIf cfg.enable {
    virtualisation = {
      libvirtd.enable = true;
    };
    programs.virt-manager.enable = true;
    users.users."${username}".extraGroups = [ "libvirtd" ];

    programs.zsh.interactiveShellInit =
      let
        grep = "${pkgs.gnugrep}/bin/grep";
        sed = "${pkgs.gnused}/bin/sed";
      in
        /* bash */ ''
        run-vm() {
          if [ -z "$1" ]; then
            echo "Usage: build-vm <hostname>"
            return 1
          fi
          # Build the VM
          runscript="/home/${username}/result/bin/run-$1-vm"
          cd && sudo nixos-rebuild build-vm --flake /home/${username}/.config/nixos#$1
          if [ $? -ne 0 ]; then return 1; fi

          # Print ports mapped to the VM
          echo "\nMapped Ports:\n$(${grep} -o 'hostfwd=[^,]*' $runscript | ${sed} 's/hostfwd=//g')"

          # Run non-graphical session in a new terminal window
          if grep -q -- "-nographic" "$runscript"; then
            ${if config.usrEnv.desktop.enable then
              "${(lib.utils.homeConfig args).modules.desktop.terminal} --class qemu -e $runscript"
            else "$runscript"}
          else
            $runscript
          fi
        }
      '';

    environment = {
      persistence."/persist".directories = [
        "/var/lib/libvirt"
      ];
    };
  })
]
