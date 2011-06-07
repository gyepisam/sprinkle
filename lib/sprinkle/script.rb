module Sprinkle
  # = Programmatically Run Sprinkle
  #
  # Sprinkle::Script gives you a way to programatically run a given
  # sprinkle script. 
  class Script
    # Run a given sprinkle script. This method is <b>blocking</b> so
    # it will not return until the sprinkling is complete or fails.
    #--
    # FIXME: Improve documentation, possibly notify user how to tell
    # if a sprinkling failed.
    #++
    def self.sprinkle(script, filename = '__SCRIPT__')
      powder = new
      powder.instance_variable_set('@filename', filename)
      powder.instance_eval script, filename
      powder.sprinkle
    end

    def sprinkle #:nodoc:
      @deployment.process if @deployment
    end

    # Auto require all packages in specified directory or default packages directory.
    def require_packages(basedir=Sprinkle::OPTIONS[:packages_dir])
      unless File.directory?(basedir)
        raise "require_packages: specified directory [#{basedir}] does not exist"
      end
      
      $: << basedir

      Dir.foreach(basedir) do |entry|
        if Sprinkle.excludable_file?(entry) 
          next
        else
          path = File.join(basedir, entry)
          if File.file?(path) && path.end_with?('.rb')
            require path
          elsif File.directory?(path)
            require_packages(path)
          end
        end
      end
    end
  end
end
