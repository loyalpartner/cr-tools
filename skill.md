

```
find ./components ./printing ./content ./extensions  ./chrome -name '*.[h,cc]' > cscope.files
cscope -b
```


查看 api

```
tail -n +4 webstore_private.json | jq '.[].functions|.[].name
```

### chromium pretty print

chromium 提供了 `tools/gdb/gdbinit`, 用于支持 libc++ 和 chromium 类型的
pretty-printing. `source tools/gdb/gdbinit` 后发现 pretty-printing 没有
起作用?

原因是 chromium 里面的 libc++ (buildtools/third_party/libc++/\_\_config\_site) 
默认的ABI命名空间是修改过的, 是 `std::Cr`, 而其提供的 printers.py 还认为
默认的ABI命名空间是 `std::__xx`

解决办法

将 buildtools/third_party/libc++/trunk/utils/gdb/libcxx/printers.py 里的
`std::__.*?::` 修改成 `std::Cr::`

```
sed  '/::__\.\*\?/s/__\.\*?/Cr/' buildtools/third_party/libc++/trunk/utils/gdb/libcxx/printers.py  -i
```
