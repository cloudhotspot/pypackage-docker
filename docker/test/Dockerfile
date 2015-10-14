FROM mycompany/myapp-builder
MAINTAINER Justin Menga <justin.menga@cloudhotspot.co>

# Add application source and wheel cache
ADD src /application
ADD wheelhouse /wheelhouse
RUN . /appenv/bin/activate && \
    pip install .[test]

# Run tests by default
CMD ["python", "manage.py", "test"]


