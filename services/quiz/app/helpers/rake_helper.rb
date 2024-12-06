# frozen_string_literal: true

module RakeHelper
  def init(procedure)
    @log = create_logger procedure unless @dry
    puts procedure
  end

  def inform(info)
    puts info
    @log.info info unless @dry
  end
end
