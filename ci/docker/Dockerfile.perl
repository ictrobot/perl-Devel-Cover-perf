ARG PERL_TAG=stable
FROM perl:${PERL_TAG}

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        pkg-config \
        time \
        libssl-dev \
        libsqlite3-dev \
        libxml2-dev \
        uuid-dev \
        zlib1g-dev && \
    rm -rf /var/lib/apt/lists/*

# Install the benchmark app's dependencies from CPAN so this image represents
# current upstream modules rather than distro-packaged Perl dependencies.
COPY example/cpanfile /tmp/example/cpanfile
WORKDIR /tmp/example
RUN cpanm --notest --installdeps .

# Tools needed by the optimizer and test harness.
RUN cpanm --notest --skip-satisfied App::ForkProve PadWalker

# Devel::Cover is the final layer so exact-version builds can reuse all
# dependency layers.
ARG DC_VERSION
RUN cpanm --notest Devel::Cover@${DC_VERSION}
RUN DC_VERSION="${DC_VERSION}" perl -e \
    'require Devel::Cover; die qq{got $Devel::Cover::VERSION, want $ENV{DC_VERSION}\n} unless $Devel::Cover::VERSION eq $ENV{DC_VERSION}'

WORKDIR /opt/work
