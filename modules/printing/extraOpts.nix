{ ... }:
{ }
#{
#  config,
#  lib,
#  pkgs,
#  ...
#}:
#/*
#  script for adding a class
#
#  # add _tmp dummy printer
#  lpadmin -p _tmp -v lpd:// -m raw
#
#  # add dummy printer to new class
#  lpadmin -p _tmp -c <className>
#
#  # add location and description, if they exist
#  lpadmin -p <className> -D <description> -L <location>
#
#  # remove dummy printer from class, now we have an empty class
#  lpadmin -x _tmp
#*/
#let
#  cfg = config.hardware.printers;
#in
#{
#  options.hardware.printers.ensureClasses =
#    with lib;
#    mkOption {
#      description = ''
#        Will regularly ensure that the given CUPS classes are configured as declared. Any manual
#        overrides to the classes declared here will be overridden eventually. This configuration will
#        not delete any classes that have been removed from the list. I order to list classes you can
#        use {command}`lpstat -c`. It will list any classes without members as having a member titled
#        `unknown`. Print jobs to empty classes will silently fail. In order to remove a class, run
#        {command}`lpadmin -x <class name>`. Classes can still be added manually. For more on classes
#        see <https://www.cups.org/doc/admin.html#CLASSES>, or {command}`man lpadmin`.
#      '';
#      type = types.attrsOf (
#        types.submodule {
#          options = {
#            description = mkOption {
#              type = types.nullOr types.str;
#              description = "Optional human-readable description";
#              example = "Printers that support color printing";
#            };
#            location = mkOption {
#              type = types.nullOr types.str;
#              description = "Optional human-readable location";
#              example = "Workroom";
#            };
#            printers = mkOption {
#              type = types.listOf types.str;
#              default = [ ];
#              description = ''
#                A list of printers included in this class. Warning: Print jobs to this class will
#                quietly fail if there are no printers in this class. CUPS reports them as pending
#              '';
#            };
#            classes = mkOption {
#              type = types.listOf types.str;
#              default = [ ];
#              description = ''
#                A list of classes to include in this class. Please note that CUPS itself does not
#                support nested classes. Any classes will simply have all of their member printers
#                added to this class in a recursive manner. This is an abstraction that serves the
#                purpose of convenience and expressiveness, not a 1:1 mapping on top of CUPS.
#              '';
#            };
#          };
#        }
#      );
#    };
#  config =
#    let
#      # we need them to be ordered
#      mkArg = k: v: { inherit k v; };
#      mkArgs =
#        args:
#        lib.pipe args [
#          (lib.lists.filter ({ k, v }: k != null && v != null))
#          (map ({ k, v }: "-${k} \"${v}\""))
#          (lib.concatStringsSep " ")
#        ];
#      lpAdmin = args: "lpadmin ${mkArgs args}";
#      getPrinters =
#        class:
#        assert lib.assertMsg (cfg.ensureClasses ? ${class}) "class \"${class}\" does not exist";
#        let
#          inherit (cfg.ensureClasses.${class})
#            classes
#            printers
#            ;
#          classPrinters = (map (getPrinters) classes);
#        in
#        lib.lists.unique (printers ++ (lib.lists.flatten classPrinters));
#      mkClass =
#        name:
#        lib.concatStringsSep "\n" ([
#          # create dummy printer
#          (lpAdmin [
#            (mkArg "p" "_tmp")
#            (mkArg "v" "socket://") # another protocol can be used, this use just works
#            (mkArg "m" "raw")
#          ])
#
#          # add dummy printer to class (only way to create a class is to add a printer to it as if it exists, it will then be created)
#          (lpAdmin [
#            (mkArg "p" "_tmp")
#            (mkArg "c" name)
#          ])
#
#          # remove dummy printer from class. the class will not be deleted
#          (lpAdmin [
#            (mkArg "x" "_tmp")
#          ])
#        ]);
#
#      populateClass =
#        name:
#        {
#          description ? null,
#          location ? null,
#          ...
#        }:
#        lib.optionalString (location != null || description != null) (lpAdmin [
#          (mkArg "p" name)
#          (mkArg "D" description)
#          (mkArg "L" location)
#        ]);
#
#      addPrintersToClass =
#        className: class:
#        let
#          printers = getPrinters className;
#          addToClass =
#            printer:
#            lpAdmin [
#              (mkArg "p" printer)
#              (mkArg "c" className)
#            ];
#        in
#        map addToClass printers;
#
#      enableClass = className: ''
#        cupsenable "${className}"
#        cupsaccept "${className}"
#      '';
#    in
#    {
#      systemd.services.ensure-classes = {
#        description = "Ensure NixOS-configured CUPS classes";
#        wantedBy = [ "multi-user.target" ];
#        wants = [
#          "cups.service"
#        ];
#        after = [
#          "cups.service"
#          "ensure-printers.service"
#        ];
#        serviceConfig = {
#          Type = "oneshot";
#          RemainAfterExit = true;
#        };
#        path = with pkgs; [ cups ];
#        script =
#          let
#            attrMap = fn: l: map fn (builtins.attrNames l);
#            concatNL = l: lib.concatStringsSep "\n" l;
#            classDefs = lib.pipe cfg.ensureClasses [
#              (attrMap mkClass)
#              concatNL
#            ];
#            classAdds = lib.pipe cfg.ensureClasses [
#              (lib.mapAttrsToList addPrintersToClass)
#              lib.flatten
#              concatNL
#            ];
#            populatedClasses = lib.pipe cfg.ensureClasses [
#              (lib.mapAttrsToList populateClass)
#              concatNL
#            ];
#            enables = lib.pipe cfg.ensureClasses [
#              (attrMap enableClass)
#              concatNL
#            ];
#          in
#          ''
#            #### CLASS DEFINITIONS ####
#            ${classDefs}
#
#            #### ADDING PRINTERS TO CLASSES ####
#            ${classAdds}
#
#            #### POPULATING CLASSES ####
#            ${populatedClasses}
#
#            #### ENABLING CLASSES ####
#            ${enables}
#          '';
#      };
#    };
#}
