======================
napalm-logging-formula
======================

Salt formula to manage the logging configuration on network devices, managed via
`NAPALM <https://napalm-automation.net>`_,
either running under a `proxy minion <https://docs.saltstack.com/en/develop/ref/proxy/all/salt.proxy.napalm.html>`_,
or installing the ``salt-minion`` directly on the network device (if the operating system permits).

Check the `Salt Formulas instructions <https://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html>`_ to understand how to install and use formulas.

Available states
================

.. contents::
    :local:

``netconfig``
-------------

Generate the configuration using Jinja templates and load the rendered configuration on the network device. The
templates are pre-written for several operating systems:

- Junos
- Cisco IOS-XR
- Arista EOS

If you have a different operating system not covered yet, please submit a PR to add it.

Pillar
======

The pillar has the same structure in all cases, following the hierarchy of the
`openconfig-system YANG model <http://ops.openconfig.net/branches/master/openconfig-system.html>`_
other than the root key is `openconfig-system-logging`, e.g.:

.. code-block:: yaml

  openconfig-system-logging:
    system:
      logging:
        config:
          buffered: 1000
          format:
            hostname: fqdn
            hostnameprefix: router
          source_interface: Loopback0
        console:
          selectors:
            selector:
              'any emergencies':
                config:
                  facility: any
                  severity: emergencies
          files:
            file:
              messages:
                config:
                  file: messages
                selectors:
                  selector:
                    'any notice':
                      config:
                        facility: any
                        severity: notice
                    'authorization info':
                      config:
                        facility: authorization
                        severity: info
                  interactive-commands:
                    config:
                      file: interactive-commands
                    selectors:
                      selector:
                        'interactive-commands any':
                          config:
                            facility: interactive-commands
                            severity: any
          remote_servers:
            remote_server:
              primary_node:
                config:
                  host: 1.2.3.4
                  remote_port: 9514
                  match: '"!(.*PING_PROBE_FAILED.*|.*PING_TEST.*)"'
                selectors:
                  selector:
                    'any any':
                      config:
                        facility: any
                        severity: any
          users:
            user:
              '*':
                config:
                  user: '*'
                selectors:
                  selector:
                    'any emergency':
                      config:
                        facility: any
                        severity: emergency

.. note::
    Some platforms may not support several options, e.g.:

    - ``match`` is only available on Junos.

Usage
=====

After configuring the pillar data (and refresh it to the minions, i.e. ``$ sudo salt '*' saltutil.refresh_pillar``),
you can run this formula:

.. code-block:: bash

    $ sudo salt vmx01 state.sls logging.netconfig

Output Example:

.. code-block:: bash

  $ sudo salt vmx01 state.apply logging.netconfig
  vmx01:
  ----------
        ID: oc_logging_netconfig
    Function: netconfig.managed
      Result: True
     Comment: Configuration changed!
     Started: 10:07:31.981618
    Duration: 2264.954 ms
     Changes:
          ----------
          diff:
              [edit system]
              +   syslog {
              +       user * {
              +           any emergency;
              +       }
              +       host 1.2.3.4 {
              +           any any;
              +           match "!(.*PING_PROBE_FAILED.*|.*PING_TEST.*)";
              +           port 9514;
              +       }
              +       file messages {
              +           any notice;
              +           authorization info;
              +       }
              +       file interactive-commands {
              +           interactive-commands any;
              +       }
              +   }
    
  Summary for vmx01
  ------------
  Succeeded: 1 (changed=1)
  Failed:    0
  ------------
  Total states run:     1
  Total run time:   2.265 s

``test_netconfig``
------------------

To avoid testing the state directly on the network device, you can use this
state to save the contents in a temporary file, and display the rendered content
on the command line:

.. code-block:: bash

    $ sudo salt vmx01 state.sls logging.test_netconfig

Output example:

.. code-block:: bash

  $ sudo salt vmx01 state.apply logging.test_netconfig
  vmx01:
  ----------
        ID: oc_logging_netconfig_test
    Function: file.managed
      Name: /tmp/__salt_logging_vmx01.txt
      Result: True
     Comment: File /tmp/__salt_logging_vmx01.txt is in the correct state
     Started: 10:09:29.548562
    Duration: 625.553 ms
     Changes:
  ----------
        ID: file.read
    Function: module.run
      Result: True
     Comment: Module function file.read executed
     Started: 10:09:30.174583
    Duration: 0.443 ms
     Changes:
            ----------
            ret:
              system {
                replace:
                syslog {
                  file messages {
                    any notice;
                    authorization info;
                  }
                  file interactive-commands {
                    interactive-commands any;
                  }
                  host 1.2.3.4 {
                    port 9514;
                    match "!(.*PING_PROBE_FAILED.*|.*PING_TEST.*)";
                    any any;
                  }
                  user * {
                    any emergency;
                  }
                }
              }
  
  Summary for vmx01
  ------------
  Succeeded: 2 (changed=1)
  Failed:    0
  ------------
  Total states run:     2
  Total run time: 625.996 ms

