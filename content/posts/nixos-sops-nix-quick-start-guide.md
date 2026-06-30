+++
title = "Sops-nix Quick Start Guide"
date = "2025-10-17"
updated = "2025-10-17"
description = "A quick guide to managing encrypted secrets in NixOS using sops-nix."
tags = ["NixOS"]
+++

## 📘 Introduction

This article provides a simple guide to using [sops-nix](https://github.com/Mic92/sops-nix).

It’s written for those who “don’t fully understand the official documentation but still want to use sops-nix to encrypt secrets” (like me when I first started 😅).
The goal is to use it in the simplest, most intuitive way. For advanced usage, please refer to the official documentation.

> ⚠️ **Note!!!**
> `sops-nix` can only be used for **file-level encryption**, not for encrypting single values, strings, or booleans directly.
> In short, it is suitable for configuration options that **expect a file path**.

For example:

- 🔑 Wakapi’s [passwordSaltFile](https://mynixos.com/nixpkgs/option/services.wakapi.passwordSaltFile)
- 🔒 Restic’s [environmentFile](https://mynixos.com/nixpkgs/option/services.restic.backups.%3Cname%3E.environmentFile), [passwordFile](https://mynixos.com/nixpkgs/option/services.restic.backups.%3Cname%3E.passwordFile), and [repositoryFile](https://mynixos.com/nixpkgs/option/services.restic.backups.%3Cname%3E.repositoryFile)

During the system build, **sops-nix uses Nix to pass encrypted files**, and after boot, it automatically decrypts them into `/run/secrets` (a temporary directory) for services to read.
It’s generally used for environment variables, passwords, and other sensitive data—making them safe to store in Git repositories while maintaining system security.

💡 If you’re looking for a way to **encrypt individual numbers, strings, booleans, or even inline Nix configurations**, check out [my other article](https://blog.0pt.icu/posts/nixos-using-sops-to-encrypt-nix-values/) which introduces a clever method using sops.

---

## 🧩 Importing the `sops-nix` Module

As shown in the official guide, you’ll need to add the `sops-nix` module to your flake configuration.
Add it to `inputs`, and import it in `modules` as `sops-nix.nixosModules.sops`.

```nix
{
  inputs.sops-nix.url = "github:Mic92/sops-nix";
  inputs.sops-nix.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, sops-nix }: {
    nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        sops-nix.nixosModules.sops
      ];
    };
  };
}
```

---

## 🔑 Generate Your Personal `age` Key

> The official docs recommend GPG, but I personally prefer using the pure `age` format.
> The local key is randomly generated, while the server key is usually derived via `ssh-to-age`.

```bash
nix-shell -p rage --run "rage-keygen -o ~/.config/sops/age/keys.txt"
```

Generated `keys.txt` looks like this:

```text
# created: 2024-12-17T19:16:19+08:00
# public key: age162j8mn60ty8dxk8cvww2lckteyeemdnd64trekpv35qcuw2pqcfqwtnm9q
AGE-SECRET-KEY-16KVMY0VXWDSECKQTR23AZYU874SM0HSMV6EPZZATG9UCXU6A233SVKDHPD
```

- ⚠️ **Keep this file safe!**
- `AGE-SECRET-KEY-xxxx` → your private key
- `public key` → your public key

---

## 🖥️ Generate an `age` Key for the NixOS Server (optional)

If your NixOS configuration repository includes multiple hosts (e.g., managed via flakes), it’s best to **generate a separate public key for each host**.

You can derive it from the server’s SSH host key:

```bash
ssh root@<server-ip>
nix-shell -p ssh-to-age --run 'cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age'
```

This will return something like:

```
age1l64vm6knlk0ewgdnvxdwrzuhfjcakwpj533gw8lgays706q59d0quuys52
```

---

## ⚙️ Add a `.sops.yaml` Configuration File

At the root of your NixOS configuration repository, create a file named `.sops.yaml`:

```yaml
# .sops.yaml
keys:
  - &admin_alice age162j8mn60ty8dxk8cvww2lckteyeemdnd64trekpv35qcuw2pqcfqwtnm9q
  - &server_bob age1l64vm6knlk0ewgdnvxdwrzuhfjcakwpj533gw8lgays706q59d0quuys52

creation_rules:
  - path_regex: secrets/.*
    key_groups:
      - age:
          - *admin_alice
          - *server_bob
```

🗝️ Explanation:

- `keys`: stores public keys of devices/users
  - `&<name>` defines an alias
  - I usually name local keys as `admin_...` and server keys as `server_...`

- `creation_rules`: defines encryption rules
  - `path_regex` uses regex to match which files to encrypt
  - `key_groups.age` defines which keys can decrypt the file

So in the example above, files under `secrets/` can be encrypted/decrypted using either `admin_alice` (local key) or `server_bob` (server key).

> 💡 Defining keys doesn’t encrypt anything yet — encryption only happens when you run the `sops` command.

If a file doesn’t match the rules, it can’t be encrypted.

In practice:

- The **local public key** allows you to decrypt files on your local machine.
- The **server public key** allows the server to decrypt them after deployment.

If you only include the local key, the server won’t be able to decrypt.
If you only include the server key, you’ll need to bring its private key locally — which isn’t convenient.

You can compare this with the official example:

```yaml
keys:
  - &admin_alice 2504791468b153b8a3963cc97ba53d1919c5dfd4
  - &admin_bob age12zlz6lvcdk6eqaewfylg35w0syh58sm7gh53q5vvn7hd7c6nngyseftjxl
  - &server_azmidi 0fd60c8c3b664aceb1796ce02b318df330331003
  - &server_nosaxa age1rgffpespcyjn0d8jglk7km9kfrfhdyev6camd3rck6pn8y47ze4sug23v3
creation_rules:
  - path_regex: secrets/[^/]+\.(yaml|json|env|ini)$
    key_groups:
      - pgp:
          - *admin_alice
          - *server_azmidi
        age:
          - *admin_bob
          - *server_nosaxa
  - path_regex: secrets/azmidi/[^/]+\.(yaml|json|env|ini)$
    key_groups:
      - pgp:
          - *admin_alice
          - *server_azmidi
        age:
          - *admin_bob
```

The first rule allows both local and server PGP + age keys to encrypt top-level files in `secrets/` with extensions `.yaml|.json|.env|.ini`.
The second rule applies similar logic for files inside `secrets/azmidi/`.

If this looks too complex, just use `secrets/.*` for simplicity. You can refine it later.

---

## 🪄 Create Your First Encrypted File

Let’s use the simpler `.sops.yaml` rule:

```yaml
keys:
  - &admin_alice age162j8mn60ty8dxk8cvww2lckteyeemdnd64trekpv35qcuw2pqcfqwtnm9q
  - &server_bob age1l64vm6knlk0ewgdnvxdwrzuhfjcakwpj533gw8lgays706q59d0quuys52
creation_rules:
  - path_regex: secrets/*
    key_groups:
      - age:
          - *admin_alice
          - *server_bob
```

Now, create an encrypted file:

```bash
nix-shell -p sops --run "sops secrets/your-first-secrets"
```

If your default editor (`$EDITOR`) isn’t set, you can define it temporarily:

```bash
EDITOR=nano nix-shell -p sops --run "sops secrets/your-first-secrets"
```

Then delete the default text and add your secret:

```
WAKAPI_PASSWORD_SALT=adgjajnnaghauhlaksfjdk
```

Save and exit. You’ll now have an encrypted file like this:

```json
{
  "data": "ENC[AES256_GCM,data:N/5R/bObiFfARZ5ud2zPiWqF9FhssA8=,iv:yZnocnSwlrz/EkGNdbw88VqsbzhXb/2V9ffwc8TLma0=,tag:nYsq2aAxMKpsBSEutvngRw==,type:str]",
  "sops": {
    "age": [
      {
        "recipient": "age162j8mn60ty8dxk8cvww2lckteyeemdnd64trekpv35qcuw2pqcfqwtnm9q",
        "enc": "-----BEGIN AGE ENCRYPTED FILE-----\nYWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBzNUU2T2tLcjMxQWV5UzFj\nRm9CbnV3K25UMktGaFB4aHoxSlBkREx2bzAwCnZybVV6aHJFalBkY3hZbDFKdndl\nT0FFMEZBMnN4ZTBlbGJ0ZzFGSHJEV1kKLS0tIEg5VnAwZ1VWS3MvcUw3SEFKOG81\nbXhRb3JmNGt0UVIzT1l4QXUrY0d6NzQK+Hjrzb68ZoWqfd4nKpJ2V4MOL1v66R8q\nxqfLgGUY3+K5CZ9sNGtsuOo3U8emsrzB8daMw8GZALVU17s2ehfbfA==\n-----END AGE ENCRYPTED FILE-----\n"
      }
    ],
    "lastmodified": "2024-11-17T11:03:35Z",
    "mac": "ENC[AES256_GCM,data:jjRRXb9XorhcvHHdJGOTfOAHm/xm/GadoF9i28KEc6YfVhEN41CcrqGmHsfq6hqpPzNlrXa6Miu9/Ppbx/hPgD4joc3/q7llVgRZ7zeJOHdbHs9WLjWN82YoM8uPpN9C2nGVWVO+pOcnMGNw/32loyxK0JClv22rBXCjmcuenyw=,iv:0xX9iqJHJPIasBkhdbBxfdEz5OX01njIobcWgAZT89A=,tag:n47PA0iDPkykRrhKRRiV1g==,type:str]",
    "version": "3.11.0"
  }
}
```

Each `recipient` corresponds to one key that can decrypt this file.
💡 Only users/machines holding those private keys can decrypt it.

---

## ✏️ Modify an Existing Secret

Simply run again:

```bash
nix-shell -p sops --run "sops secrets/your-first-secrets"
```

---

## 🧠 Use the Secret in NixOS

Example using [Wakapi](https://mynixos.com/nixpkgs/options/services.wakapi):

```nix
{config, ...}:{
  sops.secrets.secret-name = {
    mode = "0400";
    owner = "wakapi";
    group = "wakapi";
    format = "binary";
    sopsFile = ../../../secrets/your-first-secrets;
  };
  services = {
    wakapi = {
      enable = true;
      passwordSaltFile = config.sops.secrets.secret-name.path;
    };
  };
}
```

### Explanation

- `secret-name` → arbitrary name
- `mode` → permission of decrypted file
- `owner`, `group` → file owner/group (default: root)
- `format` → file format (`YAML`, `JSON`, `INI`, `dotenv`, `binary`)
  - `binary` works well for plain text and general secrets

- `sopsFile` → relative path to encrypted source file

Then, reference it as:

```nix
passwordSaltFile = config.sops.secrets.secret-name.path;
```

✅ After deployment, verify via:

```bash
sudo cat /run/secrets/secret-name
```

---

## 👑 Encrypting Root Password Hash

This one is a bit special. A working example:

```nix
{config, ...}: {
  sops.secrets.root-hashedPassword = {
    format = "binary";
    sopsFile = path/to/hashedPassword;
    neededForUsers = true;
  };
  users = {
    mutableUsers = false;
    users.root = {
      hashedPasswordFile = config.sops.secrets.root-hashedPassword.path;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3Nz..."
      ];
    };
  };
}
```

---

## 🗂️ Example Personal Project Structure

Example structure for multi-host management:

```
nix-config
├── .sops.yaml
├── flake.lock
├── flake.nix
├── Justfile
├── machines
│   ├── homelab1
│   │   ├── default.nix
│   │   ├── disko.nix
│   │   ├── hardware.nix
│   │   ├── modules
│   │   │   ├── powersave.nix
│   │   │   └── wakapi.nix
│   │   ├── secrets
│   │   │   ├── wakapi-passwd-salt
│   │   │   └── hashedPassword
│   │   └── user.nix
│   └── homelab2
│       ├── default.nix
│       ├── disko.nix
│       ├── hardware.nix
│       ├── modules
│       │   ├── powersave.nix
│       │   └── wakapi.nix
│       ├── secrets
│       │   ├── wakapi-passwd-salt
│       │   └── hashedPassword
│       └── user.nix
├── modules
│   ├── options
│   ├── services
│   └── system
└── README.md
```

### Example `.sops.yaml`:

```yaml
keys:
  - &admin_alice age162j8mn60ty8dxk8cvww2lckteyeemdnd64trekpv35qcuw2pqcfqwtnm9q
  - &server_homelab1 age12zlz6lvcdk6eqaewfylg35w0syh58sm7gh53q5vvn7hd7c6nngyseftjxl
  - &server_homelab2 age18jtffqax5v0t6ehh4ypaefl4mfhcrhn6ek3p80mhfp9psx6pd35qew2ww3
creation_rules:
  - path_regex: machines/homelab1/secrets/.*
    key_groups:
      - age:
          - *admin_alice
          - *server_homelab1
  - path_regex: machines/homelab2/secrets/.*
    key_groups:
      - age:
          - *admin_alice
          - *server_homelab2
```

Then add encrypted files:

```bash
sops machines/homelab1/secrets/hashedPassword
sops machines/homelab1/secrets/wakapi-passwd-salt
# Other secrets...
```

This way, within `machines/<machine>/modules/`, you can reference secrets as:

```nix
sopsFile = ../secrets/wakapi-passwd-salt;
```

I also recommend prefixing secret names with the machine name, e.g.:

```nix
  sops.secrets.homelab1-wakapi-passwd-salt = {
    mode = "0400";
    owner = "wakapi";
    group = "wakapi";
    format = "binary";
    sopsFile = ../secrets/wakapi-passwd-salt;
  };
```

---

## ✅ Summary

By now, you should know how to:

1. 🧬 Generate `age` keys for personal and server use
2. 🧾 Write a simple `.sops.yaml` configuration
3. 🔐 Use `sops` to encrypt files
4. ⚙️ Reference secrets securely in NixOS
5. 👑 Encrypt root passwords and handle multi-host setups

> From now on, your NixOS configuration repo can be **safely pushed to GitHub** —
> no more worries about secrets leakage. 🎉

If you want to see more practical examples, please visit [my Nix configuration](https://github.com/atp-gh/atplab).
