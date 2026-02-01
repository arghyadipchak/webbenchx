ARG DEBIAN_VERSION=trixie
ARG DEBIAN_FRONTEND=noninteractive

FROM debian:${DEBIAN_VERSION}-slim

ARG DEBIAN_FRONTEND
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  httperf \
  tzdata \
  && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*
