module Sprinkle
  # = Packages
  #
  # A package defines one or more things to provision onto the server.
  # There is a lot of flexibility in a way a package is defined but
  # let me give you a basic example:
  #
  #   package :ruby do
  #     description 'Ruby MRI'
  #     version '1.8.6'
  #     apt 'ruby'
  #
  #     verify { has_executable 'ruby' }
  #   end
  #
  # The above would define a package named 'ruby' and give it a description
  # and explicitly say its version. It is installed via apt and to verify
  # the installation was successful sprinkle will check for the executable
  # 'ruby' being availble. Pretty simple, right?
  #
  # <b>Note:</b> Defining a package does not INSTALL it. To install a
  # package, you must require it in a Sprinkle::Policy block. 
  #
  # == Pre-Requirements
  #
  # Most packages have some sort of pre-requisites in order to be installed.
  # Sprinkle allows you to define the requirements of the package, which
  # will be installed before the package itself. An example below:
  #
  #   package :rubygems do
  #     source 'http://rubyforge.org/rubygems.tgz'
  #     requires :ruby
  #   end
  #
  # In this case, when rubygems is being installed, Sprinkle will first
  # provision the server with Ruby to make sure the requirements are met.
  # In turn, if ruby has requirements, it installs those first, and so on.
  #
  # == Verifications
  #
  # Most of the time its important to know whether the software you're 
  # attempting to install was installed successfully or not. For this,
  # Sprinkle provides verifications. Verifications are one or more blocks
  # which define rules with which Sprinkle can check if it installed
  # the package successfully. If these verification blocks fail, then 
  # Sprinkle will gracefully stop the entire process. An example below:
  #
  #   package :rubygems do
  #     source 'http://rubyforge.org/rubygems.tgz'
  #     requires :ruby
  #
  #     verify { has_executable 'gem' }
  #   end
  #
  # In addition to verifying an installation was successfully, by default
  # Sprinkle runs these verifications <em>before</em> the installation to
  # check if the package is already installed. If the verifications pass
  # before installing the package, it skips the package. To override this
  # behavior, set the -f flag on the sprinkle script or set the
  # :force option to true in Sprinkle::OPTIONS
  #
  # Note that apt packages are automatically verified with a block like:
  # 
  #  verify { has_apt? PACKAGE_NAME }
  #
  # where PACKAGE_NAME is the name of the apt package.
  #
  # For more information on verifications and to see all the available
  # verifications, see Sprinkle::Verify
  #
  # == Virtual Packages
  #
  # Sometimes, there are multiple packages available for a single task. An
  # example is a database package. It can contain mySQL, postgres, or sqlite!
  # This is where virtual packages come in handy. They are defined as follows:
  #
  #   package :sqlite3, :provides => :database do
  #     apt 'sqlite3'
  #   end
  #
  # The :provides option allows you to reference this package either by :sqlite3
  # or by :database. But whereas the package name is unique, multiple packages may
  # share the same provision. If this is the case, when running Sprinkle, the 
  # script will ask you which provision you want to install. At this time, you
  # can only install one. 
  #
  # == Configurations
  #
  # Rather than using the transfer command, it may be more convenient to list
  # the configuration files associated with a package, using the configuration
  # command.
  #
  # configuration %w(/file/path/1 /file/path/2), :prefix => 'source/base/dir'
  #
  # The files will be verified for existence and transfered if necessary.
  #
  # == Meta-Packages
  #
  # A package doesn't require an installer. If you want to define a package which
  # merely encompasses other packages, that is fine too. Example:
  #
  #   package :meta do
  #     requires :magic_beans
  #     requires :magic_sauce
  #   end
  #
  #--
  # FIXME: Should probably document recommendations.
  #++
  module Package
    PACKAGES = {}

    def package(name, metadata = {}, &block)
      package = Package.new(name, metadata, &block)
      PACKAGES[name] = package

      if package.provides
        (PACKAGES[package.provides] ||= []) << package
      end

      package
    end

    class Package #:nodoc:
      include ArbitraryOptions
      attr_accessor :name, :provides, :installers, :dependencies, :recommends, :verifications

      def initialize(name, metadata = {}, &block)
        raise 'No package name supplied' unless name

        @name = name
        @provides = metadata[:provides]
        @dependencies = []
        @recommends = []
        @optional = []
        @verifications = []
        @installers = []
        self.instance_eval(&block)
      end

      def freebsd_pkg(*names, &block)
        @installers << Sprinkle::Installers::FreebsdPkg.new(self, *names, &block)
      end
      
      def freebsd_portinstall(port, &block)
        @installers << Sprinkle::Installers::FreebsdPortinstall.new(self, port, &block)
      end

      def openbsd_pkg(*names, &block)
        @installers << Sprinkle::Installers::OpenbsdPkg.new(self, *names, &block)
      end
      
      def opensolaris_pkg(*names, &block)
        @installers << Sprinkle::Installers::OpensolarisPkg.new(self, *names, &block)
      end
      
      def bsd_port(port, &block)
        @installers << Sprinkle::Installers::BsdPort.new(self, port, &block)
      end
      
      def mac_port(port, &block)
        @installers << Sprinkle::Installers::MacPort.new(self, port, &block)
      end

      def apt(*names, &block)
        @installers << Sprinkle::Installers::Apt.new(self, *names, &block)
      end

      def deb(*names, &block)
        @installers << Sprinkle::Installers::Deb.new(self, *names, &block)
      end

      def rpm(*names, &block)
        @installers << Sprinkle::Installers::Rpm.new(self, *names, &block)
      end

      def yum(*names, &block)
        @installers << Sprinkle::Installers::Yum.new(self, *names, &block)
      end

      def gem(name, options = {}, &block)
        @recommends << :rubygems
        @installers << Sprinkle::Installers::Gem.new(self, name, options, &block)
      end

      def source(source, options = {}, &block)
        @recommends << :build_essential # Ubuntu/Debian
        @installers << Sprinkle::Installers::Source.new(self, source, options, &block)
      end
      
      def binary(source, options = {}, &block)
        @installers << Sprinkle::Installers::Binary.new(self, source, options, &block)
      end
      
      def rake(name, options = {}, &block)
        @installers << Sprinkle::Installers::Rake.new(self, name, options, &block)
      end    
      
      def noop(&block)
        @installers << Sprinkle::Installers::Noop.new(self, name, options, &block)
      end
      
      def push_text(text, path, options = {}, &block)
        @installers << Sprinkle::Installers::PushText.new(self, text, path, options, &block)
      end

      def transfer(source, destination, options = {}, &block)
        @installers << Sprinkle::Installers::Transfer.new(self, source, destination, options, &block)
      end

      # Always renders always creates parent directories.
      def template(source, options = {}, &block)
        destination = Sprinkle.extract_destination(source) 
        source = Sprinkle.prefix_config_dir(source)
        transfer(source, destination, options.merge(:render => true, :recursive => false, :mkdir => true), &block)
      end

      def verify(description = '', &block)
        @verifications << Sprinkle::Verify.new(self, description, &block)
      end  

      def configuration(*files, &block)
        
        files = files.flatten

        options = if files.last.is_a?(Hash)
                    files.pop
                  else
                    {}
                  end

        files.each do |file|
          source_file = Sprinkle.prefix_config_dir(file)
          destination_file = Sprinkle.extract_destination(file)
          @installers << Sprinkle::Installers::Transfer.new(self,
                                                            source_file,
                                                            destination_file,
                                                            options.update(:mkdir => true), &block)

          verify("File exists/checksum #{destination_file}") do
            checksum_match?(source_file, destination_file)
          end
        end
      end

      alias_method :files, :configuration

      # Include all files in specified directories or files.
      def config_dir(*paths, &block)
        require 'find'
        
        files = []

        Find.find(*paths.flatten.map { |path| Sprinkle.prefix_config_dir(path) }) do |path|
          next if Sprinkle.excludable_file?(path)
          if File.file?(path)
            files << path.gsub(/^#{Sprinkle::OPTIONS[:config_dir]}/, '')
          end
        end

        configuration(*files, &block)
      end

      # Given a list of apt package names, create packages and require them
      # This is called in the context of a package that requires a list of
      # other packages that don't need special handling.
      # The dependent packages do not need to be manually defined
      def require_apt (*names)
        package_names = names.flatten.map do |apt_name|
          package_name = ['apt_package', apt_name.gsub(/\W/, '_')].join('_').to_sym
          package package_name do
            apt apt_name
          end
          package_name
        end
        requires package_names
      end

      # See comments about apt packages above, but applies to gem packages.
      def require_gem(*names)
        gem_names = names.flatten.map do |gem_name|
          package_name = ['gem_package', gem_name.gsub(/\W/, '_')].join('_').to_sym
          package package_name do
            gem gem_name
          end
          package_name
        end
        requires gem_names
      end

      
      def process(deployment, roles)
        return if meta_package?

        # Run a pre-test to see if the software is already installed. If so,
        # we can skip it, unless we have the force option turned on!
        unless @verifications.empty? || Sprinkle::OPTIONS[:force]
          begin
            process_verifications(deployment, roles, true)
            
            logger.info "--> #{self.name} already installed for roles: #{roles}"
            return
          rescue Sprinkle::VerificationFailed => e
            # Continue
          end
        end

        @installers.each do |installer|
          installer.defaults(deployment)
          installer.process(roles)
        end
        
        process_verifications(deployment, roles)
      end
      
      def process_verifications(deployment, roles, pre = false)
        return if @verifications.blank?
        
        if pre
          logger.info "--> Checking if #{self.name} is already installed for roles: #{roles}"
        else
          logger.info "--> Verifying #{self.name} was properly installed for roles: #{roles}"
        end
        
        @verifications.each do |v|
          v.defaults(deployment)
          v.process(roles)
        end
      end

      def requires(*packages)
        @dependencies << packages
        @dependencies.flatten!
      end

      def recommends(*packages)
        @recommends << packages
        @recommends.flatten!
      end

      def optional(*packages)
        @optional << packages
        @optional.flatten!
      end

      def tree(depth = 1, &block)
        packages = []

        @recommends.each do |dep|
          package = PACKAGES[dep]
          next unless package # skip missing recommended packages as they're allowed to not exist
          block.call(self, package, depth) if block
          packages << package.tree(depth + 1, &block)
        end

        @dependencies.each do |dep|
          package = PACKAGES[dep]
          package = select_package(dep, package) if package.is_a? Array
          
          raise "Package definition not found for key: #{dep}" unless package
          block.call(self, package, depth) if block
          packages << package.tree(depth + 1, &block)
        end

        packages << self

        @optional.each do |dep|
          package = PACKAGES[dep]
          next unless package # skip missing optional packages as they're allow to not exist
          block.call(self, package, depth) if block
          packages << package.tree(depth + 1, &block)
        end

        packages
      end

      def to_s; @name; end

      private

        def select_package(name, packages)
          if packages.size <= 1
            package = packages.first
          else
            package = choose do |menu|
              menu.prompt = "Multiple choices exist for virtual package #{name}"
              menu.choices(*packages.collect(&:to_s))
            end
            package = Sprinkle::Package::PACKAGES[package]
          end

          cloud_info "Selecting #{package.to_s} for virtual package #{name}"

          package
        end

        def meta_package?
          @installers.blank?
        end
    end
  end
end
