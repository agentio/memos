FROM ghcr.io/pnpm/pnpm:11 AS base
RUN pnpm runtime set node 24 -g
WORKDIR /app
COPY ./memos/web .
RUN CI=true pnpm install --frozen-lockfile
RUN CI=true pnpm release

FROM docker.io/golang:1.26 AS builder
WORKDIR /app
COPY ./memos/go.mod ./memos/go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download
COPY ./memos .
COPY --from=base server/router/frontend/dist server/router/frontend/dist
ARG VERSION=dev COMMIT=unknown
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=linux \
    go build -v \
    -o memos \
    -ldflags="-s -w -X github.com/usememos/memos/internal/version.Version=${VERSION} -X github.com/usememos/memos/internal/version.Commit=${COMMIT} -extldflags '-static'" \
    ./cmd/memos

FROM gcr.io/distroless/static-debian13:latest
COPY --chown=0:0 --chmod=755 --from=builder /app/memos /bin/memos
WORKDIR /
ENTRYPOINT ["/bin/memos"]
