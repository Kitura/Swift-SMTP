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
import SSLService

/// Configuration for connecting with TLS. For more info, see https://github.com/IBM-Swift/BlueSSLService.
public struct TLSConfiguration {
    private let configuration: SSLService.Configuration

    ///
    /// Initialize a configuration with no backing certificates.
    ///
    /// - Parameters:
    ///		- cipherSuite:					Optional String containing the cipher suite to use.
    ///		- clientAllowsSelfSignedCertificates:
    ///										`true` to accept self-signed certificates from a server. `false` otherwise.
    public init(withCipherSuite cipherSuite: String? = nil,
                clientAllowsSelfSignedCertificates: Bool = false) {
        configuration = SSLService.Configuration(
            withCipherSuite: cipherSuite,
            clientAllowsSelfSignedCertificates: clientAllowsSelfSignedCertificates
        )
    }

    ///
    /// Initialize a configuration using a `CA Certificate` file.
    ///
    /// - Parameters:
    ///		- caCertificateFilePath:	Path to the PEM formatted CA certificate file.
    ///		- certificateFilePath:		Path to the PEM formatted certificate file.
    ///		- keyFilePath:				Path to the PEM formatted key file. If nil, `certificateFilePath` will be used.
    ///		- selfSigned:				True if certs are `self-signed`, false otherwise. Defaults to true.
    ///		- cipherSuite:				Optional String containing the cipher suite to use.
    public init(withCACertificateFilePath caCertificateFilePath: String?,
                usingCertificateFile certificateFilePath: String?,
                withKeyFile keyFilePath: String? = nil,
                usingSelfSignedCerts selfSigned: Bool = true,
                cipherSuite: String? = nil) {
        configuration = SSLService.Configuration(
            withCACertificateFilePath: caCertificateFilePath,
            usingCertificateFile: certificateFilePath,
            withKeyFile: keyFilePath,
            usingSelfSignedCerts: selfSigned,
            cipherSuite: cipherSuite
        )
    }

    ///
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
    public init(withCACertificateDirectory caCertificateDirPath: String?,
                usingCertificateFile certificateFilePath: String?,
                withKeyFile keyFilePath: String? = nil,
                usingSelfSignedCerts selfSigned: Bool = true,
                cipherSuite: String? = nil) {
        configuration = SSLService.Configuration(
            withCACertificateDirectory: caCertificateDirPath,
            usingCertificateFile: certificateFilePath,
            withKeyFile: keyFilePath,
            usingSelfSignedCerts: selfSigned,
            cipherSuite: cipherSuite
        )
    }

    ///
    /// Initialize a configuration using a `Certificate Chain File`.
    ///
    /// *Note:* If using a certificate chain file, the certificates must be in PEM format and must be sorted starting with the subject's certificate (actual client or server certificate), followed by intermediate CA certificates if applicable, and ending at the highest level (root) CA.
    ///
    /// - Parameters:
    ///		- chainFilePath:                        Path to the certificate chain file (optional). *(see note above)*
    ///		- password:                             Password for the chain file (optional). If using self-signed certs, a password is required.
    ///		- selfSigned:                           True if certs are `self-signed`, false otherwise. Defaults to true.
    ///     - clientAllowsSelfSignedCertificates:   True if, as a client, connections to self-signed servers are allowed
    ///		- cipherSuite:                          Optional String containing the cipher suite to use.
    public init(withChainFilePath chainFilePath: String?,
                withPassword password: String? = nil,
                usingSelfSignedCerts selfSigned: Bool = true,
                clientAllowsSelfSignedCertificates: Bool = false,
                cipherSuite: String? = nil) {
        configuration = SSLService.Configuration(
            withChainFilePath: chainFilePath,
            withPassword: password,
            usingSelfSignedCerts: selfSigned,
            clientAllowsSelfSignedCertificates:
            clientAllowsSelfSignedCertificates,
            cipherSuite: cipherSuite
        )
    }

    #if os(Linux)
    ///
    /// Initialize a configuration using a `PEM formatted certificate in String form`.
    ///
    /// - Parameters:
    ///		- certificateString:		PEM formatted certificate in String form.
    ///		- selfSigned:				True if certs are `self-signed`, false otherwise. Defaults to true.
    ///		- cipherSuite:				Optional String containing the cipher suite to use.
    public init(withPEMCertificateString certificateString: String,
                usingSelfSignedCerts selfSigned: Bool = true,
                cipherSuite: String? = nil) {
        configuration = SSLService.Configuration(
            withPEMCertificateString: certificateString,
            usingSelfSignedCerts: selfSigned,
            cipherSuite: cipherSuite
        )
    }
    #endif

    func makeSSLService() throws -> SSLService? {
        return try SSLService(usingConfiguration: configuration)
    }
}
