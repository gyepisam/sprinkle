module Sprinkle
  module Verifiers
    # = File Verifier
    #
    # Contains verifiers to check for:
    #
    # The existence of a file.
    # 
    # == Example Usage
    #
    #   verify { has_file '/etc/apache2/apache2.conf' }
    #
    #   verify { file_contains '/etc/apache2/apache2.conf', 'mod_gzip'}
    #
    # Compare md5 checksums for local and remote files.
    #  
    # == Example Usage
    #
    #   verify { checksum_match? '/local/path/to/file' '/remote/path/to/file' }
    #
    module File
      Sprinkle::Verify.register(Sprinkle::Verifiers::File)
      
      # Checks to make sure <tt>path</tt> is a file on the remote server.
      def has_file(*paths)
        @commands.concat [paths].flatten.map { |path| "test -f #{path}" }
      end

      alias_method :has_file?, :has_file
      alias_method :has_files, :has_file
      alias_method :has_files?, :has_file
     
       
      def file_contains(path, text)
        @commands << "grep -q '#{text}' #{path}"
      end

      def checksum_match?(source, destination)
        checksum = `md5sum - < #{source}`
        @commands << "test -f #{destination} && (echo '#{checksum.chomp.gsub(/-/, destination)}' | md5sum -c --quiet --status -)"
      end
    end
  end
end
