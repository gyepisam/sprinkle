module Sprinkle
  module Installers
    # Beware, strange "installer" coming your way.
    #
    # = Text configuration installer
    #
    # This installer pushes simple configuration into a file.
    # 
    # == Example Usage
    #
    # Installing magic_beans into apache2.conf
    #
    #   package :magic_beans do
    #     push_text 'magic_beans', '/etc/apache2/apache2.conf'
    #   end
    #
    # If you user has access to 'sudo' and theres a file that requires
    # priveledges, you can pass :sudo => true 
    #
    #   package :magic_beans do
    #     push_text 'magic_beans', '/etc/apache2/apache2.conf', :sudo => true
    #   end
    #
    # A special verify step exists for this very installer
    # its known as file_contains, it will test that a file indeed
    # contains a substring that you send it.
    # Using the :auto_verify => true option will trigger this verify step.
    #
    #
    #   package :magic_beans do
    #     push_text 'magic_beans', '/etc/apache2/apache2.conf', :auto_verify => true
    #   end
    #
    # is then the same as saying
    #
    #   package :magic_beans do
    #     push_text 'magic_beans', '/etc/apache2/apache2.conf'
    #     verify { file_contains '/etc/apache2/apache2.conf', 'magic_beans' }
    #   end

    class PushText < Installer
      attr_accessor :text, :path #:nodoc:

      def initialize(parent, text, path, options={}, &block) #:nodoc:
        super parent, options, &block
        @text = text
        @path = path

        if options[:auto_verify]
          verify { file_contains path, text }
        end
      end

      protected

        def install_commands #:nodoc:
          # use fully qualified path to avoid shell builtin echo. /bin/sh builtin echo not support the -e option
          "/bin/echo -e '#{@text.gsub("'", "'\\\\''").gsub("\n", '\n')}' |#{'sudo ' if option?(:sudo)}tee -a #{@path}"
        end

    end
  end
end
