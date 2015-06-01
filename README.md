# PPBoot

## What is PPBoot and how it can help me
PPBoot is a small class/script that allows you to use 'puppet apply' if your puppet manifest relies on forge modules. The problem is puppet cannot automatically satisfy your module dependencies though they are mentioned in the metadata.json. It's officially not capable of "installing" local module with dependency resolution.

Honestly you have to sometimes... e.g if you are bootstrapping your first puppet master.

## How to use

The script was designed to be a single file entity `ppboot.rb`. You can drop it within your module or copy it to the box

    mkdir /tmp/mybootdir
    ruby ppboot --modulepath /tmp/mybootdir --input /path/to/my/module/metadata.json
    puppet apply --modulepath /path/to/my/:/tmp/mybootdir

If you do not specify modulepath the default will be used (`/etc/puppet/modules` if root, `$HOME/.puppet/modules` if unprivileged user)

## Requirements

The box should have puppet >= 3.0.0 installed. That's enough. Ruby-1.8.7 and 1.9.3 are supported but not guaranteed to work. Some modern rubies also have conflicts with old puppets, e.g. ruby-2.1 and puppet <= 3.2
