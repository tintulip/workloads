package main

deny[msg] {
  env := opa.runtime()["env"]
  msg := json.marshal(env)
}
