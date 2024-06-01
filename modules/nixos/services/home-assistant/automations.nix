{ lib, config, inputs, ... }:
let
  inherit (lib) mkIf utils head optional optionals attrValues;
  inherit (secretCfg) devices;
  inherit (inputs.nix-resources.secrets) fqDomain;
  inherit (config.modules.services) frigate;
  cfg = config.modules.services.hass;
  secretCfg = inputs.nix-resources.secrets.hass { inherit lib config; };

  frigateEntranceNotify = {
    alias = "Entrance Person Notify";
    use_blueprint = {
      path = "SgtBatten/frigate_notifications.yaml";
      input = {
        camera = "camera.driveway";
        notify_device = (head (attrValues devices)).id;
        notify_group = "All Notify Devices";
        base_url = "https://home.${fqDomain}";
        group = "{{camera}}-frigate-notification";
        title = "Security Alert";
        message = "A person was detected in the entrance";
        update_thumbnail = true;
        alert_once = true;
        zone_filter = true;
        zones = [ "entrance" ];
        labels = [ "person" ];
      };
    };
  };

  frigateHighAlertNotify = map
    (camera: {
      alias = "High Alert ${utils.upperFirstChar camera} Notify";
      use_blueprint = {
        path = "SgtBatten/frigate_notifications.yaml";
        input = {
          camera = "camera.${camera}";
          state_filter = true;
          state_entity = "input_boolean.high_alert_surveillance";
          state_filter_states = [ "on" ];
          notify_device = (head (attrValues devices)).id;
          sticky = true;
          notify_group = "All Notify Devices";
          group = "{{camera}}-frigate-notification";
          base_url = "https://home.${fqDomain}";
          title = "Security Alert";
          ios_live_view = "camera.${camera}";
          message = "A person was detected on the property";
          color = "#f44336";
          update_thumbnail = true;
        };
      };
    }) [ "driveway" "poolhouse" ];

  heatingTimeToggle = map
    (enable:
      let
        stringMode = if enable then "enable" else "disable";
        oppositeMode = if enable then "disable" else "enable";
      in
      {
        alias = "Heating ${if enable then "Enable" else "Disable"}";
        mode = "single";
        trigger = [
          {
            platform = "homeassistant";
            event = "start";
          }
          {
            platform = "time";
            at = "input_datetime.heating_${stringMode}_time";
          }
        ];
        condition =
          let
            timeCond = {
              condition = "time";
              after = "input_datetime.heating_${stringMode}_time";
              before = "input_datetime.heating_${oppositeMode}_time";
            };
          in
          optional (!enable) timeCond
          ++
          optional enable {
            condition = "and";
            conditions = [
              timeCond
              {
                condition = "state";
                entity_id = "input_boolean.heating_enabled";
                state = "on";
              }
            ];
          }
        ;
        action = [{
          service = "climate.set_hvac_mode";
          metadata = { };
          data = {
            hvac_mode = if enable then "heat" else "off";
          };
          target.entity_id = [
            "climate.joshua_thermostat"
            "climate.hallway"
          ];
        }];
      }) [ true false ];

  joshuaDehumidifierTankFull = [{
    alias = "Joshua Dehumidifier Full Notify";
    mode = "single";
    trigger = [{
      platform = "state";
      entity_id = "sensor.joshua_dehumidifier_tank_status";
      to = "Full";
      for.minutes = 1;
    }];
    condition = [ ];
    action = [{
      service = "notify.mobile_app_joshua_pixel_5";
      data = {
        title = "Dehumidifier";
        message = "Tank full";
      };
    }];
  }];

  joshuaDehumidifierMoldToggle = map
    (enable: {
      alias = "Joshua Dehumidifier ${if enable then "Enable" else "Disable"}";
      mode = "single";
      trigger = [{
        platform = "numeric_state";
        entity_id = [ "sensor.joshua_mold_indicator" ];
        above = mkIf enable 73;
        below = mkIf (!enable) 67;
        for.minutes = if enable then 0 else 30;
      }];
      condition = [ ];
      action = [{
        service = "switch.turn_${if enable then "on" else "off"}";
        target.entity_id = "switch.joshua_dehumidifier";
      }];
    }) [ true false ];

  joshuaLightsToggle = map
    (enable: {
      alias = "Joshua Lights ${if enable then "On" else "Off"}";
      mode = "single";
      trigger = [
        {
          platform = "state";
          entity_id = [ "binary_sensor.brightness_threshold" ];
          from = if enable then "on" else "off";
          to = if enable then "off" else "on";
        }
        {
          platform = "state";
          entity_id = [ "binary_sensor.ncase_m1_active" ];
          from = if enable then "off" else "on";
          to = if enable then "on" else "off";
          for.seconds = if enable then 0 else 30;
        }
      ]
      ++ optional enable {
        platform = "template";
        value_template = "{{ now().timestamp() == (${joshuaWakeUpTimestamp} - 60*60) }}";
      };
      condition =
        let
          mainCondition = {
            condition = if enable then "and" else "or";
            conditions = [
              {
                condition = "state";
                entity_id = "binary_sensor.brightness_threshold";
                state = if enable then "off" else "on";
              }
              {
                condition = "state";
                entity_id = "binary_sensor.ncase_m1_active";
                state = if enable then "on" else "off";
              }
            ];
          };
          wakeUpCondition = {
            condition = "or";
            conditions = [
              mainCondition
              {
                condition = "and";
                conditions = [
                  {
                    condition = "template";
                    value_template = "{{ now().timestamp() == (${joshuaWakeUpTimestamp} - 60*60) }}";
                  }
                  {
                    condition = "state";
                    entity_id = "input_boolean.joshua_room_wake_up_lights";
                    state = "on";
                  }
                ];
              }
            ];
          };
        in
        optional (!enable) mainCondition
        ++ optional enable wakeUpCondition;
      action = [{
        service = "light.turn_${if enable then "on" else "off"}";
        target.entity_id = "light.joshua_room";
      }];
    }) [ true false ];

  joshuaSleepTimestamp = "((as_timestamp(states('sensor.joshua_pixel_5_next_alarm')) | default(0)) + 16*60*60)";
  joshuaWakeUpTimestamp = "(as_timestamp(states('sensor.joshua_pixel_5_next_alarm')) | default(0))";

  joshuaAdaptiveLightingSunTimes = [{
    alias = "Joshua Room Lighting Sun Times";
    mode = "single";
    trigger = [
      {
        platform = "state";
        entity_id = [ "sensor.joshua_pixel_5_next_alarm" ];
      }
      {
        platform = "homeassistant";
        event = "start";
      }
    ];
    action = [{
      "if" = [{
        condition = "or";
        conditions = [
          { condition = "state"; entity_id = "sensor.joshua_pixel_5_next_alarm"; state = "unavailable"; }
          { condition = "state"; entity_id = "sensor.joshua_pixel_5_next_alarm"; state = "unknown"; }
        ];
      }];
      "then" = [{
        service = "adaptive_lighting.change_switch_settings";
        data = {
          entity_id = "switch.adaptive_lighting_joshua_room";
          use_default = "configuration";
        };
      }];
      "else" = [{
        service = "adaptive_lighting.change_switch_settings";
        data = {
          use_defaults = "configuration";
          entity_id = "switch.adaptive_lighting_joshua_room";
          sunrise_time = "{{ ${joshuaWakeUpTimestamp} | timestamp_custom('%H:%M:%S') }}";
          sunset_time = "{{ ${joshuaSleepTimestamp} | timestamp_custom('%H:%M:%S') }}";
        };
      }];
    }];
  }];

  joshuaSleepModeToggle = map
    (enable: {
      alias = "Joshua Room Sleep Mode ${if enable then "Enable" else "Disable"}";
      mode = "single";
      trigger = [
        {
          platform = "state";
          entity_id = [ "sensor.joshua_pixel_5_next_alarm" ];
        }
        {
          platform = "template";
          value_template = if enable then "{{ now().timestamp() == ${joshuaSleepTimestamp} }}" else
          "{{ now().timestamp() == (${joshuaWakeUpTimestamp} - 60*60) }}";
        }
        {
          platform = "state";
          entity_id = [ "binary_sensor.ncase_m1_active" ];
          from = if enable then "on" else "off";
          to = if enable then "off" else "on";
          for.minutes = if enable then 5 else 0;
        }
        {
          platform = "homeassistant";
          event = "start";
        }
      ];
      condition = [{
        condition = "template";
        value_template = if enable then "{{ now().timestamp() >= ${joshuaSleepTimestamp} and now().timestamp() < (${joshuaWakeUpTimestamp} - 60*60) }}" else
        "{{ now().timestamp() >= (${joshuaWakeUpTimestamp} - 60*60) and now().timestamp() < ${joshuaSleepTimestamp} }}";
      }] ++ optional enable {
        condition = "state";
        entity_id = "binary_sensor.ncase_m1_active";
        state = "off";
        for.minutes = 5;
      };
      action = [{
        service = "switch.turn_${if enable then "on" else "off"}";
        target.entity_id = "switch.adaptive_lighting_sleep_mode_joshua_room";
      }];
    }) [ true false ];
in
mkIf cfg.enableInternal
{
  services.home-assistant.config = {
    automation = heatingTimeToggle
      ++ joshuaDehumidifierMoldToggle
      ++ joshuaDehumidifierTankFull
      ++ joshuaLightsToggle
      ++ joshuaAdaptiveLightingSunTimes
      ++ joshuaSleepModeToggle
      ++ optional frigate.enable frigateEntranceNotify
      ++ optionals frigate.enable frigateHighAlertNotify;

    input_datetime = {
      heating_disable_time = {
        name = "Heating Disable Time";
        has_time = true;
      };

      heating_enable_time = {
        name = "Heating Enable Time";
        has_time = true;
      };
    };

    input_boolean = {
      heating_enabled = {
        name = "Heating Enabled";
        icon = "mdi:heating-coil";
      };

      high_alert_surveillance = {
        name = "High Alert Surveillance";
        icon = "mdi:cctv";
      };

      joshua_room_wake_up_lights = {
        name = "Joshua Room Wake Up Lights";
        icon = "mdi:weather-sunset-up";
      };
    };
  };
}
