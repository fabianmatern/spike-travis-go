CREATE KEYSPACE IF NOT EXISTS resource
  WITH REPLICATION = {
    'class' : 'SimpleStrategy',
    'replication_factor' : 1
  };

create table if not exists resource.job (id text, time timestamp, PRIMARY KEY (id));