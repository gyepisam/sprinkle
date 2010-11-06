require 'rubygems'
require 'active_support'

# Use active supports auto load mechanism
ActiveSupport::Dependencies.load_paths << File.dirname(__FILE__)

# Configure active support to log auto-loading of dependencies
#ActiveSupport::Dependencies::RAILS_DEFAULT_LOGGER = Logger.new($stdout)
#ActiveSupport::Dependencies.log_activity = true

# Load up extensions to existing classes
Dir[File.dirname(__FILE__) + '/sprinkle/extensions/*.rb'].each { |e| require e }
# Load up the verifiers so they can register themselves
Dir[File.dirname(__FILE__) + '/sprinkle/verifiers/*.rb'].each { |e| require e }


# Configuration options
module Sprinkle
  OPTIONS = { :testing => false, :verbose => false, :force => false }

  # Given a path, prepends the config_dir to it, if necessary and possible.
  def self.prefix_config_dir(path)
    if OPTIONS.key?(:config_dir) && !path.start_with?(OPTIONS[:config_dir])
      File.join(OPTIONS[:config_dir], path)
    else
      path
    end
  end

  # Convert file path like mysql/./etc/mysql/xyz.conf to /etc/mysql/xyz.conf
  # Given a file path with an '/./', returns the part after the '/.' part
  # otherwise returns the path.
  # This mechanism allows local files to be rooted differently from the remote version.
  def self.extract_destination(path)
    %r!/\.(/.+)!.match(path) ? $1 : path
  end

  # ignore the following file
  # '.' or '..' - directory aliases
  # and any files that rsync version 3.0.7 with the -C flag
  # would also ignore.
  def self.excludable_file?(name)
    if name =~ /^\.\.?$/
      return true 
    else
      # list copied from rsync man page
      patterns = %w(RCS  SCCS  CVS  CVS.adm   RCSLOG   cvslog.*   tags   TAGS
                  .make.state  .nse_depinfo *~ #* .#* ,* _$* *$ *.old *.bak
                  *.BAK *.orig *.rej .del-* *.a *.olb *.o *.obj *.so  *.exe
                  *.Z *.elc *.ln core .svn/ .git/ .bzr/)

      patterns << '.swp'

      return(patterns.any? { |pattern| File.fnmatch?(pattern, name) })
    end
  end
end




# Object is extended to give the package, policy, and deployment methods. To
# read about each method, see the corresponding module which is included.
#--
# Define a logging target and understand packages, policies and deployment DSL
#++
class Object
  include Sprinkle::Package, Sprinkle::Policy, Sprinkle::Deployment

  def logger # :nodoc:
    @@__log__ ||= ActiveSupport::BufferedLogger.new($stdout, ActiveSupport::BufferedLogger::Severity::INFO)
  end
end
