# frozen_string_literal: true

class PinboardBreadcrumbsPresenter
  def initialize(breadcrumbs, &thread_proc)
    @breadcrumbs = breadcrumbs
    @thread_proc = thread_proc
  end

  def for_list
    @breadcrumbs
  end

  def for_thread(thread)
    @thread_proc.call(@breadcrumbs, thread)
  end
end
