# frozen_string_literal: true

module Navigation
  class TableOfContentsPreview < ViewComponent::Preview
    # Sections
    # ------------
    # Sections have different states based on the parameters passed to them.
    # The styles are similar to the `Navigation::Item` component.
    #
    # @display bg_color "#fafafa"
    def sections
      render Navigation::TableOfContents.new do |toc|
        toc.with_section(text: 'With link', link: {href: '/link'})
        toc.with_section(text: 'Without link but with a very long text that should be truncated')
        toc.with_section(text: 'Active', link: {href: '/active'}, active: true)
        toc.with_section(text: 'Locked, with access', icon: {code: 'lock'}, link: {href: '/locked'})
        toc.with_section(text: 'Locked, no access', locked: true, tooltip: 'Will be unlocked on Feb. 30th')
        toc.with_section(text: 'With tooltip', link: {href: '/tooltip'}, tooltip: 'This is a tooltip')
      end
    end

    # Units
    # ------------
    # Sections can have units.
    #
    # They should appear as a list of links.
    # When active, they have a bold font style.
    #
    # @display bg_color "#fafafa"
    def units
      render Navigation::TableOfContents.new do |toc|
        toc.with_section(text: 'First Section', link: {href: '/c1'})
        toc.with_section(text: 'Second Section with units, is active', link: {href: '/c2'}, active: true) do |section|
          section.with_segment_unit(text: '2.1. Introduction', link: {href: '/c2/u1'})
          section.with_segment_unit(text: '2.2. The second machine age', link: {href: '/c2/u2'}, active: true)
          section.with_segment_unit(text: '2.3. Homework', link: {href: '/c2/homework'})
          section.with_segment_unit(text: '2.4. It is never too late to reinvent the bicycle',
            link: {href: '/c2/forum'})
        end
        toc.with_section(text: 'Third Section', link: {href: '/c3'}, locked: true)
      end
    end

    # Subsections
    # ------------
    # Sections can hold more sections, called subsections.
    # Subsections can have units, just like Sections.
    #
    # @display bg_color "#fafafa"
    def subsections
      render Navigation::TableOfContents.new do |toc|
        toc.with_section(text: 'Week 1', link: {href: '/c1'})
        toc.with_section(text: 'Week 2', link: {href: '/c2'}, active: true) do |chapter|
          chapter.with_segment_section(text: 'Alternative 1', link: {href: '/c2/a1'})
          chapter.with_segment_section(text: 'Alternative 2', link: {href: '/c2/a3'}) do |sub|
            sub.with_segment_unit(text: 'Unit', link: {href: '/c2/a3/u1'})
            sub.with_segment_unit(text: 'Another unit long title', link: {href: '/c2/a3/u2'})
            sub.with_segment_unit(text: 'Locked', locked: true)
          end
        end
        toc.with_section(text: 'Week 3', link: {url: '/c3'}, locked: true)
      end
    end

    # Subsections with units
    # ------------
    #
    # A more complex example to showcase units mixed with subsections
    #
    # @display bg_color "#fafafa"
    def units_mixed_with_subsections
      render Navigation::TableOfContents.new do |toc|
        toc.with_section(text: '1. Section, no units, no sections, no cry', link: {href: '/c1'})
        toc.with_section(text: '2. Active section with units and sub sections', link: {href: '/c2'},
          active: true) do |section|
          section.with_segment_unit(text: '2.0.1 Unit', link: {href: '/c2/u1'})
          section.with_segment_unit(text: '2.0.2 Another Unit', link: {href: '/c2/u2'})
          section.with_segment_section(text: '2.1. A Section within the units with units',
            link: {href: '/c2/homework'}) do |subsection|
            subsection.with_segment_unit(text: '2.1.1. Subsection Unit', link: {href: '/c2/homework/1'})
          end
          section.with_segment_unit(text: '2.0.3 Another unit that comes after a section', link: {href: '/c2/forum'})
        end
        toc.with_section(text: '3. Just another section', link: {href: '/c3'})
        toc.with_section(text: '4. Just another section', link: {href: '/c3'})
      end
    end
  end
end
