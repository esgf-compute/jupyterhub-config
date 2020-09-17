ARG BASE_IMAGE
FROM $BASE_IMAGE

COPY *.crt /usr/local/share/ca-certificates/

USER root

RUN update-ca-certificates

USER $NB_USER
