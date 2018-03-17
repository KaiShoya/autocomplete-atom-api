require 'open-uri'
require 'nokogiri'
require 'json'

DOC_URL = "https://developers.google.com/apps-script/reference/"

JSON_FILE = "completions.json"

## html取得
def get_html(url, charset = nil)
	html = open(url) do |f|
		charset = f.charset if charset == nil
		f.read
	end
	return Nokogiri::HTML.parse(html, nil, charset)
end

def create_contents(url)
	completions = {}
	doc = get_html(url)
	doc.css("table.member.type").each do |table|
		table.css("tr").each do |tr|
			name = nil
			dist = nil
			content_url = nil
			tr.css("td").each_with_index do |td, i|
				name = td.text.strip if i == 0
				dist = td.text.strip if i == 1
				content_url = td.css("a").attribute("href").text.strip if i == 0
			end


			unless name.nil?
				print "#{name}..."
				completions[name] = create_content(content_url) unless name.nil?
				puts "#{completions[name].size}"
			end
		end
	end
	return completions
end

def create_content(url)
	contents = []
	doc = get_html(url)
	[["property","property"],["function","method"]].each do |classname, type|
		doc.css("table.members.#{classname}").each do |table|
			table.css("tr").each do |tr|
				content = {
					name: nil,
					text: nil,
					snippet: nil,
					description: nil,
					descriptionMoreURL: nil,
					leftLabel: nil,
					type: type
				}
				tr.css("td").each_with_index do |td, i|
					str = td.text.strip
					if i == 0
						content[:name] = str
						a = td.css("a")
						content[:descriptionMoreURL] = a.text.strip == "" ? nil : a.attribute("href").text.strip

						if str.include?("()")
							content[:text] = str
						else
							snippet = str.split("(")
							unless snippet[1].nil?
								parameters = []
								snippet[1].delete(")").split(",").each.with_index(1) do |param, j|
									parameters.push("${#{j}:#{param.strip}}")
								end
								snippet[1] = parameters.join(", ") + ")"
							end
							content[:snippet] = snippet.join("(")
						end
					end

					content[:description] = str if i == 2
					content[:leftLabel] = str if i == 1
				end
				contents.push(content) unless content[:name].nil?
			end
		end
	end
	return contents
end

def main
	completions = {}
	doc = get_html(DOC_URL)
	## G Suite Service一覧からjson用配列データ作成
	doc.xpath('//*[@id="gc-wrapper"]/div[2]/nav[1]/ul/li[1]/ul/li').each do |node|
		node.children.each_with_index do |child, i|
			next unless i == 0
			## 使われているか確認
			next unless child.css(".devsite-nav-icon-wrapper").first.nil?
			puts "### #{child.text.strip}"
			completions[child.text.strip] = create_contents("#{DOC_URL}#{child.text.strip.downcase}")
		end
	end

	## json出力
	print "Export #{JSON_FILE}.."
	File.open(JSON_FILE, "w") do |f|
		f.print JSON.pretty_generate(completions)
	end
	puts "ok."
end

main
