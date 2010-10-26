module Sprinkle
  module Verifiers
    # = Directory Verifier
    #
    # Defines a verify which can be used to test the existence of a 
    # directory.
    module Directory
      Sprinkle::Verify.register(Sprinkle::Verifiers::Directory)
      
      # Tests that the directory <tt>dir</tt> exists.
      def has_directory(dir)
        @commands << "test -d #{dir}"
      end
      alias_method :has_directory?, :has_directory
      alias_method :has_dir, :has_directory
      alias_method :has_dir?, :has_directory

    end
  end
end
