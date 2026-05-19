# HarmonyOS Build and Development Guide

## Quick Start

### Prerequisites

1. **Install DevEco Studio**
   - Download from: https://developer.huawei.com/consumer/cn/deveco-studio

2. **Configure HarmonyOS SDK**
   - SDK Version: 5.0.0(12)
   - API Version: 12

3. **Set Up Signing**
   - Configure signing profile
   - Generate certificate

### Building the Project

#### Using DevEco Studio

1. Open DevEco Studio
2. Open Project: `harmonyos/
3. Sync Gradle
4. Build -> Build Hap(s)/APP(s)
5. Deploy to device or emulator

#### Using Command Line (Future)

```bash
# Build debug build
hvigorw assembleHap --mode module -p product=default -p module=entry@default

# Build release
hvigorw assembleHap --mode module -p product=default -p module=entry@default -p release=true
```

## Project Structure

```
harmonyos/
├── AppScope/                 # App level configs
├── entry/                     # Main module
│   ├── src/main/
│   │   ├── ets/
│   │   │   ├── pages/       # UI pages
│   │   │   ├── utils/      # Utilities
│   │   │   └── entryability/
│   │   ├── cpp/             # NAPI bindings
│   │   └── resources/
│   └── build-profile.json5
├── native/                   # Rust core
│   └── harmony_ffi/         # NAPI bindings in Rust
└── oh-package.json5
```

## Rust NAPI Module

The Rust core provides native functionality via NAPI:

```typescript
// In TypeScript
import rustDeskCore from '../utils/RustDeskCore';

// Initialize
await rustDeskCore.initialize(appFilesPath);

// Connect to peer
await rustDeskCore.connectToPeer('REMOTE_ID', 'PASSWORD');
```

## Security Checklist

- ✅ Permissions requested on first use
- ✅ Clear permission rationale
- ✅ Error handling
- ✅ Code obfuscation
- ✅ Secure signing
- ⏳ Encrypted communication
- ⏳ Secure storage

## Development Workflow

1. **Setup:
   - Initialize project
   - Configure signing
   - Request permissions
2. **Develop UI:
   - Implement UI pages
   - Test UI interactions
3. **Integrate native:
   - Implement NAPI bindings
   - Test integration
4. **Testing and optimization:
   - Test on real device
   - Performance tuning
   - Market adaptation

## Tips for HarmonyOS Development

- Use DevEco Studio's inspector for debugging
- Test permissions on real devices
- Check official docs: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides

## Troubleshooting

### Common Issues

**Problem: NAPI module not found
Solution: Check build native first

**Problem: Permission denied
Solution: Check module.json5 permissions and request permissions at runtime

## Release Checklist

- All permissions requested and granted
- All features tested on real device
- Performance optimized
- Signed properly
- Store listing prepared
