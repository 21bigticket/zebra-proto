# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Zebra Proto is a Protobuf-based microservice interface definition repository for an e-commerce system. It defines service interfaces using protobuf and generates Go code for Dubbo-go's Triple protocol.

**Module**: `github.com/21bigticket/zebra-proto`
**Go Version**: 1.26
**Protocol**: Dubbo-go Triple (based on gRPC)

## Project Structure

```
api/
├── hello.proto                  # Example/test service
├── zebra-activity/              # Activity and promotion services (4 proto files)
├── zebra-cart/                  # Shopping cart services (3 proto files)
├── zebra-config/                # Configuration services (2 proto files)
├── zebra-goods/                 # Product catalog services (6 proto files)
├── zebra-member/                # Member/user services (4 proto files)
├── zebra-message/               # Messaging services (SMS, WeChat) (2 proto files)
├── zebra-order/                 # Order services (4 proto files)
├── zebra-passport/              # Authentication and authorization (16 proto files)
├── zebra-pay/                   # Payment services (1 proto file)
└── zebra-stock/                 # Inventory services (2 proto files)
```

**Total**: 45 proto files, 221 RPC methods

## Common Commands

### Generate Proto Code

Generate Go code from all proto files:
```bash
./gen-proto.sh
```

Generate specific modules:
```bash
./gen-proto.sh zebra-member zebra-goods
```

This generates:
- `.pb.go` files - Message structures (protobuf standard)
- `.triple.go` files - Dubbo-go service interfaces

### Clean Generated Code

To clean all generated files:
```bash
find api -name "*.pb.go" -delete
find api -name "*.triple.go" -delete
```

### Module Management

Download dependencies:
```bash
go mod download
```

Tidy dependencies:
```bash
go mod tidy
```

## Code Architecture

### Service Definition Pattern

Each service proto file follows this structure:

```protobuf
syntax = "proto3";
package <service_name>;

import "google/protobuf/wrappers.proto";

option go_package = "./api/zebra-<module>/<service>;<package_name>";

// Request/Response messages
message XxxRequest {
  // Fields...
}

message XxxResponse {
  google.protobuf.Int32Value code = 1;  // Business status code
  string msg = 2;                        // Message
  // Data fields...
}

message Response {
  google.protobuf.Int32Value code = 1;
  string msg = 2;
}

// Service definition
service XxxService {
  rpc Method(XxxRequest) returns (XxxResponse);
  rpc AnotherMethod(XxxRequest) returns (Response);
}
```

### Response Pattern

Services use a consistent response pattern with `google.protobuf.Int32Value` for the status code:

- **code**: `0` = success, `-1` = failure, `-2` = empty data
- **msg**: Human-readable message
- **data fields**: Response payload (varies by method)

**Important**: Each service defines its own Response message types locally. Do not import response types from other packages to avoid `protoc-gen-triple` cross-package reference bugs.

### go_package Convention

The `go_package` option follows this pattern:
```
option go_package = "./api/zebra-<module>/<service>;<package_name>";
```

Example: `option go_package = "./api/zebra-member/member;member";`

## Design Guidelines

### Service Size Limits

**⚠️ IMPORTANT**: Each proto file should contain **no more than 10 RPC methods** per service.

**Rationale**:
- Smaller services are easier to understand, test, and maintain
- Follows Single Responsibility Principle
- Reduces cognitive load for developers
- Easier to version and evolve independently

**Current Violations** (need refactoring):
- `role.proto`: 12 methods - split into RoleService and RoleAuthService
- `activity.proto`: 12 methods - consider splitting by functionality

**Refactoring Strategy**:
When a service exceeds 10 RPC methods, split it by business domain:
```
// Before: UserService with 15 methods
service UserService {
  rpc Create(CreateUserRequest) returns (Response);
  rpc Update(UpdateUserRequest) returns (Response);
  rpc Delete(DeleteUserRequest) returns (Response);
  // ... 12 more methods
}

// After: Split into focused services
service UserService {
  rpc Create(CreateUserRequest) returns (Response);
  rpc Update(UpdateUserRequest) returns (Response);
  rpc Delete(DeleteUserRequest) returns (Response);
  rpc Get(GetUserRequest) returns (GetUserResponse);
  rpc List(ListUserRequest) returns (ListUserResponse);
}

service UserAuthService {
  rpc Login(LoginRequest) returns (LoginResponse);
  rpc Logout(LogoutRequest) returns (Response);
  rpc ResetPassword(ResetPasswordRequest) returns (Response);
}

service UserProfileService {
  rpc UpdateProfile(UpdateProfileRequest) returns (Response);
  rpc UploadAvatar(UploadAvatarRequest) returns (Response);
}
```

### File Organization

- **One service per proto file**: Each `.proto` file should define only one service
- **Domain-driven grouping**: Group related RPC methods in the same service
- **Clear naming**: Service names should reflect their domain responsibility

### Field Design Guidelines

#### Optional Fields in Update Requests

**⚠️ IMPORTANT**: Update request messages MUST use `optional` keyword for fields that are not required.

**Rationale**:
- Allows partial updates - only update fields that are explicitly set
- Distinguishes between "not set" and "set to default value"
- Prevents accidentally overwriting fields with default values

**Example**:
```protobuf
// ❌ BAD: All fields will be updated, even if not provided
message UpdateGoodsRequest {
  int64  id          = 1;
  string name        = 2;      // Will be set to "" if not provided
  int32  sort_order  = 3;      // Will be set to 0 if not provided
  int32  status      = 4;      // Will be set to 0 if not provided
}

// ✅ GOOD: Only provided fields will be updated
message UpdateRoleRequest {
  int64  role_id    = 1;       // Required: identifies which role to update
  optional string role_name  = 2;  // Optional: only update if provided
  optional string role_key   = 3;  // Optional: only update if provided
  optional int32  role_sort  = 4;  // Optional: only update if provided
  optional string status     = 5;  // Optional: only update if provided
  optional string remark     = 6;  // Optional: only update if provided
}
```

**Implementation Pattern**:
```go
// Server-side implementation
func (s *RoleServiceServer) Update(ctx context.Context, req *role.UpdateRoleRequest) (*role.Response, error) {
    updateData := make(map[string]interface{})

    // Only update fields that were explicitly set
    if req.RoleName != nil {
        updateData["role_name"] = req.RoleName.Value
    }
    if req.RoleKey != nil {
        updateData["role_key"] = req.RoleKey.Value
    }
    if req.RoleSort != nil {
        updateData["role_sort"] = req.RoleSort.Value
    }
    // ... and so on

    return s.repo.Update(req.RoleId, updateData)
}
```

**Current Violations** (need refactoring):
- `goods.proto`: UpdateGoodsRequest lacks optional fields
- `member.proto`: UpdateMemberRequest lacks optional fields
- Many other UpdateXxxRequest messages need to be updated

#### Integer Type for Status Codes

**⚠️ IMPORTANT**: Always use `google.protobuf.Int32Value` for status code fields that need to support 0 as a valid value.

**Rationale**:
- Proto3 `int32` has a default value of 0
- Cannot distinguish between "field not set" and "field set to 0"
- `Int32Value` wraps the int32 and allows null to represent "not set"

**Usage Pattern**:
```protobuf
import "google/protobuf/wrappers.proto";

// ✅ CORRECT: Use Int32Value for status codes
message GetRoleResponse {
  google.protobuf.Int32Value code = 1;  // 0=success, -1=failure, -2=empty
  string msg = 2;
  Role role = 3;
}

// ❌ AVOID: Direct int32 for codes (cannot distinguish 0 from unset)
message BadResponse {
  int32 code = 1;  // Is 0 a success code or just not set?
  string msg = 2;
}
```

**When to use each**:
- **Use `int32`**: When 0 is not a valid value (e.g., quantity, IDs, timestamps)
- **Use `Int32Value`**: When 0 is a valid value and you need to detect "not set" (e.g., status codes, optional numeric fields)

## Key Implementation Details

### Apache License Headers

All proto files include Apache 2.0 license headers (except hello.proto which is a simple example).

### Dubbo-go Triple Protocol

- Uses `--go-triple_out` protoc plugin
- Generated interfaces follow Dubbo-go conventions
- Services implement `UnimplementedXxxServiceServer` embedded struct

### Field Naming Conventions

- **Snake_case** for protobuf field names
- **PascalCase** for message types
- **PascalCase** for service names
- Timestamps use `int64` (Unix milliseconds)

### Common Message Patterns

#### Pagination
```protobuf
message ListRequest {
  int32 page = 1;       // 1-based
  int32 page_size = 2;
}
```

#### Soft Delete
Messages often include `int32 is_deleted` field.

#### Timestamps
Use `int64` for create_time and update_time (milliseconds since epoch).

## Known Issues

### protoc-gen-triple Cross-Package References

The `protoc-gen-triple` plugin has issues with cross-package type references. **Always define Response types locally in each proto file** rather than importing them from a common package.

## Service Dependencies

This repository is consumed as a dependency by other microservices. After modifying proto files:
1. Run `./gen-proto.sh` to regenerate code
2. Commit both `.proto` and generated `.pb.go`/`.triple.go` files
3. Tag a new release if changes are breaking

## Module Statistics

Largest modules by RPC method count:
- **zebra-passport**: 62 methods (16 services) - auth, roles, permissions
- **zebra-activity**: 37 methods (4 services) - activities, coupons
- **zebra-goods**: 30 methods (6 services) - products, SKU, categories
- **zebra-cart**: 21 methods (3 services) - cart management
- **zebra-member**: 21 methods (4 services) - user management

See proto files for individual service method counts.
