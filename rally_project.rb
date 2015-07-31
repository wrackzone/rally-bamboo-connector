require 'logger'
require 'rally_rest_api'
require 'date'

# curl --user bmullan:<password> http://localhost:8085/rest/api/latest/result/SAMPLE-DEF/latest?expand=changes.change

class RallyProject

	def initialize(url, user, password, workspace_name, project_name,logger)

		@rally = RallyRestAPI.new(  :base_url => url, 
		                            :username => user, 
		                            :password => password,
		                            :version => "1.23"
		                          )
		                          
		@logger = logger
		@workspace = find_workspace(workspace_name)
		@project   = find_project(@workspace, project_name)
	
	end
	
	def find_workspace( name ) 
		@rally.user.subscription.workspaces.find { |w| w.name == name }
	end
	
	def find_project( workspace, name )
		workspace.projects.find { |p| p.name == name }
	end
	
	def find_changeset(rev)
		print "Workspace:#{@workspace.name}\n"
            qr = @rally.find(:changeset, 
            				  :project => @project, 
                              :workspace => @workspace, 
                              :project_scope_up => false, 
                              :project_scope_down => true) { equal :revision, rev }
			if qr && qr.total_result_count>0
				return qr.first
			end
			return nil
	end
	
	def find_objects_by_name(type,name)  
          if name != "" && name != nil
            query_result = @rally.find(type, 
            				  :project => @project, 
                              :workspace => @workspace, 
                              :project_scope_up => false, 
                              :project_scope_down => false) { equal :name, name }
            return query_result
          end
  	end

	def find_or_create_build_definition( def_name ) 
		
		@logger.debug("Looking for build definition #{def_name}")
	
		results = find_objects_by_name( :build_definition,def_name ) 

		@logger.debug("Found #{results.total_result_count} results")
		if !results || results.total_result_count == 0
			# create
			fields = {
				:name => def_name,
				:workspace => @workspace,
				:project => @project	
			}
			build_def = @rally.create(:build_definition, fields)
			@logger.debug("Created #{build_def}")

		else
			@logger.debug("Found build definition #{def_name}")
			build_def = results.first
		end
		
	end

	# status can be [SUCCESS, FAILURE, INCOMPLETE, UNKNOWN, NO BUILDS]
	def create_build( build_def, changesets, duration, message, number, start, status,uri )

		@logger.debug("Creating build.")
	
		fields = {
			:build_definition => build_def,
			:changesets => changesets,
			:duration => duration,
			:message => message,
			:number => number,
			:start => start,
			:status => status,
			:uri => uri	
		}
		@logger.debug("Creating build #{fields}")
		
		build = @rally.create(:build, fields)
		@logger.debug("Created build #{fields}")

	
	end
	
	# create an array of rally changesets based on changeset ids from Bamboo
	def find_changesets( changeset_ids )
		sets = Array.new
		changeset_ids.each do |id|
			cs = find_changeset(id)
			if cs
				sets.push(cs)
			end
		end
		sets
	end

end


#rp = RallyProject.new("https://demo.rallydev.com/slm", "bmullan@rallydev.com", "Just4Rally", "User Story Pattern","Shopping Team",nil)
#bd =  rp.find_or_create_build_definition( "SAMPLE-DEF" )
#b = rp.create_build( bd, 100, "build message","1", DateTime.now, "SUCCESS","http://localhost:8085/browse/SAMPLE-DEF-11")
#pp b
