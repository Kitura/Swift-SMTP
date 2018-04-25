# 4.0.0 Migration Guide

- `User` struct now nested in `Mail` struct to avoid namespace issues. Create a user like so:

```swift
let sender = Mail.User(name: "Sloth", email: "sloth@gmail.com")
```

- `User` properties are now public

- The optional `accessToken` parameter of the `SMTP` struct has been removed. If you are using the authorization method `XOAUTH2`, pass in your access token in the `password` parameter instead. For example:

```swift
let smtp = SMTP(
    hostname: "smtp.gmail.com",
    email: "example@gmail.com",
    password: "accessToken",
    authMethods: [.xoauth2]
)
```

# 3.0.0 Migration Guide

## Initialize `SMTP`

Before `3.0.0`:

```swift
public init(hostname: String,
            email: String,
            password: String,
            port: Port = Ports.tls.rawValue,
            ssl: SSL? = nil,
            authMethods: [AuthMethod] = [],
            domainName: String = "localhost",
            accessToken: String? = nil,
            timeout: UInt = 10)
```

After `3.0.0`:

```swift
public init(hostname: String,
            email: String,
            password: String,
            port: Int32 = 465,
            useTLS: Bool = true,
            tlsConfiguration: TLSConfiguration? = nil,
            authMethods: [AuthMethod] = [],
            accessToken: String? = nil,
            domainName: String = "localhost",
            timeout: UInt = 10)
```

## Renamed

- `SSL` renamed to `TLSConfiguration`

## Removed

- `Port` typealias

## Other Changes

- `Mail` properties are now public
