FROM docker.io/postgres:16

# Copy custom PostgreSQL configuration
COPY ./compose/production/postgres/postgresql.conf /etc/postgresql/postgresql.conf

COPY ./compose/production/postgres/maintenance /usr/local/bin/maintenance
RUN chmod +x /usr/local/bin/maintenance/*
RUN mv /usr/local/bin/maintenance/* /usr/local/bin \
    && rmdir /usr/local/bin/maintenance

# Use custom config file on startup
CMD ["postgres", "-c", "config_file=/compose/postgres/postgresql.conf"]
