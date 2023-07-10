# SSL Options

Faraday supports a number of SSL options, which can be provided while initializing the connection.

| Option             | Type                                   | Default | Description                                                                                                                                      |
|--------------------|----------------------------------------|---------|--------------------------------------------------------------------------------------------------------------------------------------------------|
| `:verify`          | Boolean                                | true    | Verify SSL certificate. Defaults to `true`.                                                                                                      |
| `:verify_hostname` | Boolean                                | true    | Verify SSL certificate hostname. Defaults to `true`.                                                                                             |
| `:ca_file`         | String                                 | nil     | Path to a CA file in PEM format.                                                                                                                 |
| `:ca_path`         | String                                 | nil     | Path to a CA directory.                                                                                                                          |
| `:verify_mode`     | Integer                                | nil     | Any `OpenSSL::SSL::` constant (see [SSL docs](https://ruby-doc.org/stdlib-2.5.1/libdoc/openssl/rdoc/OpenSSL/SSL.html)).                          |
| `:cert_store`      | OpenSSL::X509::Store                   | nil     | OpenSSL certificate store.                                                                                                                       |
| `:client_cert`     | OpenSSL::X509::Certificate             | nil     | Client certificate.                                                                                                                              |
| `:client_key`      | OpenSSL::PKey::RSA, OpenSSL::PKey::DSA | nil     | Client private key.                                                                                                                              |
| `:certificate`     | OpenSSL::X509::Certificate             | nil     | Certificate (Excon only).                                                                                                                        |
| `:private_key`     | OpenSSL::PKey::RSA                     | nil     | Private key (Excon only).                                                                                                                        |
| `:verify_depth`    | Integer                                | nil     | Maximum depth for the certificate chain verification.                                                                                            |
| `:version`         | Integer                                | nil     | SSL version (see [SSL docs](https://ruby-doc.org/stdlib-2.5.1/libdoc/openssl/rdoc/OpenSSL/SSL/SSLContext.html#method-i-ssl_version-3D)).         |
| `:min_version`     | Integer                                | nil     | Minimum SSL version (see [SSL docs](https://ruby-doc.org/stdlib-2.5.1/libdoc/openssl/rdoc/OpenSSL/SSL/SSLContext.html#method-i-min_version-3D)). |
| `:max_version`     | Integer                                | nil     | Maximum SSL version (see [SSL docs](https://ruby-doc.org/stdlib-2.5.1/libdoc/openssl/rdoc/OpenSSL/SSL/SSLContext.html#method-i-max_version-3D)). |

## Example

```ruby
ssl_options = {
  ca_file: '/path/to/ca_file',
  min_version: :TLS1_2
}

conn = Faraday.new(ssl: options) do |faraday|
  # ...
end
```
