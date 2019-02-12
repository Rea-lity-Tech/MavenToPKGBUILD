# MavenToPKGBUILD
Create packages for Arch linux (AUR) for Maven dependencies. 

The packages are installed in `/usr/share/java`, as it is recommended in the PKGBUILD for [java guide](https://wiki.archlinux.org/index.php/Java_package_guidelines). For now and in the future I try to stick to the official guidelines. 

This is a first implementation to manage dependencies for java programs that share jar files. The goal is to distribute java programs and its dependencies separated in a clean way. 
However the current risk is that we have to create dozens or hundreds of packages for large projects.

Please do not submit the generated PKGBUILDs to the ArchLinux repository without filling out all the required informations. 

## How to use

#### 1. Create the dependency list


Go to a maven project where the `pom.xml` file resides: 

`pkg-maven-list-deps`

* It creates a `deps.yaml` file listing the dependencies, used later to create packages. 
* The output of the execution lists which dependencies are already installed. 
* It create a `classpath.txt` text file containing the classpath to use. 

When all packages are created and installed you can use this classpath file like this: 

``` bash 
CP=$(<classpath.txt)
java -cp $CP:target/* tech.lity.rea.app.Demo
```

#### 2. Create packages from the dependency list

Create a package for each dependency in the database. It is quite simple for now and does not handle double entry or version conflicts. You can create a new folder and try to build all the dependencies: 

``` bash 
mkdir dist ; cd dist 
pkg-maven ../deps.yaml all
```

The output packages are collected to the `pkg` folder. 


#### Alternative use: build a package by its name. 

If you only miss few packages, or your project is small you can get packages one by one. 

`pkg-maven jedis redis.clients 2.9.0` 

This will create a package for **one jar only**. You can get get its dependencies by going in the folder and running the `pkg-maven-list-deps` script. For jedis, there are no external dependencies. 

The resulting package is:`pkg/java-jedis-2.9.0-1-any.pkg.tar.xz`.


## Options 

There are three ways to build a package. Either you want to package a specific jar, a jar with packages for each dependency, or a jar with its dependency included in one big jar. 


## Installing a package 

After the package(s) are built, you can install it with pacman. 

Here is an example: 

`sudo pacman -U pkgs/java-jedis-2.9.0-1-any.pkg.tar.xz`


### TODO: 

* ~Gemify this~.
* ~Deploy Gem~.
* ~Update README~ to improve.
* More tests. 
* Better parsing. 
