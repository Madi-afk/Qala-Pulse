# Official release sources; registries for the published MinIO images are unavailable.
FROM golang:1.24.2-bookworm@sha256:79390b5e5af9ee6e7b1173ee3eac7fadf6751a545297672916b59bfa0ecf6f71 AS build
ARG COMPONENT
ARG SOURCE_COMMIT
WORKDIR /src
RUN git init . && git remote add origin https://github.com/minio/${COMPONENT}.git \
    && git fetch --depth=1 origin ${SOURCE_COMMIT} && git checkout --detach FETCH_HEAD \
    && test "$(git rev-parse HEAD)" = "${SOURCE_COMMIT}"
ENV CGO_ENABLED=0 GOTOOLCHAIN=local
RUN go build -trimpath -ldflags="-s -w" -o /out/service .

FROM alpine:3.21.3@sha256:a8560b36e8b8210634f77d9f7f9efd7ffa463e380b75e2e74aff4511df3ef88c
RUN apk add --no-cache ca-certificates
ARG COMPONENT
ARG SOURCE_COMMIT
LABEL org.opencontainers.image.source="https://github.com/minio/${COMPONENT}" \
      org.opencontainers.image.revision="${SOURCE_COMMIT}" \
      org.opencontainers.image.licenses="AGPL-3.0-only"
COPY --from=build /out/service /usr/local/bin/service
COPY --from=build /src/LICENSE /usr/share/licenses/minio/LICENSE
RUN ln -s /usr/local/bin/service /usr/local/bin/${COMPONENT}
ENTRYPOINT ["/usr/local/bin/service"]
