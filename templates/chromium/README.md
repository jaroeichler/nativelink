# Setup Chromium

Fetch the Chromium sources and create the build targets
```bash
git clone https://chromium.googlesource.com/chromium/tools/depot_tools &&
mkdir chromium &&
cd chromium &&
fetch chromium &&
cd src &&
gn gen \
    --args="use_reclient=false use_remoteexec=true use_siso=true" \
    out/Default
```

See
[building Chromium on Linux](https://chromium.googlesource.com/chromium/src/+/main/docs/linux/build_instructions.md)
for more details.

With these settings, Chromium uses
[Siso](https://chromium.googlesource.com/infra/infra/+/refs/heads/main/go/src/infra/build/siso/)
as build tool.
Siso uses the platform properties defined in
`chromium/src/build/config/siso/backend_config/backend.star`
for remote execution.
Be careful when you update dependencies with `gclient sync`, this will overwrite
`backend.star` with `template.star` and may update `container_image`.

# Configure NativeLink cloud

On the [NativeLink cloud](https://app.nativelink.com/) under Remote Execution
(Advanced) add a Chromium worker with the following settings:
- `Image` and `Container Image (Platform Property)`: Specify the image from
    `backend.star`. It should be of the form
    `docker://gcr.io/chops-public-images-prod/rbe/siso-chromium/linux@sha256:HASH`.
- `Environment Variables`: Add
    `PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin`

# Build Chromium with the NativeLink cloud

Get your `CAS_ADDRESS`, `SCHEDULER_ADDRESS`, and `API_KEY` on the
[NativeLink cloud](https://app.nativelink.com/) under Settings.
In `chromium/src` start the build with:
```bash
X_NATIVELINK_API_KEY="API_KEY" \
    autoninja \
    -C out/Default \
    -project rbe-chromium-untrusted \
    -reapi_address "SCHEDULER_ADDRESS" \
    -reapi_cas_address "CAS_ADDRESS" \
    chrome
```

# NativeLink configuration

In the scheduler configuration, add
```json
"supported_platform_properties": {
  "InputRootAbsolutePath": "priority",
  "label:action_default": "priority",
  "label:action_large": "priority"
}
```

In the scheduler and CAS configuration, set
```json
"instance_name": "projects/rbe-chromium-untrusted/instances/default_instance"
```

In the worker configuration, add
```json
"additional_environment": {
  "PATH": {
    "value": "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
  }
}
```
