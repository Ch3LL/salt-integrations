{% set salt_version = salt['pillar.get']('salt_version', '') %}
{% set check_salt = salt['cmd.run']('which salt') %}

{% if '/opt/bin/salt' not in check_salt %}
get_bootstrap_salt:
  cmd.run:
    - name: wget -O /tmp/install_salt.sh https://bootstrap.saltstack.com

install_bootstrap:
  cmd.run:
    - name: sh /tmp/install_salt.sh -M -P git {{ salt_version }}
{% endif %}
