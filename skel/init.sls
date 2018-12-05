/etc/skel/public_html/index.php:
  file.managed:
    - source: salt://skel/default-index.php
    - makedirs: True
