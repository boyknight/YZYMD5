## YZYMD5

YZYMD5用Swift编程语言编写，用来计算文本和文件的MD5值，对于大文件只占用极少的内存。
YZYMD5可以用在iOS和MacOS的开发上。

 Computing MD5 hash of string or file with small memory usage in swift, supports iOS and MacOS

### 示例 Examples


计算文本字符串的MD5值
Computing MD5 hash of string

```markdown

let md5 = YZYMD5()
md5.update("hello world")
print(md5.digestHex())


输出：
Output:

5EB63BBBE01EEED093CB22BB8F5ACDC3

```

计算文件的MD5值
Computing MD5 hash of file


```markdown

let md5 = YZYMD5()
print(md5.digestHexFromFile("/Users/yzy/1.txt"))


输出：
Output:

5EB63BBBE01EEED093CB22BB8F5ACDC3

```


### 和我联系 Contact me

我的邮箱是：<14497294@qq.com> 欢迎交流。
My email address: <14497294@qq.com>

