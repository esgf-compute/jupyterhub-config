ARG BASE_CONTAINER
FROM $BASE_CONTAINER

COPY *.crt /usr/local/share/ca-certificates/

USER root

RUN update-ca-certificates

USER $NB_USER
