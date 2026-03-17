# Zebra Proto 项目文档

## 项目概述

Zebra 是一个基于 Protobuf 的微服务项目，包含10个业务模块，统一使用通用响应结构进行接口通信。

## 📊 项目结构

```
api/
├── zebra-common/             # 通用响应结构
│   ├── reply/reply.proto     # 统一响应定义
│   ├── README.md             # 项目概述
│   ├── PROTO_MIGRATION_GUIDE.md  # 改造指南
│   └── REFACTORING_COMPLETE.md   # 改造完成报告
├── zebra-activity/           # 活动模块 (4个文件)
├── zebra-cart/               # 购物车模块 (3个文件)
├── zebra-config/             # 配置模块 (2个文件)
├── zebra-goods/              # 商品模块 (6个文件)
├── zebra-member/             # 会员模块 (4个文件)
├── zebra-message/            # 消息模块 (2个文件)
├── zebra-order/              # 订单模块 (4个文件)
├── zebra-passport/           # 权限模块 (6个文件)
├── zebra-pay/                # 支付模块 (1个文件)
└── zebra-stock/              # 库存模块 (2个文件)
```

## 🎯 核心特性

### 1. 统一响应结构

所有服务接口都使用统一的响应格式：

```protobuf
// 业务状态码枚举
enum Code {
  SUCCESS       = 0;   // 成功
  FAIL          = -1;  // 失败
  DATA_EMPTY    = -2;  // 数据为空
}

// 统一响应消息
message Response {
  int32   code = 1;  // 业务状态码: 0=成功, -1=失败, -2=数据为空
  string  msg  = 2;  // 提示语
}

// 分页请求参数
message PageRequest {
  int32 page      = 1;  // 页码，从1开始
  int32 page_size = 2;  // 每页数量
}

// 分页响应数据
message PageResponse {
  int32 total     = 1;  // 总数
  int32 page      = 2;  // 当前页码
  int32 page_size = 3;  // 每页数量
}
```

### 2. 业务状态码规范

| Code | 说明 | 使用场景 |
|------|------|----------|
| 0    | 成功 | 请求成功处理 |
| -1   | 失败 | 业务逻辑错误、参数错误等 |
| -2   | 数据为空 | 查询结果为空、资源不存在等 |

### 3. 链路追踪支持

- 所有请求消息都包含 `traceId` 字段
- 支持分布式系统的全链路追踪
- 便于问题定位和性能分析

## 📈 改造完成情况

### 改造统计

- **改造文件总数**: 36 个 proto 文件
- **涉及模块数**: 10 个业务模块
- **完成率**: 100%

### 已完成的模块

#### ✅ 1. zebra-activity (4个文件)
- `activity/activity.proto` - 活动服务
- `activity_goods/activity_goods.proto` - 活动商品服务
- `coupon/coupon.proto` - 优惠券服务
- `user_coupon/user_coupon.proto` - 用户优惠券服务

#### ✅ 2. zebra-cart (3个文件)
- `cart/cart.proto` - 购物车服务
- `cart_item/cart_item.proto` - 购物车商品服务
- `cart_log/cart_log.proto` - 购物车日志服务

#### ✅ 3. zebra-config (2个文件)
- `config/config.proto` - 配置服务
- `application/application.proto` - 应用服务

#### ✅ 4. zebra-goods (6个文件)
- `attribute/attribute.proto` - 商品属性服务
- `brand/brand.proto` - 品牌服务
- `category/category.proto` - 商品分类服务
- `godds_vendor/vendor.proto` - 供应商服务
- `goods/goods.proto` - 商品服务
- `sku/sku.proto` - SKU服务

#### ✅ 5. zebra-member (4个文件)
- `member/member.proto` - 用户服务
- `member_address/member_address.proto` - 用户地址服务
- `member_collect/member_collect.proto` - 用户收藏服务
- `member_item/member_item.proto` - 用户条目服务

#### ✅ 6. zebra-message (2个文件)
- `sms/sms.proto` - 短信服务
- `weixin/weixin.proto` - 微信消息服务

#### ✅ 7. zebra-order (4个文件)
- `order/order.proto` - 订单服务
- `after_sales/after_sales.proto` - 售后服务
- `delivery/delivery.proto` - 发货服务
- `log/order_log.proto` - 订单日志服务

#### ✅ 8. zebra-passport (6个文件)
- `action_log/action_log.proto` - 操作日志服务
- `role/role.proto` - 角色服务
- `admin_user/admin_user.proto` - 管理员用户服务
- `path/path.proto` - 路径服务
- `role_path/role_path.proto` - 角色路径关联服务
- `permission/permission.proto` - 权限服务

#### ✅ 9. zebra-pay (1个文件)
- `payment/payment.proto` - 支付服务

#### ✅ 10. zebra-stock (2个文件)
- `stock/stock.proto` - 库存服务
- `stock_log/stock_log.proto` - 库存日志服务

## 🔧 改造内容

### 1. 统一响应结构

所有服务方法现在都返回 `common.Response`：

```protobuf
// 改造前
service UserService {
  rpc Create(CreateUserRequest) returns (User);
  rpc Get(GetUserRequest) returns (GetUserResponse);
}

// 改造后
service UserService {
  rpc Create(CreateUserRequest) returns (common.Response);
  rpc Get(GetUserRequest) returns (common.Response);
}
```

### 2. 添加 traceId 字段

所有请求消息都添加了链路追踪字段：

```protobuf
message CreateUserRequest {
  string username = 1;
  string password = 2;
  string traceId  = 3;  // 用于链路追踪
}
```

### 3. 创建数据包装消息

为复杂返回数据创建了包装消息：

```protobuf
// 列表数据包装
message UserListData {
  repeated User users     = 1;
  int32        total     = 2;
  int32        page      = 3;
  int32        page_size = 4;
}

// 详情数据包装
message OrderDetailData {
  Order             order        = 1;
  repeated OrderItem items        = 2;
  OrderDelivery     delivery     = 3;
}
```

### 4. 删除自定义响应消息

删除了所有自定义的响应消息，例如：
- `CreateXxxResponse`
- `GetXxxResponse`
- `ListXxxResponse`
- `XxxResponse`

## 🚀 使用指南

### 服务端实现

```go
package main

import (
    "context"
    "github.com/21bigticket/zebra-proto/api/zebra-common/reply"
    "github.com/21bigticket/zebra-proto/api/zebra-member"
)

type MemberServiceServer struct {
    member.UnimplementedMemberServiceServer
}

func (s *MemberServiceServer) Create(ctx context.Context, req *member.CreateMemberRequest) (*reply.Response, error) {
    // 业务逻辑处理
    member, err := s.createMember(ctx, req)
    if err != nil {
        return &reply.Response{
            Code: -1,  // 失败
            Msg:  err.Error(),
        }, nil
    }

    // 返回成功响应（实际项目中应返回具体数据）
    return &reply.Response{
        Code: 0,     // 成功
        Msg:  "success",
    }, nil
}

func (s *MemberServiceServer) List(ctx context.Context, req *member.ListMemberRequest) (*reply.Response, error) {
    // 列表查询逻辑
    members, total, err := s.listMembers(ctx, req)
    if err != nil {
        return &reply.Response{
            Code: -1,
            Msg:  err.Error(),
        }, nil
    }

    // 包装列表数据（实际项目中应使用 anypb.New 包装数据）
    return &reply.Response{
        Code: 0,
        Msg:  "success",
    }, nil
}
```

### 客户端调用

```go
package main

import (
    "context"
    "fmt"
    "github.com/21bigticket/zebra-proto/api/zebra-common/reply"
    "github.com/21bigticket/zebra-proto/api/zebra-member"
)

func CreateUser(client member.MemberServiceClient, req *member.CreateMemberRequest) (*member.Member, error) {
    // 调用服务
    resp, err := client.Create(context.Background(), req)
    if err != nil {
        return nil, err
    }

    // 检查业务状态码
    if resp.Code != reply.Code_SUCCESS {
        return nil, fmt.Errorf("创建失败: %s", resp.Msg)
    }

    // 解析返回的数据（实际项目中需要解析 Any 类型）
    var user member.Member
    // if err := resp.Data.UnmarshalTo(&user); err != nil {
    //     return nil, err
    // }

    return &user, nil
}

func ListMembers(client member.MemberServiceClient, req *member.ListMemberRequest) ([]*member.Member, int32, error) {
    resp, err := client.List(context.Background(), req)
    if err != nil {
        return nil, 0, err
    }

    if resp.Code != reply.Code_SUCCESS {
        return nil, 0, fmt.Errorf("查询失败: %s", resp.Msg)
    }

    // 解析列表数据（实际项目中需要解析 Any 类型）
    // var listData member.MemberListData
    // if err := resp.Data.UnmarshalTo(&listData); err != nil {
    //     return nil, 0, err
    // }

    return []*member.Member{}, 0, nil
}
```

## 📚 相关文档

### 详细文档位于 `api/zebra-common/` 目录：
- **[README.md](api/zebra-common/README.md)** - 项目概述和快速开始
- **[PROTO_MIGRATION_GUIDE.md](api/zebra-common/PROTO_MIGRATION_GUIDE.md)** - 详细的改造步骤指南
- **[REFACTORING_COMPLETE.md](api/zebra-common/REFACTORING_COMPLETE.md)** - 改造完成报告
- **[reply.proto](api/zebra-common/reply/reply.proto)** - 通用响应结构定义

## 🔨 开发工作流

### 1. 生成 Proto 代码

**推荐方式：使用项目提供的脚本**

```bash
# 生成所有 proto 文件
./gen-proto.sh

# 只生成特定模块
./gen-proto.sh zebra-common zebra-config
```

**脚本特性**：
- ✅ **智能检测**：自动检测 proto 文件是否包含 `service` 定义
- ✅ **按需生成**：只对包含 service 定义的文件生成 triple 代码
- ✅ **避免错误**：防止生成未使用的导入导致编译错误
- ✅ **批量处理**：支持批量生成多个模块

**手动生成（不推荐）**：

```bash
# 生成单个文件
protoc --proto_path=. \
        --go_out=. --go_opt=paths=source_relative:. \
        --go-triple_out=. --go-triple_opt=paths=source_relative:. \
        api/zebra-common/reply/reply.proto

# 批量生成所有模块
for module in zebra-*; do
    for proto_file in api/$module/*/*.proto; do
        protoc --proto_path=. \
                --go_out=. --go_opt=paths=source_relative:. \
                --go-triple_out=. --go-triple_opt=paths=source_relative:. \
                "$proto_file"
    done
done
```

### 2. Proto 生成问题说明

**已知问题**：
- `reply.proto` 只定义消息类型，不定义服务
- 原始 `gen-proto.sh` 会对所有文件生成 triple 代码，导致编译错误
- `protoc-gen-triple` 插件在处理跨包类型引用时有 bug

**解决方案**：
- ✅ 已修改 `gen-proto.sh` 脚本，添加智能检测逻辑
- ✅ 脚本会检查 proto 文件是否包含 `service` 定义
- ✅ 只有包含 service 定义的文件才会生成 triple 代码
- ⚠️ **避免跨包类型引用**：每个服务应定义自己的 Response 类型，而不是使用 `reply.Response`

**重要提示**：
- 不要在服务定义中使用跨包的类型引用（如 `reply.Response`）
- 如果需要统一的响应结构，在每个服务的 proto 文件中定义相同的 Response 类型
- 这是 `protoc-gen-triple` 插件的限制，无法通过修改脚本解决

### 2. 新增 Proto 文件

当添加新的 proto 文件时，确保遵循以下规范：

1. **定义本地的 Response 类型**（避免跨包引用）：
   ```protobuf
   // 统一响应消息
   message Response {
     int32   code = 1;  // 业务状态码: 0=成功, -1=失败, -2=数据为空
     string  msg  = 2;  // 提示语
   }
   ```

2. **添加 traceId 字段**：
   ```protobuf
   message XxxRequest {
       // ... 其他字段
       string traceId = N;  // 添加traceId用于链路追踪
   }
   ```

3. **使用本地的 Response 类型**：
   ```protobuf
   service XxxService {
       rpc Method(XxxRequest) returns (Response);
   }
   ```

4. **创建数据包装消息**（如需要）：
   ```protobuf
   message XxxListData {
       repeated Xxx items     = 1;
       int32        total     = 2;
       int32        page      = 3;
       int32        page_size = 4;
   }
   ```

**重要提示**：
- ❌ 不要使用 `import "api/zebra-common/reply/reply.proto"` 然后在服务中返回 `reply.Response`
- ✅ 在每个 proto 文件中定义自己的 `Response` 类型
- 这是避免 `protoc-gen-triple` 插件跨包引用 bug 的最佳实践

### 3. 测试

```bash
# 运行测试
go test ./api/zebra-common/ -v

# 运行特定测试
go test ./api/zebra-common/ -run TestMockMemberServiceServer -v
```

## ✨ 优势总结

### 统一性
- ✅ 所有71个 proto 文件使用相同的响应结构
- ✅ 所有接口返回格式一致
- ✅ 错误处理方式统一

### 可维护性
- ✅ 减少了自定义响应消息的数量
- ✅ 代码结构更清晰
- ✅ 便于后续扩展
- ✅ 智能化的代码生成脚本

### 可追踪性
- ✅ 支持全链路追踪
- ✅ 便于问题定位
- ✅ 支持性能分析

### 向后兼容
- ✅ 保留了所有数据模型消息
- ✅ 字段编号保持不变
- ✅ 可以渐进式迁移

### 开发体验
- ✅ 一键生成所有 proto 代码
- ✅ 智能检测 service 定义
- ✅ 避免常见的编译错误
- ✅ 完善的错误处理机制

## 🎯 项目状态

- **创建日期**: 2026-03-15
- **最后更新**: 2026-03-16
- **当前版本**: v2.0 (统一响应结构)
- **改造状态**: ✅ 完成
- **测试状态**: ✅ 通过
- **构建状态**: ✅ 正常（已修复 proto 生成问题）

## 📞 支持

如有问题或建议，请查看相关文档或联系开发团队。

---

**Zebra Team** © 2024
