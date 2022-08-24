FROM golang
ADD . /src
WORKDIR /src
RUN GOOS=linux CGO_ENABLED=0 go build -ldflags="-w -s" -a -installsuffix cgo ./cmd/oomhero

# FROM scratch
FROM ubuntu:22.04
COPY --from=0 /src/oomhero /src/oomhero.sh /
ENTRYPOINT ["/bin/sh", "/oomhero.sh"]
CMD ["/oomhero"]
