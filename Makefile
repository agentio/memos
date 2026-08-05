build:
	cd memos; go install ./cmd/memos

web:
	cd memos/web; pnpm install --frozen-lockfile; pnpm release

submodules:
	git submodule update --init --recursive

all:	submodules web build

container:
	podman build . \
		--build-arg VERSION=$(shell cd memos; git describe --tags) \
		--build-arg COMMIT=$(shell cd memos; git rev-parse HEAD) \
		--tag ghcr.io/agentio/memos
	podman push ghcr.io/agentio/memos