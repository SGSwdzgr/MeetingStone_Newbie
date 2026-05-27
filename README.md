### 置顶提醒
- 由于集合石插件通信限制，晚间及周四白天高峰时段极有可能看不到新兵标记，这是网易集合石本身数据延迟导致的，本插件无法解决此问题，此时自己开组也看不到新兵信息  
实在感觉有问题，可以`/msd`看下是否有新兵信息的发包记录。若有，等待网易服务器返回数据即可
- 如果你的网易集合石显示的全是“未知目标”，看不到别人的队伍，请手动删除Addons路径下的`MeetingStoneEX`模块，这是你之前开心集合石等修改版集合石的补充模块，会有冲突
- 网易集合石返回的数据并不是必然准确，如果你认为一个人的新兵/老兵数据十分“可疑”，建议使用网易大神的“大米战绩”功能查询其真实10+大秘境次数，并佐以英雄榜成就的“战团导师：至暗之夜”数量来辅助判断（看他有几个满级号）

***

[![NGA](https://img.shields.io/badge/NGA-插件研究-590000?style=flat)](https://bbs.nga.cn/read.php?tid=46578826) [![新手盒子](https://img.shields.io/badge/新手盒子-新兵增强-93D925?style=flat)](https://www.wclbox.com/games/1/PluginItem/20419?version=2) [![GitHub release](https://img.shields.io/github/v/release/SGSwdzgr/MeetingStone_Newbie?logo=github)](https://github.com/SGSwdzgr/MeetingStone_Newbie/releases)

你应该已经知道，国服在[艾泽拉斯冒险手册](https://wow.blizzard.cn/h5/20260306/winbackiii/#/)活动中有个“向导嘉奖”玩法，它要求你每周至少完成10次“新兵训练”方可领取周奖励宝箱，获取用于抽奖的鱼串和宝箱  
但由于“新兵”的判断是战网维度，且暴雪和网易都没有提供官方的API接口来判断玩家是否为新兵，目前只能通过网易官方的[集合石插件](https://www.curseforge.com/wow/addons/meetingstone-netease)来间接识别

<details>

<summary>原版效果展示</summary>

<img src="https://github.com/user-attachments/assets/51a307f7-6607-4dec-9dec-ec4d1f82cb04" />

</details>

本插件基于网易集合石的新兵判断逻辑和本地缓存，将原本仅支持自己开组时查看的新兵信息拓展到集合石列表页和游戏原生的鼠标提示*中，在集合石寻找队伍时即可看到队长的新兵标志**，更方便完成每周的向导嘉奖任务  
**仅支持集合石已缓存过新兵数据的角色*  
***受预组队接口限制，仅支持队长信息查询，无法获取队伍成员信息*

<img src="https://github.com/user-attachments/assets/129d195c-2d89-4874-ad6d-ddccb197bf4a" />  
<img width="381" height="339" alt="image" src="https://github.com/user-attachments/assets/c83deabf-3d1f-406a-9752-1897e55d11f5" />

### 插件安装

可通过[新手盒子](https://www.wclbox.com/games/1/PluginItem/20419?version=2)一键安装和更新维护

或通过[Github Releases](https://github.com/SGSwdzgr/MeetingStone_Newbie/releases)下载最新版本，将解压后的`MeetingStone_Newbie`文件夹置入`World of Warcraft\_retail_\Interface\AddOns`路径，与`MeetingStone`同级即可

插件无开关和配置功能，安装即生效，每次加载后你会看到一条提示信息，代表加载成功

使用插件前**必须安装网易原版集合石插件**（Beta 12.1.4 以上），各国产插件平台和[CurseForge](https://www.curseforge.com/wow/addons/meetingstone-netease)均可下载，搜索 集合石MeetingStone（NetEase）即可

**不兼容**开心集合石和各整合包的修改版，它们大多阉割了网易的联网查询功能，导致无法获取新兵数据

### 插件原理、安全性和更多功能

- 若目标角色没有新兵/老兵标记，网易集合石会在两种情况下查询并返回新兵/老兵标记：
  1. 目标角色作为队长，出现在队伍列表中，你每次搜索/刷新会统一提交一轮针对所有队长的验证查询
  2. 目标角色申请了你开组/所在的队伍，进入申请列表时会单独提交一次验证查询
- 集合石云端服务器收到验证查询申请后，会通过插件通信下发新兵/老兵的判断结果，网易集合石在游戏客户端处理后缓存到插件内存中(关闭/开启游戏时还会存储/读取WTF存档中的已有数据)
- 增强插件即根据这套缓存数据，把原本只在申请列表显示的新兵标记展示到队伍列表和鼠标提示中，所以不会有额外的信息提交，也不会干扰集合石正常运行，但也因此不能提供集合石本身已查询信息之外的额外数据增量
- 你可以使用/msd命令查看详细的新兵数据收发详情
  <details>
  <summary>截图和细节说明</summary>

  这里展示的信息就是集合石插件和云端的数据沟通详情，并非由本插件发送，我们只是个浏览器

  内存数据中的“余XX分”代表新兵数据的过期时间，新兵数据自集合石返回至本地，只有5小时的有效时间（或者说生命周期），过期则不采信此新兵线索（与集合石插件自身采用的逻辑一致）

  | <img src="https://github.com/user-attachments/assets/73cdda96-9d81-4504-891e-c4c57139475a" /> | <img src="https://github.com/user-attachments/assets/e011924e-b151-46e5-9cbb-c3a6fbcc803e" /> |
  |--|--|

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

  </details>

- 由于暴雪禁止插件联网，网易集合石的数据需要依靠云端服务帐号(S1Alliance/S1Horde)与本地客户端进行插件通信来交互，受服务账号的插件通信带宽影响(猜测)，高峰时段(每日晚间/周四白天)的数据延迟则相当严重，很可能无法及时返回身份标记数据


### 已知问题

- 新兵必须自己开组/在你队伍中申请过集合石方可获得身份标记，并非全量返回
- 高峰时段(每天晚上/周四白天)返回不了数据
- 网易集合石间歇性抽风，无法正常工作
- 偶尔有极小几率返回错误数据(见置顶提醒)

这些问题都是网易集合石自己带来的，新兵增强插件完全依赖网易集合石本身对新兵的判断和标记，无法解决上述问题

对于无法通过增强插件判断的角色，目前比较可靠的方案是通过游戏内对比成就or查网页英雄榜成就，搭配网易大神App“大米战绩”，看ta的本赛季的10层开门成就、至暗之夜战团导师成就和近期大秘境记录，新兵身份要求战网账号下本赛季少于10次10层大秘境记录，战团成就能很好的反应ta是否只有这一个角色在打大秘境，查战绩则可以判断ta是否是一个本连打了N次，准确性其实相当高
