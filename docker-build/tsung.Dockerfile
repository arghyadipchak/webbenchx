ARG ERLANG_VERSION=28.3.0
ARG TSUNG_VERSION=1.8.0
ARG DEBIAN_VERSION=trixie

ARG DEBIAN_FRONTEND=noninteractive

FROM erlang:${ERLANG_VERSION}-slim AS build

ARG DEBIAN_FRONTEND
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  debhelper \
  fakeroot \
  make \
  python3-sphinx \
  wget \
  && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

ARG TSUNG_VERSION
RUN wget http://tsung.erlang-projects.org/dist/tsung-${TSUNG_VERSION}.tar.gz && \
  tar -xvzf tsung-${TSUNG_VERSION}.tar.gz && \
  cd tsung-${TSUNG_VERSION} && \
  ./configure && \
  make && \
  make deb

FROM debian:${DEBIAN_VERSION}-slim

ARG DEBIAN_FRONTEND
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  erlang-nox \
  tzdata \
  && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

ARG TSUNG_VERSION
RUN --mount=type=bind,from=build,source=/tsung_${TSUNG_VERSION}-1_all.deb,target=/tmp/tsung.deb \
  dpkg -i /tmp/tsung.deb
