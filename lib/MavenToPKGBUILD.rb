require "MavenToPKGBUILD/version"

require 'yaml'


module MavenToPKGBUILD
  # Your code goes here...


  def build(name, groupid, version, artifactid, arch="x86_64", full=false, compact=false)
    puts "Starting to build #{name}, #{groupid}, #{version}, #{artifactid}. "

    javacpp = false
    pkgversion = version
    
    ## Sometimes there are quotes in version names.
    pkgversion = pkgversion.delete_prefix("'").delete_suffix("'")
    pkgrel = "1"
    javacppversion = ""


#    binding.pry
  # groupid: org.bytedeco.javacpp-presets
  # artifactid: opencv-platform
  # version: 3.4.0-1.4

    platform = "linux"
    foldername = name

    pkgarch = "any" 
    
    if(groupid.eql? "org.bytedeco.javacpp-presets" and artifactid.end_with? "-platform")
      puts "JavaCPP platform building"
      javacpp = true
      name = artifactid.split("-platform").first
      pkgversion, javacppversion = pkgversion.split "-"
      pkgrel = javacppversion
      pkgarch = arch 
    else
        pkgversion = pkgversion.split("-").first
    end
    
    ## 1. build the directory
    begin 
      Dir.mkdir foldername
      Dir.mkdir "pkgs"
    rescue => e

    end

    ## 2. create the PGKBUILD
    pkgbuild = <<-PKGBUILD 
# Maintainer: RealityTech <laviole@rea.lity.tech>
pkgname=java-#{name}
pkgver=#{pkgversion}
pkgrel=#{pkgrel}
pkgdesc=""
arch=('#{pkgarch}')
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

PKGBUILD
    
    if javacpp
      pkgbuild = pkgbuild + "  mvn dependency:copy-dependencies\n "
    else
      pkgbuild = pkgbuild + "  mvn dependency:copy-dependencies -Djavacpp.platform=#{platform}-#{arch} \n "
    end

    if compact
      pkgbuild = pkgbuild + "  mvn package -Djavacpp.platform=#{platform}-#{arch} \n "
    end

    ## Continue building
    pkgbuild2 = <<-PKGBUILD2
    
}

package() {

PKGBUILD2

    # opencv-3.4.0-1.4.jar          ->  #{name}-#{version}-#{javacppversion}.jar
    # opencv-platform-3.4.0-1.4.jar ->  #{name}-platform-#{version}-#{javacppversion}.jar
    # opencv-3.4.0-1.4-linux-x86_64.jar ->  #{name}-#{version}-#{javacppversion}-#{platform}-#{arch}.jar
    # javacpp-1.4.jar -> javacpp-#{javacppversion}.jar   ## Not sure yet!

    if compact
      pkgbuild3 = "  installCompact '#{name}' '#{artifactid}' '-jar-with-dependencies' \n"
      
    else 
    
      if full
        pkgbuild3 = " installAll '#{name}'" 
    else 
      if javacpp
        pkgbuild3 = <<-PKGBUILD3

         # jar-name, output-jar-name, link-name 
        installJavaCPP '#{name}-#{pkgversion}-#{javacppversion}.jar' '#{name}-#{pkgversion}.jar' '#{name}.jar'       
        installJavaCPP '#{name}-platform-#{pkgversion}-#{javacppversion}.jar' '#{name}-platform-#{pkgversion}.jar' '#{name}-platform.jar'       
 
        installJavaCPP '#{name}-#{pkgversion}-#{javacppversion}-#{platform}-#{arch}.jar' '#{name}-#{pkgversion}-#{platform}-#{arch}.jar' '#{name}-#{platform}-#{arch}.jar'       

      PKGBUILD3
        
      else 
        pkgbuild3 = <<-PKGBUILD3
 
        installOne '#{name}' '#{artifactid}'

PKGBUILD3
      end
      end
    end
      
 pkgbuild4 = <<-PKGBUILD4

}

 installOne() {
     local name=$1
     local artifact=$2
     local opt=$3
     install -m644 -D ${startdir}/target/dependency/${artifact}-#{version}${opt}.jar ${pkgdir}/usr/share/java/${name}/${pkgver}/${name}-${pkgver}.jar
     cd ${pkgdir}/usr/share/java/
     ln -sr ${name}/${pkgver}/${name}-${pkgver}.jar $name.jar
 }

 installCompact() {
     local name=$1
     local artifact=$2
     local opt=$3
     install -m644 -D ${startdir}/target/${name}-#{version}${opt}.jar ${pkgdir}/usr/share/java/${name}/${pkgver}/${name}-${pkgver}${opt}.jar
     cd ${pkgdir}/usr/share/java/
     ln -sr ${name}/${pkgver}/${name}-${pkgver}${opt}.jar $name${opt}.jar
 }


 installAll() {
     local name=$1
     mkdir -p ${pkgdir}/usr/share/java/${name}-with-deps/${pkgver}
     install -m644 -D ${startdir}/target/dependency/*.jar ${pkgdir}/usr/share/java/${name}-with-deps/${pkgver}/
     # links ?
     # ln -sr ${name}/${pkgver}/${name}-${pkgver}.jar $name.jar
 }

 installJavaCPP() {
     local jarname=$1
     local outputname=$2
     local name=$3
     install -m644 -D ${startdir}/target/dependency/${jarname} ${pkgdir}/usr/share/java/#{name}/${pkgver}/${outputname}
     cd ${pkgdir}/usr/share/java/
     ln -sr #{name}/${pkgver}/${outputname} $name
     ln -sr #{name}/${pkgver}/${outputname} ${outputname}
 }


PKGBUILD4


    pkgbuild = pkgbuild + pkgbuild2 + pkgbuild3 + pkgbuild4
 
    # write pkgbuild
    puts "writing pkgbuild..."
    File.open(foldername+"/PKGBUILD", 'w') { |file| file.write(pkgbuild) }

    # create the POM
    
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
POM

    if compact
      pom = pom + <<-POM2

    <build>
       <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-assembly-plugin</artifactId>
                <executions>
                    <execution>
                        <phase>package</phase>
                        <goals>
                            <goal>single</goal>
                        </goals>
                        <configuration>
                            <descriptorRefs>
                                <descriptorRef>jar-with-dependencies</descriptorRef>
                            </descriptorRefs>
                        </configuration>
                    </execution>
                </executions>
            </plugin>
         </plugins>
      </build>
POM2
    end 

    pom = pom + " </project> "
    
    # write pom
    puts "Writing pom..."
    File.open(foldername+"/pom.xml", 'w') { |file| file.write(pom) }

    currentdir = Dir.pwd
    
    Dir.chdir foldername
    `makepkg -f >> build.log`
    `cp *.pkg.tar.xz ../pkgs`
    
    Dir.chdir currentdir
    
    puts "Finished, you can check the folder #{name}."

  end

  def build_pkg(pkg, arch, full, compact)
    pkg["name"] = pkg["artifactid"] if  pkg["name"].nil?
    build(pkg["name"], pkg["groupid"], pkg["version"], pkg["artifactid"], arch, full, compact)
  end



  
end
