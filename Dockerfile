# We have a mult-stage build here, where we've split things up base on arch. For arm64, we need to
# compile Percona Server from source. We use a different base image with all of the necessary
# compile tools already installed

FROM --platform=linux/amd64 centos:centos7 as stage-amd64
# Install EPEL for amd64
RUN rpm -Uvh --force https://mirrors.kernel.org/fedora-epel/7/x86_64/Packages/e/epel-release-7-14.noarch.rpm

# Install mysql
RUN yum install -y \
    https://repo.percona.com/yum/percona-release-latest.noarch.rpm \
    && yum install -y \
        Percona-Server-client-57.x86_64 \
        Percona-Server-server-57.x86_64 \
        Percona-Server-shared-57.x86_64 \
    && yum clean all \
    && rm -rf /tmp/*

FROM --platform=linux/arm64 centos:centos7 as stage-arm64
# Install EPEL for arm64
RUN rpm -Uvh --force https://mirrors.kernel.org/fedora-epel/7/aarch64/Packages/e/epel-release-7-12.noarch.rpm

##!!## From parent container
RUN yum groupinstall -y "Development tools" \
    && yum install -y libcurl-devel \
        readline-devel  \
        bison \
        perl-Data-Dumper  \
        bzip2-devel \
        ncurses-devel \
        openssl-devel \
        zlib-devel \
        libffi-devel \
        wget \
        libaio-devel \
        tar \
        libevent \
        libevent-devel \
        gcc  \
        gcc-c++  \
        kernel-devel  \
        make  \
        cmake \
        jemalloc  \
        jemalloc-devel \
        libaio-devel  \
        openssl-dev \
        lzo \
        lzo-devel \
    && yum clean all

##!!## Maybe needed from a parent?
#RUN yum update snappy snappy-devel lzo lzo-devel fontconfig && \
#    yum install -y v && \
#    yum clean all

# Build MySQL from source

# This newer version is needed to compile 5.7 on aarch64
# If these are run together, it doesn't work... the stuff
# at the env variables below never ends up there.
RUN yum install -y centos-release-scl \
     && yum install -y devtoolset-8 \
     && yum install -y libaio-devel openssl openssl-dev \
     && yum clean all

# Use what was installed from above
ENV CC "/opt/rh/devtoolset-8/root/usr/bin/gcc"
ENV CXX "/opt/rh/devtoolset-8/root/usr/bin/g++"

# Do things a normal install would do for us
RUN groupadd mysql && useradd -r -g mysql -s /bin/false mysql

# This is needed, see https://bugs.mysql.com/bug.php?id=97547
COPY /etc/mysql_fix.patch /var/local/mysql_fix.patch

RUN mkdir /usr/include/boost_1_59_0 \
    && cd /var/local \
    && wget https://downloads.percona.com/downloads/Percona-Server-5.7/Percona-Server-5.7.37-40/source/tarball/percona-server-5.7.37-40.tar.gz \
    && tar xfz percona-server-5.7.37-40.tar.gz \
    && rm percona-server-5.7.37-40.tar.gz \
    && cd percona-server-5.7.37-40 \
    && patch -p1 -t < ../mysql_fix.patch \
    && cmake . \
        -DDOWNLOAD_BOOST=1 \
        -DWITH_BOOST=/usr/include/boost_1_59_0 \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_CONFIG=mysql_release \
        -DFEATURE_SET=community \
        -DWITH_EMBEDDED_SERVER=OFF \
        -DDEFAULT_CHARSET=utf8mb4 \
        -DDEFAULT_COLLATION=utf8mb4_general_ci \
    && make \
    && make install \
    && cd .. \
    && rm -rf percona-server-5.7.37-40 \
    && rm -rf /usr/include/boost_1_59_0 \
    && rm -rf /tmp/*

# Do things to make `mysql-start` happy.
RUN ln -s /usr/local/mysql/bin/mysqld /usr/sbin/mysqld \
    && ln -s /usr/local/mysql/bin/mysql /usr/bin/mysql \
    && ln -s /usr/local/mysql/bin/mysqladmin /usr/bin/mysqladmin \
    && ln -s /usr/local/mysql/bin/mysql_upgrade /usr/bin/mysql_upgrade

ENV PATH "/usr/local/mysql/bin:${PATH}"

# Declare TARGETARCH to make it available
ARG TARGETARCH
# Select final stage based on TARGETARCH ARG
FROM stage-${TARGETARCH} as final

# Everything below here is done for each TARGETARCH

COPY /bin/mysql-start /usr/local/bin/mysql-start
##!!## You may want to create these :shrug:
##!!## There's nothing that's in this image that will make
##!!## `mysql-stop` run, but it's possible
# COPY /bin/mysql-stop /usr/local/bin/mysql-stop
# COPY /conf/my.cnf /etc/my.cnf

CMD ["mysql-start"]