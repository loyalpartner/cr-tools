

## windows 构建

```bash
export DEPOT_TOOLS_WIN_TOOLCHAIN_BASE_URL=/home/lee/google/
export GYP_MSVS_HASH_27370823e7=7f6ff83055
gclient runhooks
```

```bash
target_os = "win"
is_debug = false
dcheck_always_on = false
is_component_build = false
is_official_build = true
# use_goma = true
symbol_level = 0
enable_nacl = false
blink_symbol_level=0
v8_symbol_level=0
# cc_wrapper = "sccache"
chrome_pgo_phase = 0
```

## 打包 deb 和 rpm

```
autoninja -C out/Release chrome/installer:installer
```

## ts 补全

```
./ash/webui/personalization_app/tools/gen_tsconfig.py --root_out_dir out/Default --gn_target chrome/browser/resources/bookmarks:build_ts
```
