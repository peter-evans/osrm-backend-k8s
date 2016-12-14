FROM peterevans/trusty-gcloud:1.0

MAINTAINER Peter Evans <pete.evans@gmail.com>

# Let the container know that there is no TTY
ENV DEBIAN_FRONTEND noninteractive

# Install necessary packages for proper system state
RUN apt-get -y update && apt-get install -y \
    build-essential \
    cmake \
    curl \
    git \
    libboost-all-dev \
    libbz2-dev \
    libstxxl-dev \
    libstxxl-doc \
    libstxxl1 \
    libtbb-dev \
    libxml2-dev \
    libzip-dev \
    lua5.1 \
    liblua5.1-0-dev \
    libluabind-dev \
    libluajit-5.1-dev \
    pkg-config

RUN mkdir -p /osrm-build \
 && mkdir -p /osrm-data

WORKDIR /osrm-build

# Build osrm-backend
RUN curl --silent -L https://github.com/Project-OSRM/osrm-backend/archive/v5.2.6.tar.gz -o v5.2.6.tar.gz \
 && tar xzf v5.2.6.tar.gz \
 && mv osrm-backend-5.2.6 /osrm-src \
 && cmake /osrm-src \
 && make \
 && mv /osrm-src/profiles/car.lua car.lua \
 && mv /osrm-src/profiles/bicycle.lua bicycle.lua \
 && mv /osrm-src/profiles/foot.lua foot.lua \
 && mv /osrm-src/profiles/lib/ lib \
 && echo "disk=/tmp/stxxl,25000,syscall" > .stxxl \
 && rm -rf /osrm-src

# Clean up
RUN apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Set the entrypoint
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 5000
