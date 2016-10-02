#!/usr/bin/env bash
#
# Download and build elasticsearch container
set -euo pipefail

out=${PWD}/out
elasticsearch=${PWD}/out/elasticsearch

# _download "version" "sha256"
_download() {
  mkdir -p ${elasticsearch}
  curl -sOL https://download.elastic.co/elasticsearch/release/org/elasticsearch/distribution/tar/elasticsearch/${1}/elasticsearch-${1}.tar.gz
  echo "${2}  elasticsearch-${1}.tar.gz" | sha256sum -c
  tar -C ${elasticsearch} --strip-components 1 -xf elasticsearch-${1}.tar.gz

  mkdir -p ${elasticsearch}/tmp ${elasticsearch}/plugins
  chmod 1777 ${elasticsearch}/tmp
}

# _download_kopf "version"
_download_kopf() {
  mkdir -p ${elasticsearch}/plugins/kopf
  curl -sL https://github.com/lmenezes/elasticsearch-kopf/archive/v${1}.tar.gz -o kopf-v${1}.tar.gz
  tar -C ${elasticsearch}/plugins/kopf --strip-components 1 -xf kopf-v${1}.tar.gz
}
#mkdir -p ${src}/data ${src}/work ${src}/logs ${src}/plugins

_dockerfile() {
  cat <<EOF > ${out}/version
${1}
EOF
    
  cat <<EOF > ${out}/Dockerfile
FROM quay.io/desource/java:8

ADD elasticsearch /elasticsearch

VOLUME [ "/elasticsearch/data" ]

EXPOSE 9200 9300

ENTRYPOINT [ "java", "-cp", "/elasticsearch/lib/elasticsearch-${1}.jar:/elasticsearch/lib/*", "-Djava.awt.headless=true", "-XX:+UseParNewGC", "-XX:+UseConcMarkSweepGC", "-XX:CMSInitiatingOccupancyFraction=75", "-XX:+UseCMSInitiatingOccupancyOnly", "-XX:+HeapDumpOnOutOfMemoryError", "-XX:+DisableExplicitGC", "-Dfile.encoding=UTF-8", "-Djna.tmpdir=/elasticsearch/tmp", "-Delasticsearch", "-Des.foreground=yes", "-Des.path.home=/elasticsearch", "-Des.insecure.allow.root=true" ]

CMD [ "-Des.discovery.zen.ping.multicast.enabled=false", "-Xms256m", "-Xmx1g", "org.elasticsearch.bootstrap.Elasticsearch", "start" ]

EOF
}
# TODO remove "-Des.insecure.allow.root=true"

_download 2.4.1 23a369ef42955c19aaaf9e34891eea3a055ed217d7fbe76da0998a7a54bbe167
_download_kopf 2.1.2
_dockerfile 2.4.1
