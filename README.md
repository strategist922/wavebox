# WaveBox

A redis-based notification system

## Example

    require 'wave_box'

    class User
      include ::WaveBox::GenerateWave
      include ::WaveBox::ReceiveWave

      can_generate_wave :name => "message",
                        :redis => :wave_redis_instance,
                        :expire => 60 * 60 * 24 * 7, # One week
                        :max_size => 20,
                        :id => :wave_box_id

      can_receive_wave :name => "message",
                       :redis => :wave_redis_instance,
                       :expire => 60 * 60 * 24 * 7, # One week
                       :max_size => 20,
                       :id => :wave_box_id

      def wave_redis_instance
        Redis.new # return a redis instance
      end

      def wave_box_id
        object_id
      end
    end

    sender = User.new
    => #<User:0x007f85631b9a50>
    receiver = User.new
    => #<User:0x007f85631cf940>

    # Send a wave from sender to receiver
    sender.generate_message "hi", receiver

    # Find all message waves in sender's outbox
    sender.generated_message_after(0)
    => ["hi"]
    # Find all message waves in receiver's inbox
    receiver.received_message_after(0)
    => ["hi"]

## License

Ruby on Rails is released under the {MIT License}[http://www.opensource.org/licenses/MIT].