apache2:
  pkg.installed

/var/www/html/index.html:
  file.managed:
    - source: salt://apache/default-index.html

/etc/apache2/mods-enabled/userdir.conf:
  file.symlink:
    - target: ../mods-available/userdir.conf
    - watch_in:
      - service: apache2service

/etc/apache2/mods-enabled/userdir.load:
  file.symlink:
    - target: ../mods-available/userdir.load
    - watch_in:
      - service: apache2service

apache2service:
  service.running:
    - name: apache2
