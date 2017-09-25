oc_logging_netconfig:
  netconfig.managed:
    - template_name: salt://logging/templates/init.jinja
    - {{ salt.pillar.get('openconfig-system-logging') }}
