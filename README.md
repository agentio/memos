# memos

This repo contains build instructions that create a custom container build of the [Memos](https://usememos.com/) notetaking app.

## Distinctives
- The [usememos/memos](https://github.com/usememos/memos) repo is included as a Git submodule.
- The Dockerfile builds both the embedded Node SPA and the Go server.
- The Node SPA is built with the [offical pnpm build image](https://pnpm.io/docker#official-pnpm-base-image).
- The main server is built with the [official Go build image](https://hub.docker.com/_/golang).
- The final image is a tiny [gcr.io/distroless/static-debian13](https://github.com/googlecontainertools/distroless) base image with only the `memos` binary added.
- The Makefile includes a target (`make container`) that sets the `DEV` and `CONTAINER` environment variables and uses `podman` to build and push `ghcr.io/agentio/memos`. (You'll have to modify this if you don't have permission to write this package.)
- `make all` builds a local `memos` binary. This requires `pnpm` and `go`.
- `memos` runs in the container as `root`. Yeah, this is generally not preferred, but I'm running this container with [rootless Podman](https://www.redhat.com/en/blog/rootless-containers-podman) and this keeps file ownership simple.

## Usage

### Run the binary locally

If you build the binary, you can easily run it locally:
```sh
$ memos
time=2026-08-05T17:18:38.647-07:00 level=INFO msg="background runners started"
Memos dev started successfully!
Data directory: /home/tim/memos
Database driver: sqlite
Server running on port 8081
Access your memos at: http://localhost:8081
Access mode: private

Documentation: https://usememos.com
Source code: https://github.com/usememos/memos

Happy note-taking!
```

### Run the container locally

The following runs the `memos` container build with a `memos` database in `~/memos`:
```sh
podman run -d \
  --replace \
  --name memos \
  -p 8081:8081 \
  -v ~/memos:/var/opt/memos \
  ghcr.io/agentio/memos:latest
```

### Run the container with Podman Quadlets

If you'd like to run this with [Podman Quadlets](https://www.redhat.com/en/blog/quadlet-podman), here's my `/etc/containers/systemd/users/1000/memos.container`:
```
[Unit]
Description=Memos
After=network-online.target

[Container]
Image=ghcr.io/agentio/memos:latest
ContainerName=memos
Pull=newer
PublishPort=9010:3000
Volume=/opt/pods/memos:/var/opt/memos:rw,z
Environment=MEMOS_MODE="prod"
Environment=MEMOS_PORT=3000

[Service]
Restart=always

[Install]
WantedBy=default.target
```
Note that I've chosen a port to suit my deployment and that I've created `/opt/pods/memos` to contain the `memos` data files.

### Build a file descriptor set for the Memos API.

The `Makefile` includes a target (`make descriptor`) that generates a `descriptor.pb` file that contains a file descriptor set for the Memos API. When this is uploaded to IO, IO can display the contents of request and response bodies. Upload it using SSH:

```sh
ssh YOUR-IO-HOST -p 2200 put < descriptor.pb
```
