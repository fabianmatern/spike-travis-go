FROM alpine:3.6

RUN apk add --no-cache curl

COPY app /
COPY health-check.sh /tools/

HEALTHCHECK --interval=60s CMD /tools/health-check.sh

CMD /app
EXPOSE 8080
