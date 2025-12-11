# frozen_string_literal: true

module RakeHelper
  def init(procedure)
    @log = create_logger procedure unless @dry
    Rails.logger.debug procedure
  end

  def inform(info)
    Rails.logger.debug info
    @log.info info unless @dry
  end
end
