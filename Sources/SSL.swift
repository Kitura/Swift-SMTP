/**
 * Copyright IBM Corporation 2017
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import Foundation

/// Configuration to connect securely through SSL/TLS.
/// https://github.com/IBM-Swift/BlueSSLService
public struct SSL {
    let config: Config
    
    enum Config {
        #if os(Linux)
            case caCertificatePath(ca: String?, cert: String?, key: String?, selfSigned: Bool, cipher: String?)
            case caCertificateDirectory(ca: String?, cert: String?, key: String?, selfSigned: Bool, cipher: String?)
            case pemCertificate(pem: String, selfSigned: Bool, cipher: String?)
            case cipherSuite(cipher: String?)
        #endif
            case chainFile(chainFilePath: String?, password: String?, selfSigned: Bool, cipherSuite: String?)
    }
    
    #if os(Linux)
    /// Initialize a configuration using a `CA Certificate` file.
    ///
    /// - Parameters:
    ///		- caCertificateFilePath:	Path to the PEM formatted CA certificate file.
    ///		- certificateFilePath:		Path to the PEM formatted certificate file.
    ///		- keyFilePath:				Path to the PEM formatted key file. If nil, `certificateFilePath` will be used.
    ///		- selfSigned:				True if certs are `self-signed`, false otherwise. Defaults to true.
    ///		- cipherSuite:				Optional String containing the cipher suite to use.
    public init(withCACertificateFilePath caCertificateFilePath: String?, usingCertificateFile certificateFilePath: String?, withKeyFile keyFilePath: String? = nil, usingSelfSignedCerts selfSigned: Bool = true, cipherSuite: String? = nil) {
        config = .caCertificatePath(ca: caCertificateFilePath, cert: certificateFilePath, key: keyFilePath, selfSigned: selfSigned, cipher: cipherSuite)
    }
    
    /// Initialize a configuration using a `CA Certificate` directory.
    ///
    ///	*Note:* `caCertificateDirPath` - All certificates in the specified directory **must** be hashed using the `OpenSSL Certificate Tool`.
    ///
    /// - Parameters:
    ///		- caCertificateDirPath:		Path to a directory containing CA certificates. *(see note above)*
    ///		- certificateFilePath:		Path to the PEM formatted certificate file. If nil, `certificateFilePath` will be used.
    ///		- keyFilePath:				Path to the PEM formatted key file (optional). If nil, `certificateFilePath` is used.
    ///		- selfSigned:				True if certs are `self-signed`, false otherwise. Defaults to true.
    ///		- cipherSuite:				Optional String containing the cipher suite to use.
    public init(withCACertificateDirectory caCertificateDirPath: String?, usingCertificateFile certificateFilePath: String?, withKeyFile keyFilePath: String? = nil, usingSelfSignedCerts selfSigned: Bool = true, cipherSuite: String? = nil) {
        config = .caCertificateDirectory(ca: caCertificateDirPath, cert: certificateFilePath, key: keyFilePath, selfSigned: selfSigned, cipher: cipherSuite)
    }

    /// Initialize a configuration using a `PEM formatted certificate in String form`.
    ///
    /// - Parameters:
    ///		- certificateString:		PEM formatted certificate in String form.
    ///		- selfSigned:				True if certs are `self-signed`, false otherwise. Defaults to true.
    ///		- cipherSuite:				Optional String containing the cipher suite to use.
    public init(withPEMCertificateString certificateString: String, usingSelfSignedCerts selfSigned: Bool = true, cipherSuite: String? = nil) {
        config = .pemCertificate(pem: certificateString, selfSigned: selfSigned, cipher: cipherSuite)
    }
    
    /// Initialize a configuration with no backing certificates.
    ///
    /// - Parameters:
    ///		- cipherSuite:				Optional String containing the cipher suite to use.
    public init(withCipherSuite cipherSuite: String?) {
        config = .cipherSuite(cipher: cipherSuite)
    }
    #endif
    
    /// Initialize a configuration using a `Certificate Chain File`.
    ///
    /// *Note:* If using a certificate chain file, the certificates must be in PEM format and must be sorted starting with the subject's certificate (actual client or server certificate), followed by intermediate CA certificates if applicable, and ending at the highest level (root) CA.
    ///
    /// - Parameters:
    ///		- chainFilePath:			Path to the certificate chain file (optional). *(see note above)*
    ///		- password:					Password for the chain file (optional).
    ///		- selfSigned:				True if certs are `self-signed`, false otherwise. Defaults to true.
    ///		- cipherSuite:				Optional String containing the cipher suite to use.
    public init(withChainFilePath chainFilePath: String? = nil, withPassword password: String? = nil, usingSelfSignedCerts selfSigned: Bool = true, cipherSuite: String? = nil) {
        config = .chainFile(chainFilePath: chainFilePath, password: password, selfSigned: selfSigned, cipherSuite: cipherSuite)
    }
}
