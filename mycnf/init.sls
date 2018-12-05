/home/xubuntu/.my.cnf:
  file.managed:
    - source: salt://mycnf/default.my.cnf
    - user: xubuntu
    - group: xubuntu
