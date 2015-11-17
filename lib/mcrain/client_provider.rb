module Mcrain
  module ClientProvider

    def client
      @client ||= build_client
    end

    def build_client
      require client_require
      yield if block_given?
      client_class.new(*client_init_args)
    end

    def client_require
      raise NotImplementedError
    end

    def client_class
      raise NotImplementedError
    end

    def client_init_args
      raise NotImplementedError
    end

    def client_instantiation_script
      client
      "#{client_class.name}.new(*#{client_init_args.inspect})"
    end

    def client_script
      "require '#{client_require}'\nclient = #{client_instantiation_script}"
    end

  end
end
