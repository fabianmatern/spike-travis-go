FROM cassandra:3.10

COPY bootstrap.sh /
COPY db-model/ /docker-initdb.d/
COPY health-check.sh /tools/
COPY cassandra.yaml /etc/cassandra

RUN mkdir -p /cassandra/data /cassandra/commitlog /cassandra/saved_caches && \
      chown -R cassandra:cassandra /cassandra && \
      chmod -R g+w /cassandra

HEALTHCHECK --interval=2s --retries=20 CMD /tools/health-check.sh

RUN /bootstrap.sh
