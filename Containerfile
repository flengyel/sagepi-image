# Containerfile: build Sage 10.7 natively on the host architecture (arm64 on Raspberry Pi)
# Produces an image compatible with your existing sagequeue assumptions:
#   - Sage lives at /sage
#   - run as uid:gid 1000:1000
#   - HOME=/home/sage, notebooks at /home/sage/notebooks

ARG DEBIAN_RELEASE=bullseye
FROM docker.io/debian:${DEBIAN_RELEASE}

ARG SAGE_GIT_REF=10.7
ARG MAKE_JOBS=4

# Keep configure flags overridable but deterministic by default.
# Add/remove flags here once you confirm what you truly need on the Pi.
ARG CONFIGURE_FLAGS="--enable-cryptominisat"

ENV DEBIAN_FRONTEND=noninteractive

#RUN  apt-add-repository ppa:git-core/ppa

RUN apt-get update && apt-get install -y --no-install-recommends \
      autoconf automake libtool m4 \
      ca-certificates curl git \
      bzip2 libbz2-dev \
      build-essential gfortran m4 perl pkg-config \
      cmake xauth x11-xserver-utils \
      git libgit2-dev libmagick++-dev libharfbuzz-dev libfribidi-dev \
      bc \
      xz-utils bzip2 gzip tar patch unzip zip \
      rsync \
      python3 python3-venv python3-distutils \
      libssl-dev libffi-dev zlib1g-dev \
      libreadline-dev libncurses5-dev libsqlite3-dev \
      libgmp-dev libmpfr-dev libmpc-dev \
      cliquer cmake curl ecl eclib-tools fflas-ffpack flintqs g++ gcc gengetopt \
      gfan gfortran gmp-ecm lcalc libatomic-ops-dev libboost-dev libbraiding-dev \
      libbrial-dev libbrial-groebner-dev libbz2-dev libcdd-dev libcdd-tools  \
      libcurl4-openssl-dev libec-dev libecm-dev libffi-dev libflint-arb-dev libflint-dev \
      libfplll-dev libfreetype6-dev libgc-dev libgd-dev libgf2x-dev \
      libgiac-dev libgivaro-dev libglpk-dev libgmp-dev libgsl-dev libhomfly-dev libiml-dev \
      liblfunction-dev liblinbox-dev liblrcalc-dev liblzma-dev  \
      libm4rie-dev libmpc-dev libmpfi-dev libmpfr-dev libncurses5-dev \
      libntl-dev libopenblas-dev libpari-dev libpcre3-dev libplanarity-dev libppl-dev \
      libprimesieve-dev libpython3-dev libqhull-dev libreadline-dev librw-dev \
      libsingular4-dev libsqlite3-dev libssl-dev libsuitesparse-dev libsymmetrica2-dev \
      libz-dev libzmq3-dev libzn-poly-dev m4 make nauty ninja-build openssl palp pari-doc \
      pari-elldata pari-galdata pari-galpol pari-gp2c pari-seadata \
      patch perl pkg-config planarity ppl-dev r-base-dev \
      r-cran-lattice singular singular-doc sqlite3 sympow tachyon tar tox xcas xz-utils \
      coinor-cbc coinor-libcbc-dev gpgconf openssh-client pari-gp2c libisl-dev libgraphviz-dev \
      lrslib pdf2svg libxml-libxslt-perl libxml-writer-perl libxml2-dev libperl-dev libfile-slurp-perl libjson-perl \
      libsvg-perl libterm-readkey-perl libterm-readline-gnu-perl libmongodb-perl \
      polymake libpolymake-dev default-jdk libavdevice-dev bison \
      fakeroot gnupg libalgorithm-merge-perl less alsa-ucm-conf alsa-topology-conf \
      bliss libaacs0 libbson-xs-perl bzip2-doc manpages manpages-dev libc-devtools \
      libcdd-doc dbus libfile-fcntllock-perl liblocale-gettext-perl libexif-doc \
      fluid libgl-dev libglu-dev xdg-user-dirs libgail-common \
      libgtk2.0-bin libgts-bin javascript-common libjson-xs-perl libldap-common \
      ghostscript gsfonts libjxr-tools libio-socket-ssl-perl libnet-ssleay-perl \
      libgpm2 libdigest-bubblebabble-perl libnet-dns-sec-perl libnet-libidn-perl \
      libperl4-corelibs-perl libpackage-stash-xs-perl libpng-tools \
      pocketsphinx-en-us poppler-data primesieve-bin publicsuffix libsasl2-modules \
      libcgi-pm-perl libref-util-perl va-driver-all  \
      libxml-sax-expat-perl libatk-wrapper-java-jni fonts-dejavu-extra \
      texlive-base netbase graphviz r-recommended r-doc-html \
      singular-ui 4ti2 normaliz surf-alggeo python3-brial libfile-mimeinfo-perl \
      libnet-dbus-perl libx11-protocol-perl x11-utils \
    && rm -rf /var/lib/apt/lists/*

# Ensure the CA bundle is present and explicitly configured for git/curl.
RUN update-ca-certificates
COPY host-ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
RUN test -s /etc/ssl/certs/ca-certificates.crt

ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
ENV GIT_SSL_CAINFO=/etc/ssl/certs/ca-certificates.crt
ENV CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

RUN git config --system http.sslCAInfo /etc/ssl/certs/ca-certificates.crt



# Create the runtime user SageQueue expects (uid/gid 1000).
RUN groupadd -g 1000 sage \
 && useradd  -m -u 1000 -g 1000 -s /bin/bash sage \
 && mkdir -p /sage /home/sage/notebooks \
 && chown -R 1000:1000 /sage /home/sage

ENV HOME=/home/sage
ENV DOT_SAGE=/home/sage/.sage

USER 1000:1000
WORKDIR /sage

# Fetch Sage sources at a pinned ref (tag 10.7 by default).
RUN git clone --depth 1 --branch "${SAGE_GIT_REF}" https://gitlab.com/sagemath/sage.git /sage \
 && git rev-parse HEAD > /sage/SAGE_COMMIT

# Standard build sequence: bootstrap -> configure -> make. 
RUN ./bootstrap
RUN ./configure ${CONFIGURE_FLAGS}
RUN make -j"${MAKE_JOBS}"

# Install pycryptosat inside Sage's python environment (needed for CryptoMiniSat backend usage).
RUN ./sage -pip uninstall -y pycryptosat || true
RUN ./sage -pip install --no-binary=pycryptosat pycryptosat==5.11.21

# Fail-fast sanity check (build-time).
RUN ./sage -python -c "import pycryptosat; print(pycryptosat.__version__)"

EXPOSE 8888

# Default: run Jupyter bound to 0.0.0.0 inside the container.
CMD ["bash","-lc","exec ./sage -n jupyter --no-browser --ip=0.0.0.0 --port=8888 --notebook-dir=/home/sage/notebooks"]

