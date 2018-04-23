# Swift-SMTP

![Swift-SMTP bird](https://github.com/IBM-Swift/Swift-SMTP/blob/master/Assets/swift-smtp-bird.png?raw=true)

Swift SMTP client.

![Build Status](https://travis-ci.org/IBM-Swift/Swift-SMTP.svg?branch=master)
![macOS](https://img.shields.io/badge/os-macOS-green.svg?style=flat)
![Linux](https://img.shields.io/badge/os-linux-green.svg?style=flat)
![Apache 2](https://img.shields.io/badge/license-Apache2-blue.svg?style=flat)

## Features

- Connect securely through SSL/TLS when needed
- Authenticate with CRAM-MD5, LOGIN, PLAIN, or XOAUTH2
- Send emails with local file, HTML, and raw data attachments
- Add custom headers
- [Documentation](https://ibm-swift.github.io/Swift-SMTP/)

## Swift Version

macOS & Linux: `Swift 4.0.3`

## Migration Guide

Version `4.0.0` & `3.0.0` bring breaking changes. See the quick migration guide [here](https://github.com/IBM-Swift/Swift-SMTP/blob/master/migration-guide.md).

## Usage

Initialize an `SMTP` instance:

```swift
import SwiftSMTP

let smtp = SMTP(
    hostname: "smtp.gmail.com",     // SMTP server address
    email: "user@gmail.com",        // username to login
    password: "password"            // password to login
)
```

### TLS

All parameters of `SMTP` struct:

```swift
public init(hostname: String,
            email: String,
            password: String,
            port: Int32 = 465,
            useTLS: Bool = true,
            tlsConfiguration: TLSConfiguration? = nil,
            authMethods: [AuthMethod] = [],
            domainName: String = "localhost",
            timeout: UInt = 10)
```

By default, the `SMTP` struct connects on port `465` and tries to connect using TLS. It also uses a `TLSConfiguration` that uses no backing certificates. Configure these to your needs. For more info on `TLSConfiguration`, view the [docs](https://ibm-swift.github.io/Swift-SMTP/Structs/TLSConfiguration.html).

### Send email

Create a `Mail` object and use your `SMTP` handle to send it. To set the sender and receiver of an email, use the `User` struct:

```swift
let drLight = User(name: "Dr. Light", email: "drlight@gmail.com")
let megaman = User(name: "Megaman", email: "megaman@gmail.com")

let mail = Mail(
    from: drLight,
    to: [megaman],
    subject: "Humans and robots living together in harmony and equality.",
    text: "That was my ultimate wish."
)

smtp.send(mail) { (error) in
    if let error = error {
        print(error)
    }
}
```

Add Cc and Bcc:

```swift
let roll = User(name: "Roll", email: "roll@gmail.com")
let zero = User(name: "Zero", email: "zero@gmail.com")

let mail = Mail(
    from: drLight,
    to: [megaman],
    cc: [roll],
    bcc: [zero],
    subject: "Robots should be used for the betterment of mankind.",
    text: "Any other use would be...unethical."
)

smtp.send(mail)
```

### Send attachments

Create an `Attachment`, attach it to your `Mail`, and send it through the `SMTP` handle. Here's an example of how you can send the three supported types of attachments--a local file, HTML, and raw data:

```swift
// Create a file `Attachment`
let fileAttachment = Attachment(
    filePath: "~/img.png",          
    // "CONTENT-ID" let's you reference this in another attachment
    additionalHeaders: ["CONTENT-ID": "img001"]
)

// Create an HTML `Attachment`
let htmlAttachment = Attachment(
    htmlContent: "<html>Here's an image: <img src=\"cid:img001\"/></html>",
    // To reference `fileAttachment`
    related: [fileAttachment]
)

// Create a data `Attachment`
let data = "{\"key\": \"hello world\"}".data(using: .utf8)!
let dataAttachment = Attachment(
    data: data,
    mime: "application/json",
    name: "file.json",
    // send as a standalone attachment
    inline: false   
)

// Create a `Mail` and include the `Attachment`s
let mail = Mail(
    from: from,
    to: [to],
    subject: "Check out this image and JSON file!",
    // The attachments we created earlier
    attachments: [htmlAttachment, dataAttachment]
)

// Send the mail
smtp.send(mail)

/* Each type of attachment has additional parameters for further customization */
```

### Send multiple mails

```swift
let mail1: Mail = //...
let mail2: Mail = //...

smtp.send([mail1, mail2],
    // This optional callback gets called after each `Mail` is sent.
    // `mail` is the attempted `Mail`, `error` is the error if one occured.
    progress: { (mail, error) in
    },

    // This optional callback gets called after all the mails have been sent.
    // `sent` is an array of the successfully sent `Mail`s.
    // `failed` is an array of (Mail, Error)--the failed `Mail`s and their corresponding errors.
    completion: { (sent, failed) in
    }
)
```

## Acknowledgements

`Swift-SMTP` was inspired by two other Swift SMTP clients, [Hedwig](https://github.com/onevcat/Hedwig) and [Perfect-SMTP](https://github.com/PerfectlySoft/Perfect-SMTP).

## License

Apache v2.0
