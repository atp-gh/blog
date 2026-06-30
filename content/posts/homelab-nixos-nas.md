+++
title = "My NixOS NAS🧊"
date = "2025-03-04"
updated = "2025-03-04"
description = "Documenting my journey of building a personal NAS using NixOS."
tags = ["NixOS", "Hardware", "Nas", "Homelab"]
+++

You can find my config [here](https://github.com/atp-gh/atplab)

## A Few Words Before

Building this NixOS NAS has been a journey of both discovery and satisfaction.
My passion for NixOS began 1 year ago when I realized that its declarative configuration model could simplify even the most complex system setups.
I decided to channel that passion into creating a robust, secure, and highly reproducible NAS solution that not only meets my storage needs but also serves as a playground for experimenting with modern technologies.

Every aspect of this system, from the carefully( maybe 🙃) chosen hardware components to the selection of software tools, was driven by a desire for reliability and ease of management.
The declarative approach allowed me to automate almost every task.
The sense of control and precision has made managing my NAS an enjoyable and continuously rewarding experience.

It’s incredibly satisfying to see the system handle tasks flawlessly, ensuring that data is secure and always available.
The entire project is a reflection of my commitment to reproducible and declarative configurations, and it stands as a personal milestone in my ongoing exploration of NixOS.

## Hardware Specifications

| name        | content             |
| ----------- | ------------------- |
| Motherboard | GIGABYTE A520i Dash |
| CPU         | R5 5600G            |
| Memory      | 16GB                |
| SSD         | 512GB               |
| HDD         | 2 x 1 TB            |

## Key Features✨

- Declarative configuration of nas systems, ❤️love from ❄️nixos
- Supports essential applications including Immich, Syncthing, Alist, SMB, and more.
- Declarative configuration of hard disk partitions
- Remote deployment capability
- Critical data is securely encrypted
- Standardized NixOS configuration management with Clan
- Robust ZFS file systems, powerful💪
- Automated backup routines
- Optimized power consumption
- Basic monitoring and backup notifications.
- Automatic TLS certificate provisioning
- Highly reproducible configuration, at least for me, ❤️love from ❄️nixos again

## Technology Stack

| name                                                     | description                                                  |
| -------------------------------------------------------- | ------------------------------------------------------------ |
| [nixos](https://nixos.org/)                              | Operating system                                             |
| [zfs](https://openzfs.github.io/openzfs-docs/index.html) | File system                                                  |
| [disko](https://github.com/nix-community/disko)          | Declarative managed filesystems                              |
| [nix-sops](https://github.com/Mic92/sops-nix)            | Critical information encryption                              |
| [clan](https://docs.clan.lol/)                           | Peer-to-peer computer management framework, powered by nix❄️ |
| [nginx](https://nginx.org/)                              | Reverse proxy                                                |
| [go-acme](https://go-acme.github.io/lego/)               | Automatic tls certificate request                            |
| [restic](https://restic.net/)                            | Automatic backups                                            |
| [gotify](https://gotify.net/docs/)                       | Automatic send notifications                                 |
| [dashy](https://dashy.to/)                               | Homepage                                                     |
| [glances](https://nicolargo.github.io/glances/)          | System monitoring integrated with Dashy                      |
| [synching](https://syncthing.net/)                       | Synchronizes important data for real-time backups            |
| [immich](https://immich.app/)                            | Family digital camera management                             |
| [cockpit](https://cockpit-project.org/)                  | System panel                                                 |
| [forgejo](https://forgejo.org/)                          | Self-hosted git server                                       |
| [alist](https://alist.nn.ci/)                            | Web document client                                          |
| [wakapi](https://github.com/muety/wakapi)                | Code statistics tracking                                     |

## overview

### Dashy(homepage)

![](https://img.0pt.icu/learn/homelab/introducing-my-nixos-nas/1.avif)
![](https://img.0pt.icu/learn/homelab/introducing-my-nixos-nas/2.avif)

### System fastfetch

![](https://img.0pt.icu/learn/homelab/introducing-my-nixos-nas/3.avif)

### Restic + Gotify(Backup message)

![](https://img.0pt.icu/learn/homelab/introducing-my-nixos-nas/4.avif)

### Deploying

![](https://img.0pt.icu/learn/homelab/introducing-my-nixos-nas/5.avif)

### ZFS(this is my 🧊💪)

![](https://img.0pt.icu/learn/homelab/introducing-my-nixos-nas/6.avif)
