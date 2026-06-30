+++
title = "Using SOPS to Encrypt Nix Values"
date = "2025-10-17"
updated = "2025-10-17"
description = "How to encrypt sensitive values in your Nix code using SOPS."
tags = ["NixOS"]
+++

## 🧩 Introduction

In some NixOS configurations, we may need to store sensitive information, such as:

- VPS IPv4 / IPv6 addresses;
- Certain private configuration values;
- Or internal parameters that should not be exposed publicly.

After studying [sops-nix](https://github.com/Mic92/sops-nix), I realized that **sops-nix only supports file-level encryption** — it cannot encrypt individual Nix values.

These values are often needed **during the system build phase**, but `sops-nix` decrypts only **after the system has booted**, meaning that during the build phase, the encrypted files remain ciphertext.

This means that sensitive values still **appear in plaintext in `/nix/store`**. While files encrypted by `sops-nix` remain protected at that stage, any Nix expression containing secrets will be fully visible.

So, from a security standpoint, 👉 **the following approach is merely a workaround**.
If `sops-nix` can be used, it’s always preferable — as it’s more secure by design.

---

## Concept

This approach was originally suggested by [@yonzilch](https://github.com/yonzilch) — much appreciated 🙏.

The **core idea** is:

> Store sensitive values as individual `.nix` files, then encrypt those files using `sops`.

### ✳️ Example: Define an SSH Port

Create a file named `forgejo-ssh-port.nix`:

```nix
223
```

Then reference it inside `forgejo.nix`:

```nix
services.forgejo = {
  # ...
  settings = {
    server = {
      # ...
      SSH_PORT = import path/to/forgejo-ssh-port.nix;
      # ...
    };
  };
};
```

---

### ✳️ Example: Define a URL

Create `headscale-server-url.nix`:

```nix
"https://headscale.example.com"
```

Then reference it in `headscale.nix`:

```nix
services = {
  headscale = {
    # ...
    settings = {
      # ...
      server_url = import path/to/headscale-server-url.nix;
    };
  };
};
```

---

### ✳️ Example: Define a Complex Structure

Create `headscale-dns-settings.nix`:

```nix
{
  nameservers.global = [
    "127.0.0.1"
    "::1"
  ];
  magic_dns = true;
  base_domain = test;
}
```

Then reference it in `headscale.nix`:

```nix
services = {
  headscale = {
    # ...
    settings = {
      dns = import path/to/headscale-dns-settings.nix;
      # ...
    };
  };
};
```

---

📘 **To summarize:**

- Any Nix value — string, number, list, or attribute set — can exist as a separate `.nix` file;
- Decrypt before deployment, re-encrypt afterward;
- Use `sops` for all encryption/decryption operations;
- Encrypted files can be safely committed to your Git repository.

To simplify this process, you can automate encryption/decryption and deployment with a script or a `just` recipe.

---

## ⚙️ Installing sops

Install manually:

```bash
nix-shell -p sops
```

---

## 🧾 Create a `.sops.yaml` Configuration

If you haven’t yet read my other article 👉 [Quickstart Guide to sops-nix](https://blog.0pt.icu/posts/nixos-sops-nix-quick-start-guide/),
I highly recommend doing so first — it explains `.sops.yaml` in detail.

At your repository root, create `.sops.yaml`:

```yaml
keys:
  - &admin_alice age162j8mn60ty8dxk8cvww2lckteyeemdnd64trekpv35qcuw2pqcfqwtnm9q
creation_rules:
  - path_regex: values/.*
    key_groups:
      - age:
          - *admin_alice
```

This configuration specifies that:

- All files under the `values/` directory can be encrypted/decrypted by `sops`;
- The `admin_alice` key is used (only locally — you don’t need your server’s public key).

---

## 📝 Create Plaintext Nix Values

Create plaintext sensitive value files under `values/`:

```bash
vim values/forgejo-ssh-port.nix
vim values/headscale-server-url.nix
vim values/headscale-dns-settings.nix
# ...
```

---

## 🔒 Encrypt

Run:

```bash
ls values/* | xargs -n 1 sops encrypt -i
```

---

## 🧱 (Optional) Commit to Git

Once confirmed, you can safely commit the encrypted files:

```bash
git add values/
git commit -m "add some values"
```

---

## 🔓 Decrypt Before Deployment

```bash
ls values/* | xargs -n 1 sops decrypt -i
```

---

## 🚀 Deploy the System

Normal deployment command:

```bash
nixos-rebuild switch ...
```

---

## 🔐 Re-encrypt After Deployment

```bash
ls values/* | xargs -n 1 sops encrypt -i
```

---

## 💾 (Optional) Commit Again

If the values are correct:

```bash
git add values/
git commit -m "add some values"
```

---

## 🛠️ Modify or Add Plaintext Values

First, decrypt the encrypted files:

```bash
ls values/* | xargs -n 1 sops decrypt -i
```

Then edit or add new plaintext `.nix` files.
Afterward, re-encrypt them:

```bash
ls values/* | xargs -n 1 sops encrypt -i
```

---

## ⚡ Automating the Workflow with Justfile

You can easily wrap the above steps into scripts or automation tools.
Here we’ll use [just](https://github.com/casey/just).

Install `just`:

```bash
nix-shell -p just
```

At your repo root, create a `justfile`:

```justfile
set shell := ["bash", "-c"]

encrypt:
  ls values/* | xargs -n 1 sops encrypt -i

decrypt:
  ls values/* | xargs -n 1 sops decrypt -i

deploy:
  ls values/* | xargs -n 1 sops decrypt -i ; git add . ; nixos-rebuild switch ... ; ls values/* | xargs -n 1 sops encrypt -i
```

Usage:

```bash
just encrypt  # Encrypt all
just decrypt  # Decrypt all
just deploy   # Auto decrypt + deploy + re-encrypt
```

---

## ⚠️ Limitations

1. 🧩 **Non-native solution** — a workaround that requires extra manual steps;
2. 🧠 **Prone to mistakes** — you might accidentally commit plaintext secrets to Git;
3. 🔄 **Frequent ciphertext changes** — every time you re-encrypt, ciphertext differs, cluttering Git history.
   You can avoid this by discarding those diffs with:

   ```bash
   git reset --hard HEAD~1
   ```

---

## 🧱 Example Project Structure

Here’s my personal layout for reference:

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
│   │   │   ├── forgejo.nix
│   │   │   └── headscale.nix
│   │   ├── values
│   │   │   ├── forgejo-ssh-port.nix
│   │   │   ├── headscale-dns-settings.nix
│   │   │   └── headscale-server-url.nix
│   │   └── user.nix
│   └── homelab2
│       ├── default.nix
│       ├── disko.nix
│       ├── hardware.nix
│       ├── modules
│       │   ├── forgejo.nix
│       │   └── headscale.nix
│       ├── values
│       │   ├── forgejo-ssh-port.nix
│       │   ├── headscale-dns-settings.nix
│       │   └── headscale-server-url.nix
│       └── user.nix
├── modules
│   ├── options
│   ├── services
│   └── system
└── README.md
```

---

My `.sops.yaml`:

```yaml
keys:
  - &admin_alice age162j8mn60ty8dxk8cvww2lckteyeemdnd64trekpv35qcuw2pqcfqwtnm9q
creation_rules:
  - path_regex: machines/homelab1/values/.*
    key_groups:
      - age:
          - *admin_alice

  - path_regex: machines/homelab2/values/.*
    key_groups:
      - age:
          - *admin_alice
```

My `justfile`:

```justfile
# use bash for shell commands
set shell := ["bash", "-c"]

# Set hostname environment
hostname := `hostname`

deploy input:
  # Perform remote deploy action
  ls machines/{{input}}/values/* | xargs -n 1 sops decrypt -i ; sed -i "/^\s*hostname[[:space:]]*=[[:space:]]*\"/s/\"\(.*\)\"/\"{{input}}\"/" ./flake.nix ; git add . ; nixos-rebuild-ng switch --flake .#{{input}} --build-host root@{{input}} --target-host root@{{input}} -v ; ls machines/{{input}}/values/* | xargs -n 1 sops encrypt -i

de input:
  # Decrypt
  ls machines/{{input}}/values/* | xargs -n 1 sops decrypt -i

en input:
  # Encrypt
  ls machines/{{input}}/values/* | xargs -n 1 sops encrypt -i
```

🧠 **Key points:**
You need to customize the hostname field matching scheme in your own `flake.nix`.
Use `sed` to dynamically replace the hostname in `flake.nix`, and use `{{input}}` to substitute the hostname in the `just` command:

```
sed -i "/^\s*hostname[[:space:]]*=[[:space:]]*\"/s/\"\(.*\)\"/\"{{input}}\"/" ./flake.nix
```

Examples:

```bash
just de homelab1     # Decrypt all encrypted nix values in machines/homelab1/values/
just en homelab1     # Encrypt all nix values in machines/homelab1/values/
just deploy homelab1 # Auto decrypt + replace hostname + deploy homelab1

just de homelab2
just en homelab2
just deploy homelab2
```

---

## ✅ Summary

With this approach, you can:

- Use `sops` to encrypt any Nix value;
- Safely import sensitive data during the build phase;
- Automate encryption/decryption and deployment with `just`;
- Keep your configuration repository tidy and secure.

🧊 While this isn’t a perfect solution, it’s a **practical and elegant compromise** for cases where you need Nix-level secret handling.

If you want to see more practical examples, please visit [my Nix configuration](https://github.com/atp-gh/atplab).
