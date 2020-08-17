{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.sumologic;
  isEmpty = v: builtins.isNull v || (builtins.isList v && builtins.length v == 0) || (builtins.isAttrs v && builtins.length (pkgs.lib.attrsets.attrValues v) == 0);
  tidy = s: pkgs.lib.attrsets.filterAttrs (n: v: !(isEmpty v)) s;
in {
  options.services.sumologic = {
    enable = mkEnableOption "SumoLogic Collector Service";

    package = mkOption {
      type = types.package;
      default = pkgs.sumologic;
      defaultText = "pkgs.sumologic";
    };

    accessId = mkOption {
      type = types.nullOr types.str;
      default = null;
    };

    accessKey = mkOption {
      type = types.nullOr types.str;
      default = null;
    };

    ephemeral = mkOption {
      type = types.bool;
      default = true;
    };

    token = mkOption {
      type = types.nullOr types.str;
      default = null;
    };

    url = mkOption {
      type = types.nullOr types.str;
      default = null;
    };

    sources = mkOption {
      type = types.listOf (types.submodule {
        options = {
          name = mkOption {
            type = types.nullOr types.str;
            default = null;
          };

          sourceType = mkOption {
            type = types.enum [ "LocalFile" "RemoteFileV2" "Syslog" "Script" "DockerLog" "DockerStats" "SystemStats" "StreamingMetrics" ];
            default = "LocalFile";
          };

          description = mkOption {
            type = types.nullOr types.str;
            default = null;
          };

          hostName = mkOption {
            type = types.nullOr types.str;
            default = null;
          };

          category = mkOption {
            type = types.nullOr types.str;
            default = null;
          };

          fields = mkOption {
            type = types.attrsOf types.str;
            default = {};
          };

          automaticDateParsing = mkOption {
            type = types.bool;
            default = true;
          };

          timeZone = mkOption {
            type = types.nullOr types.str;
            default = null;
          };

          forceTimeZone = mkOption {
            type = types.bool;
            default = false;
          };

          defaultDateFormat = mkOption {
            type = types.nullOr types.str;
            default = null;
          };

          defaultDateFormats = mkOption {
            type = types.nullOr (types.listOf (types.submodule {
              format = mkOption {
                type = types.str;
              };
              locator = mkOption {
                type = types.nullOr types.str;
                default = null;
              };
            }));
            default = null;
          };

          multilineProcessingEnabled = mkOption {
            type = types.bool;
            default = true;
          };

          useAutolineMatching = mkOption {
            type = types.bool;
            default = true;
          };

          manualPrefixRegexp = mkOption {
            type = types.nullOr types.str;
            default = null;
          };

          filters = mkOption {
            type = types.listOf types.str;
            default = [];
          };

          cutoffTimestamp = mkOption {
            type = types.nullOr types.ints.positive;
            default = null;
          };

          cutoffRelativeTime = mkOption {
            type = types.nullOr types.str;
            default = null;
          };

          pathExpression = mkOption {
            type = types.nullOr types.str;
            default = null;
          };

          blacklist = mkOption {
            type = types.listOf types.str;
            default = [];
          };

          encoding = mkOption {
            type = types.str;
            default = "UTF-8";
          };

          remoteHosts = mkOption {
            type = types.listOf types.str;
            default = [];
          };

          remotePort = mkOption {
            type = types.nullOr types.ints.positive;
            default = null;
          };

          remoteUser = mkOption {
            type = types.nullOr types.str;
            default = null;
          };

          remotePassword = mkOption {
            type = types.nullOr types.str;
            default = null;
          };

          keyPath = mkOption {
            type = types.nullOr types.str;
            default = null;
          };

          keyPassword = mkOption {
            type = types.nullOr types.str;
            default = null;
          };

          authMethod = mkOption {
            type = types.nullOr types.str;
            default = null;
          };

          protocol = mkOption {
            type = types.nullOr (types.enum ["UDP" "TCP"]);
            default = null;
          };

          port = mkOption {
            type = types.nullOr types.ints.positive;
            default = null;
          };

          commands = mkOption {
            type = types.nullOr (types.listOf types.str);
            default = null;
          };

          file = mkOption {
            type = types.nullOr types.str;
            default = null;
          };

          workingDir = mkOption {
            type = types.nullOr types.str;
            default = null;
          };

          timeout = mkOption {
            type = types.nullOr types.ints.positive;
            default = null;
          };

          script = mkOption {
            type = types.nullOr types.str;
            default = null;
          };

          cronExpression = mkOption {
            type = types.nullOr types.str;
            default = null;
          };

          uri = mkOption {
            type = types.nullOr types.str;
            default = null;
          };

          specifiedContainers = mkOption {
            type = types.nullOr (types.listOf types.str);
            default = null;
          };

          allContainers = mkOption {
            type = types.nullOr types.bool;
            default = null;
          };

          certPath = mkOption {
            type = types.nullOr types.str;
            default = null;
          };

          collectEvents = mkOption {
            type = types.nullOr types.bool;
            default = null;
          };

          contentTypes = mkOption {
            type = types.nullOr types.str;
            default = null;
          };

          metrics = mkOption {
            type = types.nullOr (types.listOf types.str);
            default = null;
          };

          pollInterval = mkOption {
            type = types.nullOr types.ints.positive;
            default = null;
          };

          interval = mkOption {
            type = types.nullOr types.ints.positive;
            default = null;
          };
        };
      });
      default = [];
    };
  };

  config = mkIf cfg.enable {
    users.users.sumologic = {
      isSystemUser = true;
      description = "SumoLogic Collector user";
    };

    environment.etc = {
      "sumologic/wrapper.conf".source = "${cfg.package}/config-static/wrapper.conf";
      "sumologic/wrapper-license.conf".source = "${cfg.package}/config-static/wrapper-license.conf";
      "sumologic/log4j2.xml".source = "${cfg.package}/config-static/log4j2.xml";
      "sumologic/user.properties".source = pkgs.writeText "sumologic-collector-user.properties" ''
        ${if cfg.accessId != null then "accessid = ${cfg.accessId}" else ""}
        ${if cfg.accessKey != null then "accesskey = ${cfg.accessKey}" else ""}
        ${if cfg.token != null then "token = ${cfg.token}" else ""}
        ${if cfg.url != null then "url = ${cfg.url}" else ""}
        wrapper.java.command = ${pkgs.adoptopenjdk-jre-bin}/bin/java
        ephemeral = ${if cfg.ephemeral then "true" else "false"}
        skipAccessKeyRemoval = true
        disableUpgrade = true
        syncSources = /etc/sumologic/sources.json
      '';
      "sumologic/sources.json".source = pkgs.writeText "sumologic-collector-sources.json" (builtins.toJSON { sources = builtins.map tidy cfg.sources; "api.version" = "v1"; });
    };

    systemd.services.sumologic = {
      description = "SumoLogic Collector";
      after = [ "syslog.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.coreutils pkgs.gettext pkgs.procps pkgs.adoptopenjdk-jre-bin pkgs.nix ];
      preStart = ''
        for cfgfile in /etc/sumologic/*; do
          if [ ! -f "$STATE_DIRECTORY/''${cfgfile#/etc/sumologic/}" ]; then
            ln -s "$cfgfile" "$STATE_DIRECTORY/''${cfgfile#/etc/sumologic/}"
          fi
        done
        touch "$STATE_DIRECTORY/collector.properties"
        for d in alerts cache metrics-cache sink-cache data; do
          mkdir -p "$STATE_DIRECTORY/$d"
        done
      '';
      restartTriggers = [
        config.environment.etc."sumologic/sources.json".source
      ];
      serviceConfig = {
        User = "sumologic";
        ExecStart = "${cfg.package}/collector start sysd";
        ExecStop = "${cfg.package}/collector stop sysd";
        Type = "forking";
        LogsDirectory = "sumologic";
        RuntimeDirectory = "sumologic";
        ConfigurationDirectory = "sumologic";
        StateDirectory = "sumologic";
      };
      environment = {
        NIX_PATH = "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos:nixos-config=/etc/nixos/configuration.nix:/nix/var/nix/profiles/per-user/root/channels";
        JAVA_COMMAND_LOCATION = "${pkgs.adoptopenjdk-jre-bin}/bin/java";
      };
    };
  };
}
