ARG VERSION
ARG CROMITE_SHA

FROM uazo/cromite:${VERSION}-${CROMITE_SHA}

USER lg
WORKDIR /home/lg/working_dir

COPY prepare-arm64.sh .

ENV CIPD_CACHE_DIR=/home/lg/working_dir/.cipd_cache
ENV VPYTHON_VIRTUALENV_ROOT=/home/lg/vpython_root

RUN chmod 755 ./prepare-arm64.sh && ./prepare-arm64.sh
