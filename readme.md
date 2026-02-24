### zebra-proto
zebra-proto/
├── api/                          # 所有 proto 定义
│   ├── hello.proto               # 示例/测试接口
│   ├── zebra-activity/           # 营销活动服务
│   │   ├── activity/             # 活动管理
│   │   ├── activity_goods/       # 活动商品
│   │   ├── coupon/               # 优惠券
│   │   └── user_coupon/          # 用户优惠券
│   ├── zebra-cart/               # 购物车服务
│   │   ├── cart/                 # 购物车
│   │   ├── cart_item/            # 购物车项
│   │   └── cart_log/             # 购物车日志
│   ├── zebra-config/             # 配置中心服务
│   ├── zebra-goods/              # 商品服务
│   │   ├── goods/                # 商品(SPU)
│   │   ├── sku/                  # SKU
│   │   ├── category/             # 分类
│   │   ├── brand/                # 品牌
│   │   ├── attribute/            # 属性
│   │   └── godds_vendor/         # 供应商
│   ├── zebra-member/             # 会员服务
│   ├── zebra-message/            # 消息服务
│   ├── zebra-order/              # 订单服务
│   ├── zebra-passport/           # 权限认证服务
│   ├── zebra-pay/                # 支付服务
│   └── zebra-stock/              # 库存服务
├── gen-proto.sh                  # Proto 代码生成脚本
└── go.mod                        # Go 模块定义

### 使用
开发人员修改 .proto 文件
        ↓
运行 ./gen-proto.sh
        ↓
生成 .pb.go (消息结构)
生成 .triple.go (Dubbo 服务接口)
        ↓
提交代码
        ↓
其他服务引用本仓库作为依赖# zebra-proto
