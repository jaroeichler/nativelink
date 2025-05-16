# Setup Chromium

*TODO:* Use `fetch --no-history chrome` for testing and CI.
Otherwise fetching doesn't go through for me in one go because of access limits
to the Google servers.
Maybe we can get rid of `--args="symbol_level=0"`.

Fetch the Chromium sources and create the build targets
```
mkdir chromium &&
cd chromium &&
fetch chromium &&
cd src &&
gn gen --args="symbol_level=0 use_reclient=false use_remoteexec=true use_siso=true" out/Default
```

After fetching Chromium, look up `container_image` in
`chromium/src/build/config/siso/backend_config/backend.star`.
Use this image as the remote build image.
Be careful when you update dependencies with `gclient sync`, this will overwrite
`backend.star` with `template.star` and may update `container_image`.

# Configure NativeLink cloud

*TODO:* Make `instance_name` configurable (or add it as another default).
Add support for `label:action_default`, `label:action_large`, and
`InputRootAbsolutePath` platform properties (set them to `priority` for now).
`Environment Variables` should be exported to both the image and the worker
configuration.

In the `Worker Configuration` on https://app.nativelink.com/ set
- `Instance Name` to
    `projects/rbe-chromium-untrusted/instances/default_instance`
- `Image` and `Container Image` to `container_image` in `backend.star`.
    This should be something like
    `docker://gcr.io/chops-public-images-prod/rbe/siso-chromium/linux@sha256:HASH`
- `Environment Variables` to
    `PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin`

# Build Chromium with the NativeLink cloud

Open `Settings` on `https://app.nativelink.com/` to get your `API_KEY`, `SCHEDULER_ADDRESS`, and `CAS_ADDRESS`.
In `chromium/src` start the build with
```
X_NATIVELINK_API_KEY=API_KEY \
autoninja \
-C out/Default \
-project rbe-chromium-untrusted \
-reapi_address SCHEDULER_ADDRESS \
-reapi_cas_address CAS_ADDRESS \
chrome
```

# Configure NativeLink on-prem

Siso sets the following platform properties by default
- `InputRootAbsolutePath` is a Boolean to indicate, whether an absolute path is
    required. Mainly for debug reasons.
- `label:action_default` is set to `1` for default build actions.
- `label:action_large` is set to `1` for resource intensive build actions.
    Consider setting this only to workers with enough compute resources.

Add support for these platform properties by adding to the scheduler
configuration
```
"supported_platform_properties": {
    "label:action_default": "minimum",
    "label:action_large": "minimum",
    "InputRootAbsolutePath": "priority"
}
```

Set the instance name to
```
"instance_name": "projects/rbe-chromium-untrusted/instances/default_instance"
```

Some Python scripts require Python to be in `PATH`.
Add to the worker configuration
```
"additional_environment": {
    "PATH": {
        "value": "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    }
}
```

# Build Chromium on-prem

In `chromium/src` start the build with
```
autoninja \
-C out/Default \
-project rbe-chromium-untrusted \
-reapi_address SCHEDULER_ADDRESS \
-reapi_cas_address CAS_ADDRESS \
chrome
```
where `SCHEDULER_ADDRESS` and `CAS_ADDRESS` point to the NativeLink Scheduler
and CAS.
Note that you need to configure authentication
(see https://chromium.googlesource.com/infra/infra/go/src/infra/+/84ece7f58102/build/siso/auth/cred)
or use an insecure connection with `-reapi_insecure`.

To try it out, build a container with the official `siso-chromium` image bundled
with `nativelink` and `basic_cas.json5` and run it
```
nix run .#chromium-worker.copyToDockerDaemon
docker run --network host chromium-worker:latest
```

In this case, start the build in `chromium/src` with
```
autoninja \
-C out/Default \
-project rbe-chromium-untrusted \
-reapi_address 127.0.0.1:50051 \
-reapi_insecure \
chrome
```
