# MavenToPKGBUILD
Create packages for Arch linux (AUR) for Maven dependencies. 

The packages are installed in `/usr/share/java`, as it is recommended in the PKGBUILD for [java guide](https://wiki.archlinux.org/index.php/Java_package_guidelines). For now and in the future I try to stick to the official guidelines. 

This is a first implementation to manage dependencies for java programs that share jar files. The goal is to distribute java programs and its dependencies separated in a clean way. 
However the current risk is that we have to create dozens or hundreds of packages for large projects.

Please do not submit the generated PKGBUILDs to the ArchLinux repository without filling out all the required informations. 

## How to use

#### 1. Build a specific project:

`ruby builder-java.rb DATABASE.yaml PROJECT`

You can try it: 

`ruby builder-java.rb package.yaml jedis` 

#### 2. Build all the projects: 


Create a package for each dependency in the database. It is quite simple for now and does not handle double entry or version conflicts.

`ruby builder-java.rb DATABASE.yaml all`

You can try it: 
`ruby builder-java.rb package.yaml all` 

#### 3. Build a package by its name. 

You can also try it: 

`ruby builder-java.rb jedis redis.clients 2.9.0` 


## Installing a package 

After the package(s) are build, you can install it with pacman. 

Here is an example: 

`sudo pacman -U pkgs/java-jedis-2.9.0-1-any.pkg.tar.xz`

