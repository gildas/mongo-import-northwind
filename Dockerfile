FROM ubuntu:bionic as origin

RUN apt-get update ; \
    apt-get install curl --yes

FROM mongo:4
LABEL maintainer="Gildas Cherruel <gildas@breizh.org>"

COPY --from=origin /usr/bin/curl /usr/local/bin/
COPY ./importer.sh /usr/local/bin/

# We should overwrite the default entrypoint from Mongo
ENTRYPOINT ["/usr/local/bin/importer.sh"]

CMD ["/usr/local/bin/importer.sh"]
