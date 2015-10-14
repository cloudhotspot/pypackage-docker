FROM mycompany/myapp-builder
MAINTAINER Justin Menga <justin.menga@cloudhotspot.co>

# Add test entrypoint script
ADD test.sh /usr/local/bin/test.sh
RUN chmod +x /usr/local/bin/test.sh
ENTRYPOINT ["test.sh"]

# Run tests by default
CMD ["python", "manage.py", "test"]


