FROM cloudhotspot/sampledjangoapp-builder
MAINTAINER Justin Menga <justin.menga@cloudhotspot.co>

# Environment variables available to container
ENV PORT=8000 PROJECT_NAME=SampleDjangoApp

# Add application source and wheel cache
ADD src /application
ADD wheelhouse /wheelhouse
RUN . /appenv/bin/activate && \
    pip install -r requirements.txt

# Run tests by default
CMD ["python", "manage.py", "test"]


