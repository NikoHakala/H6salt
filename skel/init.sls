/etc/skel/public_html/index.html:
  file.managed:
    - source: salt://skel/default-index.html
    - makedirs: True
