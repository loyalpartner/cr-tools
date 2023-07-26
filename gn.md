

### 快速编译单元测试

```
autoninja -C out/Debug "$(gn refs out/Debug url/gurl_unittest.cc --as=output)"
```


### 计算插件ID

```
echo -n $PUBLIC_KEY | base64 --decode |  shasum -a 256 | head -c32 | tr 0-9a-f a-p
```
