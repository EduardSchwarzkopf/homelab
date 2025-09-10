curl -v -L http://$PACKER_HTTP_IP:$PACKER_HTTP_PORT/schematic.yaml -o schematic.yaml
export SCHEMATIC=$(curl -L -X POST --data-binary @schematic.yaml https://factory.talos.dev/schematics | grep -o '\"id\":\"[^\"]*' | grep -o '[^\"]*$')
curl -L https://factory.talos.dev/image/$SCHEMATIC/v$OS_VERSION/nocloud-amd64.raw.xz -o /tmp/talos.raw.xz
xz -d -c /tmp/talos.raw.xz | dd of=/dev/sda && sync