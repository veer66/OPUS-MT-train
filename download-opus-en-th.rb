$URLs = %w{https://object.pouta.csc.fi/OPUS-JW300/v1/xml/en-th.xml.gz
           https://object.pouta.csc.fi/OPUS-Tatoeba/v20190709/xml/en-th.xml.gz
           https://object.pouta.csc.fi/OPUS-Tatoeba/v20190709/xml/en-th.xml.gz      
           https://object.pouta.csc.fi/OPUS-Tanzil/v1/xml/en-th.xml.gz
           https://object.pouta.csc.fi/OPUS-QED/v2.0a/xml/en-th.xml.gz
           https://object.pouta.csc.fi/OPUS-GNOME/v1/xml/en-th.xml.gz
           https://object.pouta.csc.fi/OPUS-bible-uedin/v1/xml/en-th.xml.gz
           https://object.pouta.csc.fi/OPUS-KDE4/v2/xml/en-th.xml.gz
           https://object.pouta.csc.fi/OPUS-Ubuntu/v14.10/xml/en-th.xml.gz}

$URLs.each do |url|
  corpus_name, version, format_name, filename = url.split(/\//)[-4..-1]
  dir_path = File.join(ENV['HOME'], 'OPUS', corpus_name + version, format_name)
  puts "mkdir -p #{dir_path}"
  `mkdir -p #{dir_path}`
  file_path = File.join(dir_path, filename)
  cmd = "wget #{url} -O #{file_path}"
  puts "Run: #{cmd}"
  `#{cmd}`
end
