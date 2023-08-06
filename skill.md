

```
find ./components ./printing ./content ./extensions  ./chrome -name '*.[h,cc]' > cscope.files
cscope -b
```


查看 api

```
tail -n +4 webstore_private.json | jq '.[].functions|.[].name
```

### chromium pretty print

`source tools/gdb/gdbinit` 后, std::string 没有启用 pretty print, 原因是
libc++(`buildtools/third_party/libc++`) 默认的 
`\_LIBCPP_ABI_NAMESPACE` 默认为 Cr, std::string 在 gdb 里
的类型其实是 `std::Cr::string`, 而 libcxx 默认的 printers.py 默认的
`\_LIBCPP_ABI_NAMESPACE` 是 `__x`

解决办法

将 buildtools/third_party/libc++/trunk/utils/gdb/libcxx/printers.py 里的
`std::__.*?::` 修改成 `std::Cr::`

```
sed  '/::__\.\*\?/s/__\.\*?/Cr/' buildtools/third_party/libc++/trunk/utils/gdb/libcxx/printers.py  -i
```
