require 'rexml/document'
require 'logger'
require 'rally_rest_api'
require './bamboo_project'
require './rally_project'
require './obfuscate'

class Notifier

	@doc = nil

	def initialize(doc,filename,logger)

		logger.info("notifier:initiatlize:" + filename )
	
		@filename = filename
		@doc = doc
		@logger = logger
		                          
		@bamboo_url      = @doc.elements['/bamboo-rally-notifier/bamboo/url'].text.strip
		@bamboo_user     = @doc.elements['/bamboo-rally-notifier/bamboo/user'].text.strip
		@bamboo_password = @doc.elements['/bamboo-rally-notifier/bamboo/password'].text.strip
		
		@rally_url       = @doc.elements['/bamboo-rally-notifier/rally/server'].text.strip
		@rally_user      = @doc.elements['/bamboo-rally-notifier/rally/user'].text.strip
		@rally_password  = @doc.elements['/bamboo-rally-notifier/rally/password'].text.strip
		
		# check passwords for obfuscation
		dirty = false
		if !Obfuscate.encoded? @bamboo_password
			obfuscated = Obfuscate.encode(@bamboo_password)
			@doc.elements["/bamboo-rally-notifier/bamboo/password"].text = obfuscated
			dirty = true
		else
	 		@bamboo_password = Obfuscate.decode(@bamboo_password)
		end
	
		if !Obfuscate.encoded? @rally_password
			obfuscated = Obfuscate.encode(@rally_password)
			@doc.elements["/bamboo-rally-notifier/rally/password"].text = obfuscated
			dirty = true
		else
	 		@rally_password = Obfuscate.decode(@rally_password)
		end
		
		# update the doc if necessary
		@doc.write( File.new(@filename,"w") , 3) if dirty == true

	end

	
	# send build notification to rally and update changesets
	def notify_build(bamboo_project,build_result,config_project)
	
		@logger.info("Notifying Rally for build key #{build_result.build_key}")
		
		@logger.debug("Logging in with '#{@rally_user}','#{@rally_password}'")
		rp = RallyProject.new(@rally_url,
					          @rally_user,
					          @rally_password,
					          config_project.elements["rally-workspace"].text.strip,
					          config_project.elements["rally-project"].text.strip,
					          @logger)
					          
		# find the rally build definition
		def_name = bamboo_project.get_project + "-" + bamboo_project.get_plan					          
		@logger.debug("Definition name #{def_name}")
		bd = rp.find_or_create_build_definition(def_name)
		@logger.debug("Build Definition #{bd}")
		
		# find the rally changesets
		cs = rp.find_changesets( build_result.changesets )
		@logger.debug("Changesets #{cs}")
		
		# create a rally build
		rally_build = rp.create_build( bd, 
								 cs,
								 build_result.duration,
								 build_result.message,
								 build_result.build_number,
								 build_result.start_time,
								 build_result.status,
								 build_result.build_browse_link
								 )
		@logger.debug("Rally Build #{rally_build}")
								 
		@logger.debug("End:Notify")

		
	end

	def update_document(project, new_build_number)
	
		print "updating plan... " + project.elements["bamboo-plan"].text.strip + "\n"
	
		project.elements["last-build"].text = new_build_number
		
		@doc.write( File.new(@filename,"w") , 3)
	
	end
	
	def process
		@doc.elements.each('/bamboo-rally-notifier/projects/project') do |project|
		
			bamboo_project = project.elements["bamboo-project"].text.strip
			bamboo_plan    = project.elements["bamboo-plan"].text.strip
			@logger.info("bamboo-project = " + bamboo_project + " bamboo-plan = " + bamboo_plan)
			# def initializer(url, user, password, project, plan,logger)
			bp = BambooProject.new( @bamboo_url, 
									@bamboo_user, 
									@bamboo_password,
									bamboo_project,
									bamboo_plan,
									@logger)
			
			# last build from config
			last_run_build = project.elements["last-build"].text.strip.to_i
			@logger.info("last-run from config file = " + last_run_build.to_s)
			# last build from bamboo
			latest = bp.latest_build
			@logger.info("latest from bamboo = " + latest.build_number.to_s)
			# if there is at least one build
			if latest.build_number.to_i > 0 
				# if no last_run_build in config file then just run for latest.
				if last_run_build == 0
					notify_build(bp,latest,project)
					update_document(project,latest.build_number)
				else	
					# run from build after last build in config file to current.
					if (last_run_build < latest.build_number.to_i)
						last_run_build += 1
						while(last_run_build <= latest.build_number.to_i) do
							notify_build( bp, bp.specific_build(last_run_build.to_s), project)
							last_run_build += 1
						end
						update_document(project,(last_run_build-1).to_s)
					end
				end
			end
		end
	end

end

