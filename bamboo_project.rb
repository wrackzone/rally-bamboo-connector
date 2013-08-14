require 'rest_client'
require 'logger'
require './bamboo_result'

# curl --user bmullan:6keyserv http://localhost:8085/rest/api/latest/result/SAMPLE-DEF/latest?expand=changes.change

class BambooProject

	def initialize(url, user, password, project, plan,logger)
	
		@url      = url.gsub("http://","http://"+user+":"+password+"@")
		@user     = user
		@password = password
		@project  = project
		@plan     = plan
		@logger   = logger
	
	end
	
	def get_project
		@project
	end
	
	def get_plan
		@plan
	end

	def get_build(url)
			p = {:params => {:expand => 'changes.change',:os_authType => 'basic' },:accept => :xml}
			@logger.debug(url)
			result = RestClient.get url , p 
			@logger.debug(result)
			br = BambooResult.new(result)
	end

	def latest_build 
#			url = @url + "result/"+@project+"-"+@plan+"/latest"
			url = @url + "build/"+@project+"-"+@plan+"/latest"
			get_build(url)
	end
	
	def specific_build(number)
#			url = @url + "result/"+@project+"-"+@plan+"/"+number
			url = @url + "build/"+@project+"-"+@plan+"/"+number
			get_build(url)
	end

end

