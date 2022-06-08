FROM docker

COPY apparmor-profiles /app/apparmor-profiles

COPY container-handler.sh /app/

RUN chmod +x /app/container-handler.sh

CMD ["/app/container-handler.sh"]

