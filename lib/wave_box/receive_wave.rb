module WaveBox
  module ReceiveWave
    def method_missing(method, *args, &block)
      if method.to_s =~ /received_(\w+)_after/
        received_after( $1, *args )
      elsif method.to_s =~ /receive_(\w+)/
        receive( $1, *args)
      else
        super
      end
    end

    def receive(name, wave, time = Time.now)
      send("#{name}_inbox").push(wave, time)
    end

    def received_after(name, time)
      send("#{name}_inbox").after(time)
    end

    module ClassMethods
      def can_receive_wave(config)
        raise ArgumentError, "Missing redis config" unless config[:redis]
        raise ArgumentError, "Missing id lambda" unless config[:id]
        raise ArgumentError, "Missing wave name" unless config[:name]

        name = config[:name]

        [:expire, :max_size, :encode].each do |c|
          define_method "#{name}_inbox_#{c}" do config[c] end
        end

        if config[:redis].is_a? Symbol
          class_eval <<-RUBY
            def #{name}_inbox_redis_instance
              send("#{config[:redis]}")
            end
          RUBY
        else
          define_method "#{name}_inbox_redis_instance" do config[:redis] end
        end

        if config[:id].is_a? Symbol
          class_eval <<-RUBY
            def #{name}_inbox_id
              send("#{config[:id]}")
            end
          RUBY
        else
          define_method "#{name}_inbox_id" do config[:redis] end
        end

        define_method "#{name}_inbox_key" do "wave:#{name}:inbox:#{send("#{name}_inbox_id")}" end

        class_eval <<-RUBY
          def #{name}_inbox
            @#{name}_inbox ||= WaveBox::Box.new({
                                  :redis => #{name}_inbox_redis_instance,
                                  :key => #{name}_inbox_key,
                                  :encode => #{name}_inbox_encode,
                                  :expire => #{name}_inbox_expire,
                                  :max_size => #{name}_inbox_max_size})
          end
        RUBY
      end
    end

    def self.included(host)
      host.extend ClassMethods
    end

  end
end
