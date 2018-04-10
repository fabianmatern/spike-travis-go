FROM golang:1.9

RUN go get github.com/julienschmidt/httprouter

COPY server.go /server.go
CMD go run /server.go

EXPOSE 1024