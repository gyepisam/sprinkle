module Sprinkle
  module Verifiers
    # = Ruby Verifiers
    #
    # The verifiers in this module are ruby specific. 
    module Ruby
      Sprinkle::Verify.register(Sprinkle::Verifiers::Ruby)
      
      # Checks if ruby can require the <tt>files</tt> given. <tt>rubygems</tt>
      # is always included first.
      def ruby_can_load(*files)
        # Always include rubygems first
        files = files.unshift('rubygems').collect { |x| "require '#{x}'" }
        
        @commands << "ruby -e \"#{files.join(';')}\""
      end
      
      # check for gem existence by querying
      def has_gem(name, version=nil)
        @commands << ("expr match $(gem query -q -l -i -n #{name}%s) true > /dev/null" % if version then " --version #{version}" end)
      end

      alias_method :has_gem?, :has_gem
    end
  end
end
