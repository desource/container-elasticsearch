#!/usr/bin/env sh
set -eux

ELASTICSEARCH_VERSION=2.3.1

SRC=$PWD/src
OUT=$PWD/elasticsearch-build
ROOTFS=$PWD/rootfs

mkdir -p $OUT/elasticsearch
curl -OL https://download.elastic.co/elasticsearch/release/org/elasticsearch/distribution/tar/elasticsearch/$ELASTICSEARCH_VERSION/elasticsearch-$ELASTICSEARCH_VERSION.tar.gz
tar -C $OUT/elasticsearch --strip-components 1 -xf elasticsearch-$ELASTICSEARCH_VERSION.tar.gz

# TODO add Plugins

cp -r $SRC/etc $OUT

mkdir -p $OUT/data/data $OUT/data/work $OUT/data/log
chown -R nobody $OUT/data

cat <<EOF > $OUT/Dockerfile
FROM quay.io/desource/java

ADD ./elasticsearch     /elasticsearch
ADD ./etc               /etc
ADD ./data              /data

EXPOSE 9200 9300

USER nobody

VOLUME ["/data/data", "/data/work", "/data/log"]

ENTRYPOINT ["java", "-cp", "/elasticsearch/lib/elasticsearch-${ELASTICSEARCH_VERSION}.jar:/elasticsearch/lib/*", "-Djava.awt.headless=true", "-XX:+UseParNewGC", "-XX:+UseConcMarkSweepGC", "-XX:CMSInitiatingOccupancyFraction=75", "-XX:+UseCMSInitiatingOccupancyOnly", "-XX:+HeapDumpOnOutOfMemoryError", "-XX:+DisableExplicitGC", "-Dfile.encoding=UTF-8", "-Des.foreground=yes", "-Des.path.home=/elasticsearch"]

CMD ["-Xms256m", "-Xmx1g", "org.elasticsearch.bootstrap.Elasticsearch", "start"]

EOF
