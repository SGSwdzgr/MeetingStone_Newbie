[![NGA](https://img.shields.io/badge/NGA-插件研究-590000?style=flat)](https://bbs.nga.cn/read.php?tid=46578826) [![GitHub release](https://img.shields.io/github/v/release/SGSwdzgr/MeetingStone_Newbie?logo=github)](https://github.com/SGSwdzgr/MeetingStone_Newbie/releases)

你应该已经知道，雷火在[艾泽拉斯冒险手册](https://wow.blizzard.cn/h5/20260306/winbackiii/#/)活动中有个“向导嘉奖”玩法，它要求你每周至少完成10次“新兵训练”方可领取周奖励宝箱

但由于“新兵”的判断是战网维度，且暴雪和网易都没有提供官方的API接口来判断玩家是否为新兵，目前只能通过网易官方的[集合石插件](https://www.curseforge.com/wow/addons/meetingstone-netease)来间接识别

<details>

<summary>原版效果展示</summary>

<img src="https://github.com/user-attachments/assets/51a307f7-6607-4dec-9dec-ec4d1f82cb04" />

</details>

本插件即基于网易集合石的新兵判断逻辑和本地缓存，将原本仅支持自己开组时查看的新兵信息**拓展到列表页和游戏原生的鼠标提示中**，在集合石寻找队伍时即可看到队长的新兵标志（受预组队接口限制，仅支持队长信息查询，无法获取队伍成员信息），更方便完成每周的向导带新任务

<img src="https://github.com/user-attachments/assets/129d195c-2d89-4874-ad6d-ddccb197bf4a" />

*p.s.* 同时也支持在游戏原生的鼠标提示中查看（但需要集合石缓存过此角色的新兵数据）

<img width="381" height="339" alt="image" src="https://github.com/user-attachments/assets/c83deabf-3d1f-406a-9752-1897e55d11f5" />

### 插件安装

通过[Github Releases](https://github.com/SGSwdzgr/MeetingStone_Newbie/releases)下载最新版本，将解压后的MeetingStone_Newbie文件夹置入World of Warcraft\_retail_\Interface\AddOns路径，与MeetingStone同级即可

插件无开关和配置功能，安装即生效，每次加载后你会看到一条提示信息，代表加载成功

使用插件前**必须安装网易原版集合石插件**（Beta 12.1.4 以上），各国产插件平台和[CurseForge](https://www.curseforge.com/wow/addons/meetingstone-netease)均可下载，搜索 集合石MeetingStone（NetEase）即可

*p.s.* **不兼容**开心集合石和各整合包的修改版，它们大多阉割了网易的联网查询功能，导致无法获取新兵数据

### 插件原理、安全性和更多功能

插件使用网易集合石本地缓存数据，无额外信息提交，不干扰集合石正常运行，可使用/msd命令查看网易集合石返回的原始数据

<details>
  
<summary>截图和细节说明</summary>

这里展示的信息就是集合石插件和云端的数据沟通详情，并非由本插件发送，我们只是个浏览器

内存数据中的“余XX分”代表新兵数据的过期时间，新兵数据自集合石返回至本地，只有5小时的有效时间（或者说生命周期），过期则不采信此新兵线索（与集合石插件自身采用的逻辑一致）

| <img src="https://github.com/user-attachments/assets/73cdda96-9d81-4504-891e-c4c57139475a" /> | <img src="https://github.com/user-attachments/assets/e011924e-b151-46e5-9cbb-c3a6fbcc803e" /> |
|--|--|

</details>

因此，新兵信息的更新、展示完全依赖网易集合石的云端数据返回，目前实测，在工作日白天数据返回较为迅速，在晚间延迟则相当严重，还请酌情自行判断

*（<b>说大白话：</b>因为集合石查数据有延迟，有标记的肯定是新兵，没有的不一定不是。晚上这套系统工作的可能不太流畅，因为同时使用集合石的人太多了）*

```Plaintext
[ 客户端 Client ]
 ├─ 触发：UI 操作 (如打开集合石列表/鼠标悬停)
 │
 └─ [ 网易集合石插件 (Logic 模块) ]
     ├─ 1. 压栈：将目标队长 ID 压入待查队列 (InsertServerCQGLIB)
     └─ 2. 发包：定时打包队列，调用 SendAddonMessage 发送带前缀的密语
            │  (目标: S1Alliance / S1Horde)
            │
============│=== 【暴雪沙箱与网络边界】 ==========================
            │
            ▼
[ 魔兽世界游戏服务器 Server ]
 └─ 3. 路由：系统聊天网关处理 Whisper 请求
            │
            ▼
[ 网易服务端机器人 Service Bot ] (常驻挂机账号)
 ├─ 4. 监听：截获包含 CQGLIB 指令的密语
 └─ 5. 查询：向网易外部服务器请求数据
            │
            ▼
[ 网易外部数据库 Web/DB ]
 └─ 6. 响应：返回对应玩家的新兵状态
            │
[ 网易服务端机器人 Service Bot ]
 └─ 7. 回包：加密数据 (SQGLIB)，通过系统密语回复给对应客户端

============│=== 【暴雪沙箱与网络边界】 =========================
            │
            ▼
[ 客户端 Client ]
 └─ [ 网易集合石插件 (NetEaseSocket) ]
     ├─ 8. 接收：监听 CHAT_MSG_ADDON，截获 SQGLIB 回包
     └─ 9. 落库：解密数据，写入本地内存 AceDB (MEETINGSTONE_UI_DB)
            │
            ▼
 └─ [ 新兵增强插件 (Core.lua) ]
     ├─ 10. 穿透：通过 getfenv 提取私有类 MemberDisplay 并实施 Hook
     ├─ 11. 匹配：读取本地内存数据库，比对当前屏幕上的队长名字
     └─ 12. 渲染：执行 UI 注入，显示新兵图标与 Tooltip
```

### 特别提醒

- 安装后何时能看到列表页中的新兵取决于你何时安装的网易集合石，可以多刷新两次集合石，然后耐心等待

- 如果你在等待很久后仍然看不到新兵，请/msd查看“内存数据库”-“新兵”的最后更新时间，这是网易集合石返回的所有新兵信息

- 如果你还是没有，可以考虑关闭游戏后，搜索并删除_retail_/WTF中所有的MeetingStone.lua和MeetingStone.lua.bak文件，这是重置本地集合石数据的一种方式，然后重启游戏，等待他重新缓存即可

- 一切数据延迟/错误问题都是网易集合石导致的，与本增强插件无关
