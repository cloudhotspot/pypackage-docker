FROM ubuntu:trusty
MAINTAINER Justin Menga <justin.menga@cloudhotspot.co>

# Set mirrors to NZ and install common packages
RUN sed -i "s/http:\/\/archive./http:\/\/nz.archive./g" /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -qyy -o APT::Install-Recommends=false -o APT::Install-Suggests=false python-virtualenv python libffi6 openssl libpython2.7

# Create virtual environment
RUN virtualenv /appenv

# Upgrade PIP
RUN . /appenv/bin/activate; pip install pip>=7.1.2

# Activate the virtual environment
ADD entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]