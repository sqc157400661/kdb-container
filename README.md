# kdb-container

#### 介绍
{**以下是 Gitee 平台说明，您可以替换此简介**
Gitee 是 OSCHINA 推出的基于 Git 的代码托管平台（同时支持 SVN）。专为开发者提供稳定、高效、安全的云端软件开发协作平台
无论是个人、团队、或是企业，都能够用 Gitee 实现代码托管、项目管理、协作开发。企业项目请看 [https://gitee.com/enterprises](https://gitee.com/enterprises)}

#### 软件架构
软件架构说明


#### 安装教程

1.  xxxx
2.  xxxx
3.  xxxx

#### MySQL 8.0 镜像

`mysql/docker/80/Dockerfile` 支持两种构建模式：默认
`MYSQL_INSTALL_DEBS=1` 用本地 `.deb` 安装 MySQL；离线 Runner 使用
`MYSQL_BASE_IMAGE=kdbdeveloper/mysql80:v0.0.7`、`MYSQL_INSTALL_DEBS=0` 做
overlay，只覆盖当前仓库的初始化脚本、supervisor 配置和 MySQL 配置，不访问
网络。完整安装模式也必须提前准备 Debian 索引及依赖，不能在
`--network=none` 的空环境中假定 `apt-get -f install` 能成功。

远程可复现构建入口见
[`kdb-project/scripts/remote-dev/README.md`](../kdb-project/scripts/remote-dev/README.md)。

#### 参与贡献

1.  Fork 本仓库
2.  新建 Feat_xxx 分支
3.  提交代码
4.  新建 Pull Request


#### 特技

1.  使用 Readme\_XXX.md 来支持不同的语言，例如 Readme\_en.md, Readme\_zh.md
2.  Gitee 官方博客 [blog.gitee.com](https://blog.gitee.com)
3.  你可以 [https://gitee.com/explore](https://gitee.com/explore) 这个地址来了解 Gitee 上的优秀开源项目
4.  [GVP](https://gitee.com/gvp) 全称是 Gitee 最有价值开源项目，是综合评定出的优秀开源项目
5.  Gitee 官方提供的使用手册 [https://gitee.com/help](https://gitee.com/help)
6.  Gitee 封面人物是一档用来展示 Gitee 会员风采的栏目 [https://gitee.com/gitee-stars/](https://gitee.com/gitee-stars/)
