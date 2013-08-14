require 'rexml/document'
require 'logger'

# curl --user bmullan:6keyserv http://localhost:8085/rest/api/latest/result/SAMPLE-DEF/latest?expand=changes.change

class BambooResult

	def initialize(xml)
		@xml_result = REXML::Document.new(xml)
	end

	# doc.elements['/bamboo-rally-notifier/service/interval'].text+'s') { process(doc) }
	def build_number 
#			@xml_result.elements['result'].attributes['number']
			@xml_result.elements['build'].attributes['number']
	end
	
	def build_link
#			@xml_result.elements['result/link'].attributes['href']
			@xml_result.elements['build/link'].attributes['href']
	end
	
	# convert http://localhost:8085/rest/api/latest/result/SAMPLE-DEF-11
	# to http://localhost:8085/browse/SAMPLE-DEF-10 
	def build_browse_link
#		build_link.gsub("rest/api/latest/result","browse")
		build_link.gsub("rest/api/latest/build","browse")
	end

	def build_key
#			@xml_result.elements['result'].attributes['key']
			@xml_result.elements['build'].attributes['key']
	end

	# status can be [SUCCESS, FAILURE, INCOMPLETE, UNKNOWN, NO BUILDS]
	def status
#		case @xml_result.elements['result'].attributes['state']
		case @xml_result.elements['build'].attributes['state']
			when "Successful" then "SUCCESS"
			else "FAILURE"
		end
	end

	def start_time
#		@xml_result.elements['result/buildStartedTime'].text.strip
		@xml_result.elements['build/buildStartedTime'].text.strip
	end
	
	def duration
#		@xml_result.elements['result/buildDuration'].text.strip.to_i
		@xml_result.elements['build/buildDurationInSeconds'].text.strip.to_i
	end
	
	def message
#		@xml_result.elements['result/buildReason'].text.strip
		@xml_result.elements['build/buildReason'].text.strip
	end

	#<changes expand="change" size="3" max-result="3" start-index="0">
	#	<change changesetId="157" fullName="barry" userName="bmullan" author="bmullan" expand="files">
	#		<comment>DE20 </comment>
	#		<date>2011-04-02T21:20:03.098-04:00</date>
	#		<files size="1" max-result="1" start-index="0"/>
	#	</change>
			
	# returns an array of changeset id's
	def changesets
		sets = Array.new
#		@xml_result.elements.each("/result/changes/change") do |change|
		@xml_result.elements.each("/build/changes/change") do |change|
			print "#{change.attributes['changesetId']}\n"
			sets.push( change.attributes['changesetId'] ) 
		end
		sets
	end	

end

