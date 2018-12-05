ufw:
  pkg.installed

/etc/ufw/user.rules:
  file.managed:
    - source: salt://ufw/default-user.rules
    - watch_in:
      - service: ufw.service

/etc/ufw/user6.rules:
  file.managed:
    - source: salt://ufw/default-user6.rules
    - watch_in:
      - service: ufw.service


ufw-enable:
  cmd.run:
    - name: 'ufw --force enable'
    - require:
      - ufw
    - unless: "sudo ufw status|grep 'Status: active'"

ufw.service:
  service.running
