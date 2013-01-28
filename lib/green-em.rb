require 'green'
class Green
  module EM
    extend self
    def sync(deferrable, params = {})
      g = Green.current
      deferrable.callback { |*args| g.switch(*get_args(args, params[:errback_args])) }
      deferrable.errback { |*args| g.throw(get_args(args, params[:errback_args]).first) }
      Green.hub.wait { deferrable.green_cancel }
    end

    def get_args(args, proc_args)
      case proc_args
      when Proc
        proc.call(*args)
      when nil
        args
      else
        proc_args
      end
    end

  end
end
