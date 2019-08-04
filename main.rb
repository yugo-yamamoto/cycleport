require_relative './crawler.rb'

c = Crawler.new
c.login
p c.session_id

csv = File.open("csv/85.csv", 'w')
csv.puts("place\tlat\tlon\tcount")

[8, 5].each do |area_id| 
  html = c.fetch_html(area_id)
  ports = c.ports(html)
  pp ports
  ports.each do |port|
    csv.puts(
      [
        port[:place],
        port[:lat],
        port[:lon],
        port[:count]
      ].join("\t")
    )
  end
end
