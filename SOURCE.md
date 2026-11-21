# 源码出处与完整性

## 是什么

三星公开的内核源码包，**未做任何修改**：

| 项 | 值 |
|---|---|
| 分发渠道 | Samsung Open Source Release Center（opensource.samsung.com） |
| 下载包 | `SM-G986U_NA_13_Opensource.zip` |
| 对应固件 | `G986USQU3GVK1`（Android 13，VZW，安全补丁 2022-11-01） |
| 包内文件 | `Kernel.tar.gz`、`Platform.tar.gz`、`README_Kernel.txt`、`README_Platform.txt` |
| 本仓库使用 | `Kernel.tar.gz`（+ `README_Kernel.txt` 一并存档） |
| `Kernel.tar.gz` 大小 | 215,891,343 B |
| `Kernel.tar.gz` sha256 | `a907ee24ad6bfd13df438f13e05a9179d8a5dece4257985bfc12236c6acfbe09` |
| 内核版本 | `4.19.113`（`Makefile`: 4.19.113），设备侧 `uname -r` = `4.19.113-25305888` |
| defconfig | `arch/arm64/configs/vendor/y2q_usa_singlew_defconfig` |
| 解压后大小 | 约 1.3 GB（`arch/` 占大头） |

`Platform.tar.gz`（ART / 平台层源码，与内核编译无关）本仓库未使用。

## 在哪

Release [`source-v1`](https://github.com/taowen/sm-g986u-kernel/releases/tag/source-v1)：

```
https://github.com/taowen/sm-g986u-kernel/releases/download/source-v1/Kernel.tar.gz
```

CI（`scripts/fetch-source.sh`）默认就从这个地址取，校验 sha256 后再解压。

## 为什么不直接进 git

单文件 216 MB，超过 GitHub 100 MB 的限制；拆包或 LFS 都只是把问题挪个地方。放 Release asset：

- 不占仓库对象存储，`git clone` 不会拖 216 MB
- 公开仓库的 Release asset 无需 token 即可下载，CI 里一条 `curl` 搞定
- 想要「仓库内自带源码」时，一样可以 `git clone` 后 `curl` 那一条

## 想自己从官方重新下一份

1. 打开 <https://opensource.samsung.com/uploadSearch?searchValue=SM-G986U>
2. 选版本 `G986USQU3GVK1`，下载 `SM-G986U_NA_13_Opensource.zip`
3. 校验：`sha256sum Kernel.tar.gz` 应等于上面的值

（该站点有 Cloudflare challenge，需要浏览器手动点一下；这也是本项目把它镜像到 Release 的原因之一。）

## 许可

内核源码为 **GPL-2.0**（`COPYING`），本仓库原样再分发。构建脚本同许可。
