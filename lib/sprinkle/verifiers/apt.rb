module Sprinkle
  module Verifiers
    # = Apt Verifier
    #
    # Contains a verifier to check the existence of an Apt package.
    # Accepts one or more apt package names. 

    # == Example Usage
    #
    #   verify { has_apt 'ntp' }
    #
    #   verify { has_apt 'ntp', 'ntp-date' }
    # 
    # Synonyms: has_apt?, has_apts, has_apts?
    #
    module Apt
      Sprinkle::Verify.register(Sprinkle::Verifiers::Apt)

      # Checks to make sure <tt>package</tt> exists in the apt database on the remote server.
      def has_apt(*packages)
        [packages].flatten.each do |package|
          @commands << %Q!test "$(dpkg-query -W -f='${Status}' #{package} 2> /dev/null)" = 'install ok installed'!
        end
      end
      make_synonyms(:has_apt, :has_apt?, :has_apts, :has_apts?)
    end
  end
end
