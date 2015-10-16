FROM mycompany/myapp-builder
MAINTAINER Justin Menga <justin.menga@cloudhotspot.co>

# Add test entrypoint script
ADD scripts/test.sh /usr/local/bin/test.sh
RUN chmod +x /usr/local/bin/test.sh

# Add cache entrypoint script
# ADD scripts/cache.sh /usr/local/bin/cache.sh
# RUN chmod +x /usr/local/bin/cache.sh

ENTRYPOINT ["test.sh"]

# Run tests by default
CMD ["python", "manage.py", "test"]


