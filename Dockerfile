FROM amazonlinux:latest
MAINTAINER Alan Zhao <alanzhaonys@yahoo.com>

# Install packages
RUN yum update -y
RUN yum install vim httpd24 php71 -y

RUN echo "<?php phpinfo(); ?>" > /var/www/html/phpinfo.php

# Change Apache server name
RUN sed -i -e "s/#ServerName www.example.com:80/ServerName localhost/g" /etc/httpd/conf/httpd.conf

# Change PHP timezone
RUN sed -i -e "s/;date.timezone =/date.timezone = America\/New_York/g" /etc/php-7.1.ini

# Change system timezone
RUN ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime

CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]

EXPOSE 80
