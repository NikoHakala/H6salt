# H6 Palvelinten Hallinta

Tehtävä tehty Xubuntu 18.04 käyttöjärjestelmällä

Jos kopioit tämän salt lamp setin niin muista vaihtaa salasanoja mariadb init.sls ja default.my.cnf tiedostoissa.

Alkutoimet

	setxkbmap fi && sudo apt-get update && sudo apt-get install -y gedit curl chromium-browser

# Asenna LAMP saltilla

## Apache Manuaaliasennus

Aloitin asentamalla apachen ja poistamalla default sivun.

	sudo apt-get install apache2


![Apachen etusivu](https://github.com/NikoHakala/salt/blob/master/apakkelocalhost.png)
      

	echo DefaultPage | sudo tee /var/www/html/index.html

![Apache etusivu tyhjennettynä](https://github.com/NikoHakala/salt/blob/master/apakkelocalhostdefaultrm.png)

Sitten laitoin käyttäjien kotisivut toimimaan.

	sudo a2enmod userdir
	sudo systemctl restart apache2
	mkdir public_html && cd public_html
	nano index.html

![Xubuntun kotisivu](https://github.com/NikoHakala/salt/blob/master/xubuntukotisivu.png)

## Apache Automatisointi Saltilla

Sitten kun apache toimi aloitin automatisoinnin saltilla

Ensin tietenkin asensin salt masterin ja orjan ja hyväksyin masterkoneen orjaksi.

	sudo apt-get install salt-master salt-minion -y
	echo -e "master: 192.168.10.47\nid: MasterMinion"|sudo tee /etc/salt/minion
	sudo systemctl restart salt-minion
	sudo salt-key -A

Sitten aloin tekemään apache init.sls tiedostoa

	sudo mkdir -p /srv/salt/apache && cd /srv/salt/apache

Tein viellä top.sls tiedoston.

	sudoedit /srv/salt/top.sls
	cat /srv/salt/top.sls
	base:
	  '*':
	    - apache

	sudoedit init.sls

Apache init sisältö

	cat init.sls
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

Kun apachen init oli valmis ajoin sen muutaman kerran 
ensin apache asennettuna sitten poistin apachen ja kokeilin uudelleen.

Se toimi tarpeeksi hyvin.

Sitten tein /srv/salt/skel kansion johon tein public_html automatisoinnin.

	sudo mkdir /srv/salt/skel
	sudoedit init.sls

Skel init sisältö

	cat init.sls
	/etc/skel/public_html/index.html:
	  file.managed:
	    - source: salt://skel/default-index.html
	    - makedirs: True

Lisäsin skelin top.slsään

	sudo salt '*' state.apply

Tein käyttäjän nimeltä pekka testatakseni skellin toimintaa.

	curl localhost/~pekka/
	default

Se näytti toimivan.

## MariaDB + ufw portit Manuaaliasennus

Aloitin mariadb asennuksen ensin muuttamalla palomuurin asetuksia.

	sudo ufw allow 22/tcp
	sudo ufw enable
	sudo ufw allow 4505/tcp
	sudo ufw allow 4506
	sudo ufw allow 80/tcp

Sitten asensin mariadbn ja tein sinne testi databasen ja sille käyttäjän.

	sudo apt-get -y install mariadb-client mariadb-server
	sudo mariadb -u root
	CREATE DATABASE ninjamakkara CHARACTER SET utf8;
	GRANT ALL ON ninjamakkara.* TO ninjamakkara@localhost IDENTIFIED BY 'Lisää tähän oma vaikea salasana';
	exit
	
Sitten tein käyttäjälle .my.cnf tiedoston kirjautumisen helpottamista varten.

	touch .my.cnf
	chmod og-rwx .my.cnf
	nano .my.cnf

Tältä näyttää .my.cnf tiedoston pohja

	cat .my.cnf
	[client]
	user=ninjamakkara
	password='Tähän oma vaikea salasana'
	database=ninjamakkara

	Sudo salt '*' state.apply

Kun se on tehty oikein niin mariadb komennolla pääsee kirjautumaan sisään ilman salasanaa ym.


## MariaDB + ufw portit Automatisointi Saltilla

Kun mariadb toimi manuaalisesti asennettuna aloitin automatisoinnin.

	sudo mkdir /srv/salt/mariadb && cd /srv/salt/mariadb
	sudoedit init.sls

Mariadb init sisältö
	cat init.sls
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

Sitten tein .my.cnf tiedostolle automatisoinnin mutta vain xubuntu käyttäjälle.
Tämä ei tunnu mielestäni tarpeelliselta mutta kai tämä on hyvää harjoitusta.

	sudo mkdir /srv/salt/mycnf && cd /srv/salt/mycnf
	sudo edit init.sls

	cat init.sls
	/home/xubuntu/.my.cnf:
	  file.managed:
	    - source: salt://mycnf/default.my.cnf
	    - user: xubuntu
	    - group: xubuntu

Lisäsin mycnffän top.slsään ja kokelin toimiiko se.

Nyt mariadb komentoa käyttäen xubuntu käyttäjällä voidaan kirjautua makkaraninjat tietokantaan käyttäjällä makkaraninjat.

Kun mycnf toimi oikein automatisoin ufw porttien configuroinnin.

	sudo mkdir /srv/salt/ufw && cd /srv/salt/ufw

Kopioin manuaalisesti vaihtamani säännöt eli portit 22, 80, 4505 ja 4506 auki.

	sudo cp /etc/ufw/user.rules /srv/salt/default-user.rules
	sudo cp /etc/ufw/user6.rules /srv/salt/default-user.rules
	
Sitten tein init.sls tiedoston.
	
	sudoedit init.sls

ufw init sisältö.
	cat init.sls
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

	ufw.service:
	  service.running

Sitten vielä muutin porttien asetuksia manuaalisesti jonka jälkeen lisäsin ufwn top.slsään ja ajoin highstaten.

	sudo ufw deny 80/tcp
	sudo salt '*' state.apply

Asiat eivät menneet kuten oletin koska en muuttanut user.rules tiedostojen oikeuksia.

	sudo chmod o+r default-user.rules
	sudo chmod o+r default-user6.rules

Sitten kokeilin uudelleen highstatea.

Uudet säännöt menivät läpi mutta ufw enable komento ajetaan joka kerta vaikka ufw on päällä joten korjasin sen.


ufw init korjattu ufw-enable idempotenttiseksi

	ufw-enable:
	  cmd.run:
	    - name: 'ufw --force enable'
	    - require:
	      - ufw
	    - unless: 'sudo ufw status|grep active'

Sitten kaikki toimi oikein mukavasti.
	

## PHP manuaaliasennus

Sitten aloitin phpn manuaali asennuksen

	sudo apt-get install -y libapache2-mod-php

Jotta php toimisi normaali käyttäjillä pitää muokata phpn conf tiedostoa.

	sudoedit /etc/apache2/mods-available/php7.2.conf

![Php if module](https://github.com/NikoHakala/salt/blob/master/phpifmodule.png)

Sitten apache pitää käynnistää uudelleen.

	sudo systemctl restart apache2

Kun apache käynnistyi uudelleen kokeilin toimiko php.

	cd && cd public_html && mv index.html index.php
	echo -e "<?php\nprint 2+2;\n?>"|sudo tee index.php

Xubuntun kotisivu

	curl localhost/~xubuntu/
	4


## PHP Automatisointi Saltilla

Kun php todistettavasti toimi manuaali asennuksen jälkeen aloitin automatisoinnin

	sudo mkdir /srv/salt/php
	sudoedit init.sls

php init sisältö

	cat init.sls
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

Sitten vielä tarvitsee kopioida php conf tiedosto jota muokattiin aikaisemmin.

	sudo cp /etc/apache2/mods-available/php7.2.conf /srv/salt/php/default-php7.2.conf

Kokeilin highstatea ja kaikki meni läpi. Joten en tee asialle viellä mitään.

Sitten muutin vielä skellin default sivun php loppuiseksi.

	cd /srv/salt/skel
	sudo mv default-index.html default-index.php

Ja muutin vielä init.sls tiedoston oikeaan muotoon 

	cat init.sls

	/etc/skel/public_html/index.php:
	  file.managed:
	    - source: salt://skel/default-index.php
	    - makedirs: True

Nyt uusille käyttäjille tulee valmiiksi toimiva index.php joka laskee laskun 2+2.

![Php salt testaus](https://github.com/NikoHakala/salt/blob/master/phpsalttestaus.png)

## Modulin testaus puhtaalta xubuntu 18.04 live koneelta

Gittasin kaiken githubiin ja käynnistin koneen uudelleen.







