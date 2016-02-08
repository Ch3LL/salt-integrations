{% set master_ip = salt['pillar.get']('master_ip', '') %}
{% set os_ = salt['grains.get']('os', '') %}
{% set salt_version = pillar.get('salt_version', '') %}
{% set minion_id = '{0}-{1}'.format(pillar.get('minion_host'), salt_version) %}

{% set hostname = salt['grains.get']('id', '') %}
{% if 'master' in hostname %}
  {% set master_role = True %}
  {% set minion_role = False %}
  {% set service = 'salt-master' %}
{% elif 'minion' in hostname %}
  {% set master_role = False %}
  {% set minion_role = True %}
  {% set service = 'salt-minion' %}
{% endif %}

disable_services:
  service.dead:
    - names:
      - {{ service }}
    - require_in:
      - file: remove_pki
      - file: clear_minion_id
{% if minion_role %}
      - file: minion_config
{% endif %}

remove_pki:
  file.absent:
    - name: /etc/salt/pki

clear_minion_id:
  file.absent:
    - name: /etc/salt/minion_id

{% if minion_role %}
minion_config:
  file.managed:
    - name: /etc/salt/minion
    - contents: |
        master: {{ master_ip }}
        id: {{ minion_id }}
{% endif %}

enable_services:
  cmd.run:
    - names:
      - service {{ service }} start
    - require:
      - file: remove_pki
      - file: clear_minion_id
{% if minion_role %}
      - file: minion_config
{% endif %}
wait_for_key:
  cmd.run:
    - name: sleep 7
    - require:
      - cmd: enable_services

{% if master_role %}
accept_key:
  cmd.run:
    - name: 'salt-key -ya {{ minion_id }}'
    - require:
      - cmd: wait_for_key
{% endif %}
