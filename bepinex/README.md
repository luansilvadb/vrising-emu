# =============================================================================
# BepInEx README for ARM64
# =============================================================================

This directory should contain the pre-packaged BepInEx files for ARM64.

## Structure

When properly set up, this directory should contain:

```
bepinex/
├── BepInEx/
│   ├── core/
│   │   ├── BepInEx.Core.dll
│   │   ├── BepInEx.Unity.IL2CPP.dll
│   │   └── ... other core files
│   ├── plugins/
│   │   └── (empty - mods go here at runtime)
│   ├── config/
│   │   └── BepInEx.cfg
│   ├── patchers/
│   └── addition_stuff/
│       └── box64.rc
├── doorstop_config.ini
├── winhttp.dll
└── .doorstop_version
```

## ARM64 Compatibility

The standard BepInEx release has issues on ARM64 due to:
1. Il2CppInterop multithreading issues under Box64
2. Cpp2IL crashes during assembly generation

## Solutions

### Option 1: Use tsx-cloud Patched Version (Recommended)

The tsx-cloud project provides pre-generated interop assemblies:
https://github.com/tsx-cloud/vrising-ntsync

### Option 2: Generate on x86_64 Machine

1. Run BepInEx on an x86_64 machine first
2. Let it generate the interop assemblies
3. Copy the entire BepInEx folder here
4. The assemblies in `BepInEx/interop/` are the key files

### Option 3: Download Pre-packaged

Download from the releases page (if available) and extract here.

## Box64 Configuration

The `addition_stuff/box64.rc` file contains Box64-specific settings for V Rising:

```ini
[VRisingServer.exe]
BOX64_DYNAREC=1
BOX64_DYNAREC_BIGBLOCK=2
BOX64_DYNAREC_FASTROUND=1
BOX64_DYNAREC_FASTNAN=1
BOX64_DYNAREC_SAFEFLAGS=0
BOX64_DYNAREC_BLEEDING_EDGE=1
BOX64_MALLOC_HACK=1
```
