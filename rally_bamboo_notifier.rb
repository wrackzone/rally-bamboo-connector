require 'rubygems'
require 'openwfe/util/scheduler'
require 'rexml/document'
require 'logger'
require './notifier'
include OpenWFE

def setup_logger(doc) 
	
	logtext = doc.elements['/bamboo-rally-notifier/service/log-level'].text.strip
	logfile = doc.elements['/bamboo-rally-notifier/service/log-file'].text.strip
	
	log = Logger.new(logfile)
	
	log.level = case logtext
		when "INFO" then Logger::INFO
		when "DEBUG" then Logger::DEBUG
		when "WARN" then Logger::WARN
		when "ERROR" then Logger::ERROR
		when "FATAL" then Logger::FATAL
		else Logger::INFO
	end
	
	return log	
end

def process(doc,filename)
	
	log = setup_logger(doc)
	log.info("logging to file #{doc.elements['/bamboo-rally-notifier/service/log-file'].text.strip.strip}")
	
	doc.elements.each('/bamboo-rally-notifier/projects/project') do |project|
	
		log.info("bamboo-project = " + project.elements["bamboo-project"].text.strip)
		log.info("bamboo-plan    = " + project.elements["bamboo-plan"].text.strip)
		log.info("rally-workspace= " + project.elements["rally-workspace"].text.strip)
		log.info("rally-project  = " + project.elements["rally-project"].text.strip)
	
	end
	notifier = Notifier.new(doc,filename,log)
	notifier.process

end

# start the scheduler
scheduler = Scheduler.new
scheduler.start

# process command line args
ARGV.each do |arg|
	if  File::exists?( arg )
		# schedule the config file
		doc = REXML::Document.new(File.read(arg))
		scheduler.schedule_every( 
			doc.elements['/bamboo-rally-notifier/service/interval'].text.strip+'s') { process(doc,arg) }
#			doc.elements['/bamboo-rally-notifier/service/interval'].text.strip+'s') { process(doc,arg) }
	else
		p "#{arg} not found!"
	end
end

scheduler.join
