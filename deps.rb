require 'yaml'

if ARGV[0] != nil
  output = ARGV[0]
else
  output = "deps.yaml"
end

tmp = "tmp.txt"
`mvn dependency:list -DoutputFile=#{tmp}`

lines = File.readlines tmp
lines = lines.drop 2 

all_deps = {} 

lines.each do |l|
  groupid, artifactid, type, version = l.strip.split ":"

  next if artifactid.nil? or artifactid.empty?

  puts "Dependency: " + artifactid.to_s
  dep = {}
  dep["groupid"] = groupid
  dep["artifactid"] = artifactid
  dep["version"] = version
  #  dep["type"] = type
  all_deps[artifactid] = dep
end

File.open(output, 'w') {|f| f.write all_deps.to_yaml }
