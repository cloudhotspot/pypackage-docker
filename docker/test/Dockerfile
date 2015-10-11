FROM cloudhotspot/pypackage-base
MAINTAINER Justin Menga <justin.menga@cloudhotspot.co>

# Environment variables available to container
ENV PORT=8000 PROJECT_NAME=SampleDjangoApp

ADD wheelhouse /wheelhouse
RUN . /appenv/bin/activate && \
    pip install --no-index -f wheelhouse ${PROJECT_NAME} && \
    manage.py collectstatic --noinput && \
    rm -rf /wheelhouse

# The application runs on the specified PORT environment variable
EXPOSE ${PORT}
