

```
find ./components ./printing ./content ./extensions  ./chrome -name '*.[h,cc]' > cscope.files
cscope -b
```


查看浏览器

```
tail -n +4 webstore_private.json | jq '.[].functions|.[].name
```
