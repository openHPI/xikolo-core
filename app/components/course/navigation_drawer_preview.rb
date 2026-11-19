# frozen_string_literal: true

module Course
  class NavigationDrawerPreview < ViewComponent::Preview
    def default
      render ::Course::NavigationDrawer.new do |drawer|
        drawer.with_main_content do
          <<~HTML.html_safe
            <main class="p-6">
              <h1 class="text-2xl font-bold">Introduction to Quantum Computing</h1>
              <p class="mt-4">This is the main course content.</p>
            </main>
          HTML
        end

        drawer.with_overview_link do
          <<~HTML.html_safe
            <a href="#" class="x-btn x-btn-neutral x-btn-outline w-full rounded-2xl">Go to overview</a>
          HTML
        end
        drawer.with_navigation(component: table_of_contents)
      end
    end

    private

    def table_of_contents
      Navigation::TableOfContents.new.tap do |toc|
        toc.with_section(text: 'Week 1: Qubits', link: {href: '#'})
        toc.with_section(text: 'Week 2: Quantum Gates', link: {href: '#'})
        toc.with_section(text: 'Week 3: Algorithms', link: {href: '#'})
      end
    end
  end
end
