FROM mycompany/myapp-base:latest
MAINTAINER Justin Menga <justin.menga@cloudhotspot.co>

# Install build dependencies
RUN apt-get install -qy libffi-dev libssl-dev python-dev && \
    . /appenv/bin/activate && \
    pip install wheel 
    
# PIP environment variables (NOTE: must be set after installing wheel)
ENV WHEELHOUSE=/wheelhouse PIP_WHEEL_DIR=/wheelhouse PIP_FIND_LINKS=/wheelhouse

# OUTPUT: Build artefacts (Wheels) are output here
VOLUME /wheelhouse

# INPUT: The application/project root to build from
VOLUME /application
WORKDIR /application

CMD ["pip", "wheel", "."]