FROM alpine:3.6

RUN apk add --no-cache \
  "go=1.8.4-r0" \
  "go-tools=1.8.4-r0" \
  "libc-dev=0.7.1-r0" \
  "git=2.13.5-r0" \
  "curl" \
  "jq" \
  "bash"

ENV GOPATH=/code
RUN mkdir -p /code/bin
ENV PATH=$GOPATH/bin:$PATH

# Unfortunately we can't use `go get` here as it will always get the latest version,
# and we want everyone to have the same thing. So we have to do the 'getting' part ourselves
# and let Go install it in the normal way.
RUN git clone --depth 1 --branch v1.4.0 https://github.com/onsi/ginkgo.git $GOPATH/src/github.com/onsi/ginkgo && \
    cd $GOPATH/src/github.com/onsi/ginkgo/ginkgo && \
    go install .

RUN git clone --depth 1 --branch v0.3.0 https://github.com/golang/dep.git $GOPATH/src/github.com/golang/dep && \
    cd $GOPATH/src/github.com/golang/dep/cmd/dep && \
    go install .

RUN git clone https://github.com/go-yaml/yaml.git $GOPATH/src/gopkg.in/yaml.v2 && \
    cd $GOPATH/src/gopkg.in/yaml.v2 && \
    git checkout eb3733d160e74a9c7e442f435eb3bea458e1d19f && \
    go install .

RUN git clone --depth 1 --branch v1.0.0 https://github.com/ghodss/yaml $GOPATH/src/github.com/ghodss/yaml && \
    cd $GOPATH/src/github.com/ghodss/yaml && \
    go install .

RUN git clone https://github.com/buildkite/yaml2json.git $GOPATH/src/github.com/buildkite/yaml2json && \
    cd $GOPATH/src/github.com/buildkite/yaml2json && \
    git checkout 1ccbcc3b3ce92fb3bf0fd69f6f734bf08cecc206 && \
    go install .
