# =============================================================================
# BepInEx for V Rising ARM64 - README
# =============================================================================

## About This Directory

This directory contains default BepInEx configuration files that will be copied
to the server directory on first startup if BepInEx is not already installed.

## Contents

```
bepinex/
├── doorstop_config.ini          # Unity Doorstop configuration
├── addition_stuff/
│   └── box64.rc                 # Box64 optimization settings
└── README.md                    # This file
```

## ARM64 Compatibility

BepInEx on ARM64 requires special consideration:

1. **Il2CppInterop Issue**: The standard Il2CppInterop uses multithreaded file
   writing which crashes under Box64 emulation.

2. **Solution**: The tsx-cloud project provides a patched version that disables
   problematic multithreading: https://github.com/tsx-cloud/Il2CppInterop

3. **Pre-generated Assemblies**: For best results, generate interop assemblies
   on an x86_64 machine first, then copy them to ARM64.

## Using Pre-built Image (Recommended)

The easiest way to get BepInEx working on ARM64 is to use the pre-built image:

```yaml
image: tsxcloud/vrising-ntsync:latest
```

This image includes:
- Patched Il2CppInterop
- Pre-configured Box64 settings
- All necessary dependencies

## Installing Plugins

1. Enable plugins in your docker-compose:
   ```yaml
   environment:
     - ENABLE_PLUGINS=true
   ```

2. Place plugin `.dll` files in:
   ```
   /mnt/vrising/server/BepInEx/plugins/
   ```

3. Restart the server

## Box64 Configuration

The `box64.rc` file contains optimized settings for V Rising. Key settings:

- `BOX64_DYNAREC=1` - Enable dynamic recompilation
- `BOX64_DYNAREC_BIGBLOCK=2` - Larger compilation blocks
- `BOX64_DYNAREC_BLEEDING_EDGE=1` - Latest optimizations

## Troubleshooting

### Plugins not loading

1. Check if doorstop is enabled:
   ```bash
   cat /mnt/vrising/server/doorstop_config.ini | grep enabled
   ```

2. Check BepInEx logs:
   ```bash
   cat /mnt/vrising/server/BepInEx/LogOutput.log
   ```

### Server crashes with plugins

1. Try disabling plugins first: `ENABLE_PLUGINS=false`
2. Enable one plugin at a time to find the problematic one
3. Check if the plugin is compatible with the current V Rising version

## Links

- [BepInEx Documentation](https://docs.bepinex.dev/)
- [tsx-cloud/vrising-ntsync](https://github.com/tsx-cloud/vrising-ntsync)
- [V Rising Mods on Thunderstore](https://v-rising.thunderstore.io/)
- [Box64 Documentation](https://github.com/ptitSeb/box64/blob/main/docs/USAGE.md)
