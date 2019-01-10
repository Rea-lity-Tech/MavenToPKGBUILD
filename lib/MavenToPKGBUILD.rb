require "MavenToPKGBUILD/version"

require 'yaml'


module MavenToPKGBUILD
  # Your code goes here...


  def build(name, groupid, version, artifactid)
    puts "Starting to build #{name}, #{groupid}, #{version}, #{artifactid}. "

    
    ## 1. build the directory
    begin 
      Dir.mkdir name
    rescue => e

    end

    ## 2. create the PGKBUILD
    pkgbuild = <<-PKGBUILD 
# Maintainer: RealityTech <laviole@rea.lity.tech>
pkgname=java-#{name}
pkgver=#{version}
pkgrel=1
pkgdesc=""
arch=('any')
url=""
license=('GPL')
groups=()
depends=('java-runtime')
makedepends=('maven' 'jdk8-openjdk' 'git')
provides=("${pkgname%-git}")
conflicts=("${pkgname%-git}")
replaces=()

build() {
  cd "$startdir"
  mvn dependency:copy-dependencies
}

package() {
  local name='#{name}'
  
  install -m644 -D $startdir/target/dependency/${name}-${pkgver}.jar ${pkgdir}/usr/share/java/${name}/${pkgver}/${name}-${pkgver}.jar
  cd ${pkgdir}/usr/share/java
  ln -sr ${name}/${pkgver}/${name}-${pkgver}.jar $name.jar
}

PKGBUILD

    # write pkgbuild
    puts "writing pkgbuild..."
    File.open(name+"/PKGBUILD", 'w') { |file| file.write(pkgbuild) }

    pom = <<-POM
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>tech.lity.rea</groupId>
    <artifactId>#{name}</artifactId>
    <version>#{version}</version>
    <packaging>jar</packaging>

    <name>#{name}</name>
    <description></description>
    <url></url>
    
    <repositories>
        <repository>
            <id>clojars.org</id>
            <url>http://clojars.org/repo</url>
        </repository>

        <repository>
            <id>ossrh</id>
            <url>https://oss.sonatype.org/content/repositories/snapshots</url>
        </repository>

        <repository>
            <id>central</id>
            <name>Maven Repository Switchboard</name>
            <layout>default</layout>
            <url>http://repo1.maven.org/maven2</url>
            <snapshots>
                <enabled>true</enabled>
            </snapshots>
        </repository>
    </repositories>
    
    <dependencies>
      <dependency>
	<groupId>#{groupid}</groupId>
	<artifactId>#{artifactid}</artifactId>
	<version>#{version}</version>
      </dependency>
    </dependencies>
</project>
POM


    # write pom
    puts "Writing pom..."
    File.open(name+"/pom.xml", 'w') { |file| file.write(pom) }

    currentdir = Dir.pwd
    
    Dir.chdir name
    `makepkg -f >> build.log`
    `cp *.pkg.tar.xz ../pkgs`
    
    Dir.chdir currentdir
    
    puts "Finished, you can check the folder #{name}."

  end

  def build_pkg(pkg)
    pkg["name"] = pkg["artifactid"] if  pkg["name"].nil?
    build(pkg["name"], pkg["groupid"], pkg["version"], pkg["artifactid"])
  end



  
end
