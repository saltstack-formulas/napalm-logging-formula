oc_logging_netconfig_test:
  file.managed:
    - name: /tmp/__salt_logging_{{ opts.id }}.txt
    - source: salt://logging/templates/init.jinja
    - template: jinja
    - skip_verify: False
    - {{ salt.pillar.get('openconfig-system-logging') }}
file.read:
  module.run:
    - path: /tmp/__salt_logging_{{ opts.id }}.txt
