FROM debian:bullseye
RUN apt update && \
    apt install -y --no-install-recommends --no-install-suggests mariadb-server && \
    rm -rf /var/lib/apt/lists/*
EXPOSE 3306
CMD	["/bin/bash"]


#COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/
