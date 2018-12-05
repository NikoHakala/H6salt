libapache2-mod-php:
  pkg.installed

/etc/apache2/mods-available/php7.2.conf:
  file.managed:
    - source: salt://php/default-php7.2.conf
    - watch_in:
      - service: apache2restart

apache2restart:
  service.running:
    - name: apache2
