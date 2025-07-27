FROM debian:bullseye
RUN apt update && \
    apt install -y --no-install-recommends --no-install-suggests mariadb-server && \
    rm -rf /var/lib/apt/lists/*
EXPOSE 3306
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/
COPY scripts/setup.sh /bin/
RUN	chmod +x /bin/setup.sh
ENTRYPOINT ["/bin/setup.sh"]
CMD ["mysqld_safe"]
#CMD	service mariadb start && bash


