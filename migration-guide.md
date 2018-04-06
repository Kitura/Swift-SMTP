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

`3.0.0`+:

```swift
let smtp = SMTP(hostname: String,
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
