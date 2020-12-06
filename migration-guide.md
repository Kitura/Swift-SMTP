# 5.0.0 Migration Guide

- The default port is now `587`.

- The `SMTP` struct is now initialized with a `TLSMode` enum instead of a `useTLS` Bool, allowing more configuration options:

```swift
/// TLSMode enum for what form of connection security to enforce.
    public enum TLSMode {
        /// Upgrades the connection to TLS if STARTLS command is received, else sends mail without security.
        case normal

        /// Send mail over plaintext and ignore STARTTLS commands and TLS options. Could throw an error if server requires TLS.
        case ignoreTLS

        /// Only send mail after an initial successful TLS connection. Connection will fail if a TLS connection cannot be established. The default port, 587, will likely need to be adjusted depending on your server.
        case requireTLS

        /// Expect a STARTTLS command from the server and require the connection is upgraded to TLS. Will throw if the server does not issue a STARTTLS command.
        case requireSTARTTLS
    }
```

# 4.0.0 Migration Guide

- `User` struct now nested in `Mail` struct to avoid namespace issues [(69)](https://github.com/Kitura/Swift-SMTP/pull/69). Create a user like so:

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

- Fixed a bug where the wrong `Attachment` was used an an alternative to text content when a `Mail` was initialized with multiple `Attachment`s [(67)](https://github.com/Kitura/Swift-SMTP/pull/67)

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
