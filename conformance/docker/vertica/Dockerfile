# A single-node Vertica database for the conformance tests.
#
# The Community Edition images on Docker Hub are no longer public, so this builds on the public
# Kubernetes image, which normally depends on the VerticaDB operator to create the database.
# entrypoint.sh does that work instead. 25.3 is the last release that accepts the Community
# Edition license; 26.1 and later refuse to start with it.
FROM opentext/vertica-k8s:25.3.0-8

USER root
# The image expects to run as uid 997 / gid 995 but has no user for them, which Vertica requires
RUN echo "dbadmin:x:997:995:dbadmin:/home/dbadmin:/bin/bash" >> /etc/passwd \
    && (grep -q ":995:" /etc/group || echo "verticadba:x:995:" >> /etc/group) \
    && mkdir -p /home/dbadmin /data \
    && chown 997:995 /home/dbadmin /data

COPY --chown=997:995 entrypoint.sh /home/dbadmin/entrypoint.sh

USER 997:995
ENV USER=dbadmin HOME=/home/dbadmin TZ=UTC
EXPOSE 5433
ENTRYPOINT ["/bin/bash", "/home/dbadmin/entrypoint.sh"]
