#!/bin/env ruby


#
# Henry Molina
# Enero 21 de 2020
# monit_rest expone el estatus de monit via rest en los formatos JSON, pp y raw
# visitar:
#   http://localhost:2813/Monit
#   http://localhost:2813/Monit/raw
#   http://localhost:2813/Monit/pp

require 'webrick'
require 'json'

include WEBrick

PORT = 2813

$debug = false
$pid_file = '/var/run/monit_rest.pid'

def delete_pid
  File.delete($pid_file) if File.exist?($pid_file)
end

def start_webrick(config = {})
  config.update(:Port => PORT)
  server = HTTPServer.new(config)
  yield server if block_given?
  ['INT', 'TERM'].each {|signal|
    trap(signal) {
      server.shutdown
      delete_pid
    }
  }
  delete_pid
  File.open($pid_file, ::File::CREAT | ::File::EXCL | ::File::WRONLY){|f| f.write("#{Process.pid}") }
  server.start
end

# From: https://rubyit.wordpress.com/2011/07/25/basic-rest-server-with-webrick/
class RestServlet < HTTPServlet::AbstractServlet
  def response_status(worker)
    if worker.send(:run_success?)
	raise HTTPStatus::OK
    else
	raise HTTPStatus::ServerError
    end
  end

  def do_GET(req,resp)
      # Split the path into pieces, getting rid of the first slash
      path = req.path[1..-1].split('/')
      raise HTTPStatus::NotFound if !RestServiceModule.const_defined?(path[0])
      response_class = RestServiceModule.const_get(path[0])

      if response_class and response_class.is_a?(Class)
        # There was a method given
        if path[1]
          response_method = path[1].to_sym
          # Make sure the method exists in the class
          raise HTTPStatus::NotFound if !response_class.respond_to?(response_method)
          # Remaining path segments get passed in as arguments to the method
          if path.length > 2
            resp.body = response_class.send(response_method, path[2..-1])
          else
            resp.body = response_class.send(response_method)
          end
          response_status(response_class)

        # No method was given, so check for an "index" method instead
        else
          raise HTTPStatus::NotFound if !response_class.respond_to?(:index)
          resp.body = response_class.send(:index)
          response_status(response_class)
        end
      else
        raise HTTPStatus::NotFound
      end
  end

end

module RestServiceModule
  # Monit
  class Monit
    @monit_raw_status = ''
    @monit_internal_status = ''
    @run_success = false

    def self.internal
      output = Hash.new
      section_type = ''
      section_name = ''
      version = ''
      lines = @monit_raw_status.split("\n")
      lines.each do |line|
        if line =~ /^$/ .. line !~ /^$/
          p "new_section >> #{line}" if $debug
          new_section = true
        else
          p "#{section_type}:#{section_name} >> #{line}" if $debug
          new_section = false
        end

        if new_section and line !~ /^$/
          section_type = line.split(' ')[0,line.split(' ').size-1].join(' ')
          section_name = line.split(' ')[line.split(' ').size-1].delete('\'')
          output[section_type] = {} if output[section_type].nil?
          output[section_type][section_name] = {} if output[section_type][section_name].nil?
          next
        end

        line = line.gsub(/\s+/,' ')
        line.lstrip!

        case line
        when /^Monit/
             version = line.split(' ')[1]
             uptime  = line.split(':')[1]
             uptime.lstrip!
             output['Version'] = version
             output['Uptime'] = uptime
        when /^status/
             value = line.split(' ')[1,line.split(' ').size-1].join(' ')
             output[section_type][section_name]['status'] = value
        when /^monitoring status/
             value = line.split(' ')[2,line.split(' ').size-1].join(' ')
             output[section_type][section_name]['monitoring status'] = value
        when /^monitoring mode/
             value = line.split(' ')[2,line.split(' ').size-1].join(' ')
             output[section_type][section_name]['monitoring mode'] = value
        when /^permission/
             value = line.split(' ')[1,line.split(' ').size-1].join(' ')
             output[section_type][section_name]['permission'] = value
        when /^on reboot/
             value = line.split(' ')[2,line.split(' ').size-1].join(' ')
             output[section_type][section_name]['on reboot'] = value
        when /^uid/
             value = line.split(' ')[1,line.split(' ').size-1].join(' ')
             output[section_type][section_name]['uid'] = value
        when /^gid/
             value = line.split(' ')[1,line.split(' ').size-1].join(' ')
             output[section_type][section_name]['gid'] = value
        when /^size/
             value = line.split(' ')[1,line.split(' ').size-1].join(' ')
             output[section_type][section_name]['size'] = value
        when /^access timestamp/
             value = line.split(' ')[2,line.split(' ').size-1].join(' ')
             output[section_type][section_name]['access timestamp'] = value
        when /^change timestamp/
             value = line.split(' ')[2,line.split(' ').size-1].join(' ')
             output[section_type][section_name]['change timestamp'] = value
        when /^modify timestamp/
             value = line.split(' ')[2,line.split(' ').size-1].join(' ')
             output[section_type][section_name]['modify timestamp'] = value
        when /^data collected/
             value = line.split(' ')[2,line.split(' ').size-1].join(' ')
             output[section_type][section_name]['data collected'] = value
        when /^uptime/
             value = line.split(' ')[1,line.split(' ').size-1].join(' ')
             output[section_type][section_name]['uptime'] = value
        when /^threads/
             value = line.split(' ')[1,line.split(' ').size-1].join(' ')
             output[section_type][section_name]['threads'] = value
        when /^cpu total/
             value = line.split(' ')[2,line.split(' ').size-1].join(' ')
             output[section_type][section_name]['cpu total'] = value
        when /^memory total/
             value = line.split(' ')[2,line.split(' ').size-1].join(' ')
             output[section_type][section_name]['memory total'] = value
        when /^cpu/
             value = line.split(' ')[1,line.split(' ').size-1].join(' ')
             output[section_type][section_name]['cpu'] = value
        when /^memory/
             value = line.split(' ')[1,line.split(' ').size-1].join(' ')
             output[section_type][section_name]['memory'] = value
        when /^disk read/
             value = line.split(' ')[2,line.split(' ').size-1].join(' ')
             output[section_type][section_name]['disk read'] = value
        when /^disk write/
             value = line.split(' ')[2,line.split(' ').size-1].join(' ')
             output[section_type][section_name]['disk write'] = value
        end
      end
      @monit_internal_status = output
    end

    def self.index()
      self.get_status
      self.internal
      return JSON.generate(@monit_internal_status)
    end

    def self.raw
      self.get_status
      return @monit_raw_status
    end

    def self.pp
      self.get_status
      self.internal
      return JSON.pretty_generate(@monit_internal_status)
    end

    def self.get_status
      @monit_raw_status = `/usr/bin/monit status`
      @run_success = $?.success?
    end

   def self.run_success?
     return @run_success
   end

  end
end

start_webrick { | server |
  WEBrick::Daemon.start
  server.mount('/', RestServlet)
}
