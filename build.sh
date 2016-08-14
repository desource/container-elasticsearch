#!/usr/bin/env sh
set -eux

ELASTICSEARCH_VERSION=2.3.1

SRC=$PWD/src
OUT=$PWD/elasticsearch-build
ROOTFS=$PWD/rootfs

mkdir -p $OUT/elasticsearch
curl -OL https://download.elastic.co/elasticsearch/release/org/elasticsearch/distribution/tar/elasticsearch/$ELASTICSEARCH_VERSION/elasticsearch-$ELASTICSEARCH_VERSION.tar.gz
# shasum check
tar -C $OUT/elasticsearch --strip-components 1 -xf elasticsearch-$ELASTICSEARCH_VERSION.tar.gz

# TODO add Plugins

cp -r $SRC/etc $OUT

mkdir -p $OUT/elasticsearch/data $OUT/elasticsearch/work $OUT/elasticsearch/logs $OUT/elasticsearch/plugins
chown -R nobody $OUT/elasticsearch/{config,data,work,logs,plugins}

cat <<EOF > $OUT/Dockerfile
FROM quay.io/desource/java

ADD ./etc               /etc
ADD ./elasticsearch     /elasticsearch

EXPOSE 9200 9300

USER nobody

VOLUME ["/elasticsearch/data"]

ENTRYPOINT ["java", "-cp", "/elasticsearch/lib/elasticsearch-${ELASTICSEARCH_VERSION}.jar:/elasticsearch/lib/*", "-Djava.awt.headless=true", "-XX:+UseParNewGC", "-XX:+UseConcMarkSweepGC", "-XX:CMSInitiatingOccupancyFraction=75", "-XX:+UseCMSInitiatingOccupancyOnly", "-XX:+HeapDumpOnOutOfMemoryError", "-XX:+DisableExplicitGC", "-Dfile.encoding=UTF-8", "-Delasticsearch", "-Des.foreground=yes", "-Des.path.home=/elasticsearch"]

CMD ["-Des.discovery.zen.ping.multicast.enabled=false", "-Xms256m", "-Xmx1g", "org.elasticsearch.bootstrap.Elasticsearch", "start"]

EOF
