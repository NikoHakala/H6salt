mariadb-client:
  pkg.installed

mariadb-server:
  pkg.installed

create_testdb:
  cmd.run:
    - name: 'echo create database makkaraninjat|sudo mariadb -u root'
    - require:
      - mariadb-client
    - unless: 'echo show databases|sudo mariadb -u root|grep makkaraninjat'

create_testdbuser:
  cmd.run:
    - name: echo "grant all on makkaraninjat.* to makkaraninjat@localhost identified by 'salasana'"|sudo mariadb -u root
    - require:
      - mariadb-client
    - unless: 'echo select user from mysql.user|sudo mariadb -u root|grep makkaraninjat'
