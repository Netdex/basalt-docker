import os
import sys

args = [
    "/opt/basalt/bin/basalt", "serve",
    "--config", os.environ.get("BASALT_CONFIG", "/etc/basalt.json"),
]

# The key stays in its file, out of the process's command line.
key_file = os.environ.get("BASALT_API_KEY_FILE", "/run/secrets/basalt-api-key")
if os.path.exists(key_file):
    args += ["--api-key-file", key_file]

os.execv(args[0], args + sys.argv[1:])
