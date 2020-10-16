FROM alpine:3.12 AS builder

ARG OPENSSL_FIPS_VER=2.0.16
ARG OPENSSL_VER=1.0.2u
ARG OPENSSL_PGP_FINGERPRINT=D9C4D26D0E604491

WORKDIR /tmp/build

RUN set -x;
RUN apk add --no-cache zlib
RUN apk add --no-cache --virtual .build-deps \
      wget \
      gcc \
      gzip \
      tar \
      libc-dev \
      ca-certificates \
      perl \
      make \
      coreutils \
      gnupg \
      linux-headers \
      zlib-dev

RUN wget --quiet https://www.openssl.org/source/openssl-fips-$OPENSSL_FIPS_VER.tar.gz
RUN tar -xzf openssl-fips-$OPENSSL_FIPS_VER.tar.gz
RUN wget --quiet https://www.openssl.org/source/openssl-$OPENSSL_VER.tar.gz
RUN tar -xzf openssl-$OPENSSL_VER.tar.gz
RUN cd openssl-fips-$OPENSSL_FIPS_VER && \
    ./config && \
    make && \
    make install

RUN cd openssl-$OPENSSL_VER && \
 perl ./Configure linux-x86_64 \
    --prefix=/usr \
    --libdir=lib \
    --openssldir=/etc/ssl \
    -DOPENSSL_NO_BUF_FREELISTS \
    -Wa,--noexecstack \
    fips shared zlib enable-ec_nistp_64_gcc_128 enable-ssl2 && \
    make && \
    make INSTALL_PREFIX=/tmp/root install_sw

RUN rm -rf /tmp/build /usr/local/ssl

RUN apk del .build-deps

FROM alpine:3.12
COPY --from=builder /tmp/root /