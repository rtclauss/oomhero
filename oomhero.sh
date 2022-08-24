#!/bin/sh

# Execute command from dockerfile and any `docker exec -ti` or `kubectl exec -ti`
exec "$@"
