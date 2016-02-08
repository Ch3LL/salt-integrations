{% set salt_version = salt['pillar.get']('salt_version', '') %}
{% set tgt_hosts = ['int_test_minion', 'int_test_master'] %}
{% set orch_master = 'int_test_master' %}
{% set minion_host = tgt_hosts[0] %}
{% set master_host = tgt_hosts[1] %}
{% set master_ip = salt['cmd.run']('cat /etc/salt/roster | grep -i ' ~ master_host ~ ': | awk -F\':|,\' {\'print "\"$3\'}') %}

{% for host in tgt_hosts %}
create_{{ host }}:
  salt.function:
    - name: salt_cluster.create_node
    - tgt: {{ orch_master }}
    - arg:
      - {{ host }}
      - linode_cent7

sleep_{{ host }}:
  salt.function:
    - name: test.sleep
    - tgt: {{ orch_master }}
    - arg:
      - 120

verify_host_{{ host }}:
  salt.function:
    - name: cmd.run
    - tgt: {{ orch_master }}
    - arg:
      - salt-ssh {{ host }} -i test.ping

install_salt_{{ host }}:
  salt.state:
    - tgt: {{ host }}
    - ssh: 'true'
    - sls:
      - envs.install_salt
    - pillar:
        salt_version: {{ salt_version }}

setup_{{ host }}:
  salt.state:
    - tgt: {{ host }}
    - ssh: 'true'
    - sls:
      - envs.master_minion.setup
    - pillar:
        salt_version: {{ salt_version }}
        master_ip: {{ master_ip }}
        minion_host: {{ minion_host }}
{% endfor %}
