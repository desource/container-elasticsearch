#!/bin/sh
set -eux

ELASTICSEARCH_VERSION=2.3.1
KOPF_VERSION=2.1.2

SRC=$PWD/src
OUT=$PWD/out
ROOTFS=$PWD/rootfs

mkdir -p $OUT/elasticsearch $OUT/tmp
curl -sOL https://download.elastic.co/elasticsearch/release/org/elasticsearch/distribution/tar/elasticsearch/$ELASTICSEARCH_VERSION/elasticsearch-$ELASTICSEARCH_VERSION.tar.gz
# shasum check
tar -C $OUT/elasticsearch --strip-components 1 -xf elasticsearch-$ELASTICSEARCH_VERSION.tar.gz

mkdir -p $OUT/elasticsearch/tmp $OUT/elasticsearch/plugins
chmod 1777 $OUT/elasticsearch/tmp

mkdir -p $OUT/elasticsearch/plugins/kopf
curl -sL https://github.com/lmenezes/elasticsearch-kopf/archive/v$KOPF_VERSION.tar.gz -o kopf-v$KOPF_VERSION.tar.gz
tar -C $OUT/elasticsearch/plugins/kopf --strip-components 1 -xf kopf-v$KOPF_VERSION.tar.gz

#mkdir -p $OUT/elasticsearch/data $OUT/elasticsearch/work $OUT/elasticsearch/logs $OUT/elasticsearch/plugins

cat <<EOF > $OUT/Dockerfile
FROM quay.io/desource/java

ADD elasticsearch /elasticsearch

# USER nobody

VOLUME ["/elasticsearch/data"]

ENTRYPOINT ["java", "-cp", "/elasticsearch/lib/elasticsearch-${ELASTICSEARCH_VERSION}.jar:/elasticsearch/lib/*", "-Djava.awt.headless=true", "-XX:+UseParNewGC", "-XX:+UseConcMarkSweepGC", "-XX:CMSInitiatingOccupancyFraction=75", "-XX:+UseCMSInitiatingOccupancyOnly", "-XX:+HeapDumpOnOutOfMemoryError", "-XX:+DisableExplicitGC", "-Dfile.encoding=UTF-8", "-Djna.tmpdir=/elasticsearch/tmp", "-Delasticsearch", "-Des.foreground=yes", "-Des.path.home=/elasticsearch", "-Des.insecure.allow.root=true"]

CMD ["-Des.discovery.zen.ping.multicast.enabled=false", "-Xms256m", "-Xmx1g", "org.elasticsearch.bootstrap.Elasticsearch", "start"]

EXPOSE 9200 9300

EOF

# TODO remove "-Des.insecure.allow.root=true"
