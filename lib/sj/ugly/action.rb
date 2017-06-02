module SJ
  module Ugly
    module Action
      # n.b. Struct is implemented in C, and its implementation does not allow
      #      emptiness, so we patch all methods to simulate it instead.
      Unit = Struct.new(:_) do
        def ==(other);   Unit === other; end
        def [];                     nil; end
        def dig;                    nil; end
        def each;                  self; end
        def each_pair;             self; end
        def eql?(other); Unit === other; end
        def inspect;             "Unit"; end
        def length;                   0; end
        def select;                  []; end
        def size;                     0; end
        def to_a;                    []; end
        def to_h;                    {}; end
        def to_s;                "Unit"; end
        def members;                 []; end
        def values;                  []; end
        def values_at(*selector);    []; end
      end.new

      def self.included(receiver)
        receiver.extend(ClassMethods)
        receiver.send(:include, InstanceMethods)
      end

      module ClassMethods
        def mk(**kwargs)
          self.new(**kwargs)
        end
      end

      module InstanceMethods
        def call!(&closure)
          val = self.send(:invoke!)
          yield val if block_given?
        end

        private

        def validates(&block)
          errors = []
          yield errors if block_given?
          unless errors.empty?
            msg = errors.join('; ')
            raise ArgumentError.new(msg)
          end
        end
      end
    end
  end
end
