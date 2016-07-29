#!/usr/bin/env sh
set -eux

ELASTICSEARCH_VERSION=2.3.1

BASE=$PWD
SRC=$PWD/src
OUT=$PWD/elasticsearch-build
ROOTFS=$PWD/rootfs

mkdir -p $OUT/elasticsearch
curl -OL https://download.elastic.co/elasticsearch/release/org/elasticsearch/distribution/tar/elasticsearch/$ELASTICSEARCH_VERSION/elasticsearch-$ELASTICSEARCH_VERSION.tar.gz
tar -C $OUT/elasticsearch --strip-components 1 -xf elasticsearch-$ELASTICSEARCH_VERSION.tar.gz

cp -r $SRC/etc $ROOTFS

cp $SRC/etc $OUT

cat <<EOF > $OUT/Dockerfile
FROM quay.io/desource/java

ADD ./elasticsearch     /elasticsearch
ADD ./etc               /etc

EXPOSE 9200 9300

VOLUME /data/data /data/log /data/plugins

ENTRYPOINT ["java", "-cp", "/elasticsearch/lib/elasticsearch-${ELASTICSEARCH_VERSION}.jar:/elasticsearch/lib/*", "-Djava.awt.headless=true", "-XX:+UseParNewGC", "-XX:+UseConcMarkSweepGC", "-XX:CMSInitiatingOccupancyFraction=75", "-XX:+UseCMSInitiatingOccupancyOnly", "-XX:+HeapDumpOnOutOfMemoryError", "-XX:+DisableExplicitGC", "-Dfile.encoding=UTF-8", "-Delasticsearch", "-Des.foreground=yes", "-Des.path.home=/elasticsearch/", "-Des.insecure.allow.root=true"]

CMD [ "-Des.insecure.allow.root=true", "-Xms256m", "-Xmx1g", "org.elasticsearch.bootstrap.Elasticsearch", "start" ]

EOF
