# Vault Token List

## Overview

vtl works with vault and consul, allowing you to output a list of all the active vault tokens that are stored in your consul backend.

## Setup

1. Set a vault root token in your environment:
  - `export VAULT_TOKEN=<root token here>`
2. Configure the address and port of your consul and vault servers on line 10 and 11 of vtl.rb, respectively.  e.g.:

```
consul_addr = 'http://consul.domain.tld:8500'
vault_addr = 'http://vault.domain.tld:8200'
```
