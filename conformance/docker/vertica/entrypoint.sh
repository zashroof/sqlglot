#!/bin/bash
# Creates the database on the first start and restarts it on later ones.
set -euo pipefail

DB_NAME=${VERTICA_DB_NAME:-conformance}
DB_PASSWORD=${VERTICA_DB_PASSWORD:-sqlglot}
CERTS=/opt/vertica/config/https_certs
CATALOG=/data/$DB_NAME/v_${DB_NAME}_node0001_catalog
VCLUSTER=(/opt/vertica/bin/vcluster --db-name "$DB_NAME" --config "$HOME/vertica_cluster.yaml")

# The node management agent and Vertica's HTTPS service, which vcluster talks to, need TLS
if [ ! -f "$CERTS/rootca.pem" ]; then
    cd "$CERTS"
    openssl req -x509 -newkey rsa:2048 -nodes -keyout rootca.key -out rootca.pem -days 3650 \
        -subj "/CN=rootca" -addext "basicConstraints=critical,CA:TRUE" \
        -addext "keyUsage=critical,keyCertSign,cRLSign" 2>/dev/null
    for name in vertica_https "$USER"; do
        openssl req -newkey rsa:2048 -nodes -keyout "$name.key" -out "$name.csr" -subj "/CN=$name" 2>/dev/null
        openssl x509 -req -in "$name.csr" -CA rootca.pem -CAkey rootca.key -CAcreateserial \
            -out "$name.pem" -days 3650 2>/dev/null \
            -extfile <(printf "subjectAltName=DNS:localhost,IP:127.0.0.1\nextendedKeyUsage=serverAuth,clientAuth")
    done
    pem() { awk '{printf "%s\\n", $0}' "$1"; }
    printf '{"name": "https", "mode": 2, "key": "%s", "certificate": "%s", "chain_certs": [], "ca_certificates": ["%s"]}' \
        "$(pem vertica_https.key)" "$(pem vertica_https.pem)" "$(pem rootca.pem)" > httpstls.json
    cd "$HOME"
fi

rm -f /opt/vertica/config/node_management_agent.pid
/opt/vertica/bin/manage_node_agent.sh start > /dev/null
until (exec 3<>/dev/tcp/127.0.0.1/5554) 2>/dev/null; do sleep 1; done

if [ -d "$CATALOG" ]; then
    "${VCLUSTER[@]:0:1}" start_db "${VCLUSTER[@]:1}" --password "$DB_PASSWORD"
else
    "${VCLUSTER[@]:0:1}" create_db "${VCLUSTER[@]:1}" --hosts 127.0.0.1 \
        --catalog-path /data --data-path /data --password "$DB_PASSWORD" \
        --config-param "HttpServerConf=$CERTS/httpstls.json"
fi

stop() {
    "${VCLUSTER[@]:0:1}" stop_db "${VCLUSTER[@]:1}" --password "$DB_PASSWORD" || true
    exit 0
}
trap stop TERM INT

# Vertica logs to $CATALOG/vertica.log; keep the container alive until it is stopped
sleep infinity &
wait $!
