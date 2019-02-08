require 'yaml'
require "MavenToPKGBUILD/version"


module MavenToPKGBUILD

  def create_pkg_version(version)
    version.delete_prefix("'").delete_suffix("'").split("-").first
  end
  
  def build_pkg(pkg, options)
    build(pkg["name"], pkg["groupid"], pkg["version"], pkg["artifactid"], options)
  end

  def build(name, groupid, version, artifactid, options) # arch="x86_64", full=false, compact=false)

    ## Arguments, Pom variables
    @artifactid = artifactid
    @version = version
    @groupid = groupid
    @name = artifactid if name.nil?
    @foldername = @name

    ## Options
    @arch = options.fetch :arch, "x86_64"
    @full = options.fetch :full, false
    @compact = options.fetch :compact, false

    ## PKGBUILD variables
    ## Sometimes there are quotes in version names.
    @pkgversion = @version.delete_prefix("'").delete_suffix("'")
    @pkgarch = "any" 
    @pkgrel = options.fetch :version, "1"
    @compact_pkg = @compact ? "-compact" : ""

    
    ## JavaCPP variables
    @javacppversion = ""
    @platform = "linux"
    @javacpp = false

    puts "Starting to build #{@name}, #{@groupid}, #{@version}, #{@artifactid}. "
    
    if(@groupid.eql? "org.bytedeco.javacpp-presets" and @artifactid.end_with? "-platform")
      puts "JavaCPP platform building"
      @javacpp = true
      @name = @artifactid.split("-platform").first
      @pkgversion, @javacppversion = @pkgversion.split "-"
      @pkgrel = @javacppversion+@pkgrel
      @pkgarch = @arch 
    else
        @pkgversion = @pkgversion.split("-").first
    end
    
    create_directories()
    pkgbuild = build_pkgbuild()
    
    # write pkgbuild
    puts "writing pkgbuild..."
    File.open(@foldername+"/PKGBUILD", 'w') { |file| file.write(pkgbuild) }

    pom = build_pom()
    puts "Writing pom..."
    File.open(@foldername+"/pom.xml", 'w') { |file| file.write(pom) }

    ## make the package
    currentdir = Dir.pwd
    Dir.chdir @foldername
    `makepkg -f >> build.log`
    `cp *.pkg.tar.xz ../pkgs`
    Dir.chdir currentdir
    
    puts "Finished, you can check the folder #{@name}."

  end

  def create_directories()
    begin 
      Dir.mkdir @foldername
      Dir.mkdir "pkgs"
    rescue => e
    end
  end

  def build_pkgbuild

    config = <<-CONFIG 
# Maintainer: RealityTech <laviole@rea.lity.tech>
pkgname=java-#{@name}#{@compact_pkg}
pkgver=#{@pkgversion}
pkgrel=#{@pkgrel}
pkgdesc=""
arch=('#{@pkgarch}')
url=""
license=()
groups=()
depends=('java-runtime')
makedepends=('maven' 'jdk8-openjdk')
provides=()
conflicts=()
replaces=()

build() {
  cd "$startdir"

CONFIG
    
    if @javacpp
      config = config + "  mvn dependency:copy-dependencies\n "
    else
      config = config + "  mvn dependency:copy-dependencies -Djavacpp.platform=#{@platform}-#{arch} \n "
    end

    if @compact
      config = config + "  mvn package -Djavacpp.platform=#{@platform}-#{arch} \n "
    end

    ## Continue building
    package = <<-PACKAGE
}

package() {

PACKAGE


    if @compact
      install = "  installCompact '#{@name}' '#{@artifactid}' '-jar-with-dependencies' \n"
      
    else 
      
      if @full
        install = " installAll '#{@name}'" 
      else 
        if @javacpp

          # opencv-3.4.0-1.4.jar          ->  #{name}-#{version}-#{javacppversion}.jar
          # opencv-platform-3.4.0-1.4.jar ->  #{name}-platform-#{version}-#{javacppversion}.jar
          # opencv-3.4.0-1.4-linux-x86_64.jar ->  #{name}-#{version}-#{javacppversion}-#{@platform}-#{arch}.jar
          # javacpp-1.4.jar -> javacpp-#{javacppversion}.jar   ## Not sure yet!

          install = <<-INSTALL
         # jar-name, output-jar-name, link-name 
        installJavaCPP '#{@name}-#{@pkgversion}-#{@javacppversion}.jar' '#{@name}-#{@pkgversion}.jar' '#{@name}.jar'       
        installJavaCPP '#{@name}-platform-#{@pkgversion}-#{@javacppversion}.jar' '#{@name}-platform-#{@pkgversion}.jar' '#{@name}-platform.jar'       
        installJavaCPP '#{@name}-#{@pkgversion}-#{@javacppversion}-#{@platform}-#{arch}.jar' '#{@name}-#{@pkgversion}-#{@platform}-#{arch}.jar' '#{@name}-#{@platform}-#{arch}.jar'       

      INSTALL
        else 
          install = <<-INSTALL
 
        installOne '#{@name}' '#{@artifactid}'

INSTALL
        end
      end
    end
    
    functions = <<-FUNCTIONS

}

 installOne() {
     local name=$1
     local artifact=$2
     local opt=$3
     install -m644 -D ${startdir}/target/dependency/${artifact}-#{@version}${opt}.jar ${pkgdir}/usr/share/java/${name}/${pkgver}/${name}-${pkgver}.jar
     cd ${pkgdir}/usr/share/java/
     ln -sr ${name}/${pkgver}/${name}-${pkgver}.jar $name.jar
     ln -sr ${name}/${pkgver}/${name}-${pkgver}.jar $name-${pkgver}.jar
 }

 installCompact() {
     local name=$1
     local artifact=$2
     local opt=$3
     install -m644 -D ${startdir}/target/${name}-#{@version}${opt}.jar ${pkgdir}/usr/share/java/${name}/${pkgver}/${name}-${pkgver}${opt}.jar
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
     install -m644 -D ${startdir}/target/dependency/${jarname} ${pkgdir}/usr/share/java/#{@name}/${pkgver}/${outputname}
     cd ${pkgdir}/usr/share/java/
     ln -sr #{@name}/${pkgver}/${outputname} $name
     ln -sr #{@name}/${pkgver}/${outputname} ${outputname}
 }

FUNCTIONS

    ## Install in a maven-like environment ?
    ## ${groupId.replace('.','/')}/${artifactId}/${version}/${artifactId}-${version}${classifier==null?'':'-'+classifier}.${type}
    
    pkgbuild = pkgbuild + package + install + functions
    
    return pkgbuild
    
  end
  


  def build_pom
    
    pom = <<-POM
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>tech.lity.rea</groupId>
    <artifactId>#{@name}</artifactId>
    <version>1-dummy</version>
    <packaging>jar</packaging>

    <name>#{@name}</name>
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
	<groupId>#{@groupid}</groupId>
	<artifactId>#{@artifactid}</artifactId>
	<version>#{@version}</version>
      </dependency>
    </dependencies>
POM

    if @compact
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
    return pom
  end
  
end
