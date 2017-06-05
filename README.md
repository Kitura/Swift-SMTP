# Swift-SMTP

![Swift-SMTP bird](https://github.com/IBM-Swift/Swift-SMTP/blob/master/Assets/swift-smtp-bird.png)

Swift package for sending emails to an SMTP server.

[![Build Status - Master](https://travis-ci.com/IBM-Swift/Swift-SMTP.svg?token=prrUzhsjZyXD9LxyWxge&branch=master)](https://travis-ci.com/IBM-Swift/Swift-SMTP.svg?token=prrUzhsjZyXD9LxyWxge&branch=master)
![macOS](https://img.shields.io/badge/os-macOS-green.svg?style=flat)
![Linux](https://img.shields.io/badge/os-linux-green.svg?style=flat)
![Apache 2](https://img.shields.io/badge/license-Apache2-blue.svg?style=flat)

## Features

- Connect securely through SSL/TLS if available
- Authenticate with CRAM-MD5, LOGIN, PLAIN, or XOAUTH2
- Send emails with local file, HTML, and raw data attachments
- Add custom headers
- Asynchronous
- [Documentation](https://ibm-swift.github.io/Swift-SMTP/)

## Swift Version

macOS & Linux: `Swift 3.1.1`

## Usage

Use the `SMTP` struct as a handle to your SMTP server. If your server requires a SSL/TLS connection, you can specify an `SSL` config and include it in your `SMTP` handle:

```swift
import SwiftSMTP

// Create an `SSL` config
#if os(Linux)
    let certificateFilePath = "~/cert.pem"
    let keyFilePath = "~/key.pem"
    let ssl = SSL(withCACertificateDirectory: nil, usingCertificateFile: certificateFilePath, withKeyFile: keyFilePath)
#else
    let chainFilePath = "~/cert.pfx"
    let certPassword = "password"
    let ssl = SSL(withChainFilePath: chainFilePath, withPassword: certPassword)
#endif
/* Additional methods available to create an `SSL` config */

// Create your `SMTP` handle
let smtp = SMTP(hostname: "smtp.gmail.com",     // SMTP server address
                user: "user@gmail.com",         // username to login 
                password: "password",           // password to login
                ssl: ssl)                       // if your SMTP server requires SSL/TLS
                
/* Additional parameters available to further customize your `SMTP` handle */
```

### Send email

Create a `Mail` object and use your `smtp` handle to send it. To set the sender and receiver of an email, use the `User` struct:

```swift
let drLight = User(name: "Dr. Light", email: "drlight@gmail.com")
let megaman = User(name: "Megaman", email: "megaman@gmail.com")

let mail = Mail(from: drLight,
                to: [megaman],
                subject: "Humans and robots living together in harmony and equality.",
                text: "That was my ultimate wish.")

smtp.send(mail) { (err) in
    if let err = err {
        print(err)
    }
}
```

Add Cc and Bcc:

```swift
let roll = User(name: "Roll", email: "roll@gmail.com")
let zero = User(name: "Zero", email: "zero@gmail.com")

let mail = Mail(from: drLight,
                to: [megaman],
                cc: [roll],
                bcc: [zero],
                subject: "Robots should be used for the betterment of mankind.",
                text: "Any other use would be...unethical.")

smtp.send(mail)
```

### Send attachments

Create an `Attachment`, attach it to your `Mail`, and send it through the `smtp` handle. Here's an example of how you can send the three supported types of attachments--a local file, HTML, and raw data:

```swift
// Create a file `Attachment`
let fileAttachment = Attachment(filePath: "~/img.png",
                                // You can add "CONTENT-ID" to reference this in another attachment
                                additionalHeaders: ["CONTENT-ID": "img001"])

// Create an HTML `Attachment`
let htmlAttachment = Attachment(htmlContent: "<html>Here's an image: <img src=\"cid:img001\"/></html>", 
                                related: [fileAttachment]) // to reference `fileAttachment`

// Create a data `Attachment`
let data = "{\"key\": \"hello world\"}".data(using: .utf8)!
let dataAttachment = Attachment(data: data, 
                                mime: "application/json", 
                                name: "file.json",
                                inline: false) // send as a standalone attachment

// Create a `Mail` and include the `Attachment`s
let mail = Mail(from: from, 
                to: [to], 
                subject: "Check out this image and JSON file!", 
                attachments: [htmlAttachment, dataAttachment]) // attachments we created earlier

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

`Swift-SMTP` was inspired by [Hedwig](https://github.com/onevcat/Hedwig) and [Perfect-SMTP](https://github.com/PerfectlySoft/Perfect-SMTP), two Swift packages that can also be used to send emails to an SMTP server.

## License

Apache 2.0
