FROM docker

COPY Dockerfile.dind /app/

COPY container-handler.sh /app/

RUN docker build /app/Dockerfile.dind -t dind-with-apparmor

RUN chmod +x /app/container-handler.sh

CMD ["/app/container-handler.sh"]

