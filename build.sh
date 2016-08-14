#!/usr/bin/env sh
set -eux

ELASTICSEARCH_VERSION=2.3.1

SRC=$PWD/src
OUT=$PWD/elasticsearch-build
ROOTFS=$PWD/rootfs

mkdir -p $OUT/elasticsearch $OUT/tmp
curl -OL https://download.elastic.co/elasticsearch/release/org/elasticsearch/distribution/tar/elasticsearch/$ELASTICSEARCH_VERSION/elasticsearch-$ELASTICSEARCH_VERSION.tar.gz
# shasum check
tar -C $OUT/elasticsearch --strip-components 1 -xf elasticsearch-$ELASTICSEARCH_VERSION.tar.gz

# TODO add Plugins

mkdir -p $OUT/tmp $OUT/etc

cat <<EOF > $OUT/etc/passwd
root:x:0:0:root:/:/dev/null
nobody:x:65534:65534:nogroup:/:/dev/null
EOF

cat <<EOF > $OUT/etc/group
root:x:0:
nogroup:x:65534:
EOF

chmod 1777 $OUT/tmp

#mkdir -p $OUT/elasticsearch/data $OUT/elasticsearch/work $OUT/elasticsearch/logs $OUT/elasticsearch/plugins
chown -R nobody:root $OUT/elasticsearch

cat <<EOF > $OUT/Dockerfile
FROM quay.io/desource/java

ADD etc/passwd        /etc/
ADD etc/group         /etc/
ADD tmp               /tmp
ADD elasticsearch     /elasticsearch

USER nobody

VOLUME ["/elasticsearch/data"]

ENTRYPOINT ["java", "-cp", "/elasticsearch/lib/elasticsearch-${ELASTICSEARCH_VERSION}.jar:/elasticsearch/lib/*", "-Djava.awt.headless=true", "-XX:+UseParNewGC", "-XX:+UseConcMarkSweepGC", "-XX:CMSInitiatingOccupancyFraction=75", "-XX:+UseCMSInitiatingOccupancyOnly", "-XX:+HeapDumpOnOutOfMemoryError", "-XX:+DisableExplicitGC", "-Dfile.encoding=UTF-8", "-Delasticsearch", "-Des.foreground=yes", "-Des.path.home=/elasticsearch"]

CMD ["-Des.discovery.zen.ping.multicast.enabled=false", "-Xms256m", "-Xmx1g", "org.elasticsearch.bootstrap.Elasticsearch", "start"]

EXPOSE 9200 9300

EOF
