import os
import runpy
import sys

args = [
    "serve.server",
    "--engine-bin", "/opt/basalt/bin/basalt",
    "--config", os.environ.get("BASALT_CONFIG", "/etc/basalt.json"),
]

# basalt accepts the API key only as --api-key on the command line. Passing it
# in-process keeps it out of /proc/<pid>/cmdline.
key_file = os.environ.get("BASALT_API_KEY_FILE", "/run/secrets/basalt-api-key")
if os.path.exists(key_file):
    with open(key_file) as f:
        args += ["--api-key", f.read().strip()]

sys.argv = args + sys.argv[1:]
sys.path.insert(0, "/opt/basalt")
runpy.run_module("serve.server", run_name="__main__", alter_sys=True)
