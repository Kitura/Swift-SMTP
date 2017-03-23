# Kitura-SMTP

Swift package for sending emails to an SMTP server.

## Usage

Use the `SMTP` struct as a handle to an SMTP server:

```swift
import KituraSMTP

let smtp = SMTP(hostname: "smtp.gmail.com",             // SMTP server address
                user: "user@gmail.com",                 // username to login 
                password: "password",                   // password to login
                chainFilePath: "~/cert.pfx" ,           // local path to certificate chain file
                                                        // (required if your server uses an SSL/TLS (STARTTLS) port)
                chainFilePassword: "password",          // password to certificate chain file
                selfSignedCerts: true)                  // whether certificate is self signed
```

### Send an email

Create a simple `Mail` object and use your `smtp` handle to send it. To set the sender and receiver of an email, use the `User` struct:

```swift
let from = User(name: "Dr. Light", email: "drlight@gmail.com")
let to = User(name: "Megaman", email: "megaman@gmail.com")

let mail = Mail(from: from,
                to: [to],
                subject: "Humans and robots living together in harmony and equality.",
                text: "That was my ultimate wish.")

smtp.send(mail) { (err) in
            if let err = err {
              print(err)
            }
        }
```
