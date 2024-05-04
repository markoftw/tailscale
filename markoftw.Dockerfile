FROM golang:1.22-alpine AS build-env

WORKDIR /go/src/tailscale

COPY go.mod go.sum ./
RUN go mod download

COPY . .

# see build_docker.sh
ARG VERSION_LONG=""
ENV VERSION_LONG=$VERSION_LONG
ARG VERSION_SHORT=""
ENV VERSION_SHORT=$VERSION_SHORT
ARG VERSION_GIT_HASH=""
ENV VERSION_GIT_HASH=$VERSION_GIT_HASH
ARG TARGETARCH

RUN go install -tags=xversion -ldflags="\
      -X tailscale.com/version.longStamp=$VERSION_LONG \
      -X tailscale.com/version.shortStamp=$VERSION_SHORT \
      -X tailscale.com/version.gitCommitStamp=$VERSION_GIT_HASH" \
      -v ./cmd/tailscale ./cmd/tailscaled ./cmd/containerboot

FROM alpine:3.18
RUN apk add --no-cache ca-certificates iptables iproute2 ip6tables iputils

COPY --from=build-env /go/bin/* /usr/local/bin/

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod a+x /usr/local/bin/entrypoint.sh

CMD /usr/local/bin/entrypoint.sh
