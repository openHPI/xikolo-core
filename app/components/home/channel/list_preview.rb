# frozen_string_literal: true

class Home::Channel::ListPreview < ViewComponent::Preview
  # Mimics the parts of CourseService::Channel that the component relies on.
  Channel = Struct.new(:title, :code, :description, keyword_init: true)

  def default
    render(Home::Channel::List.new(items: items))
  end

  private

  def items
    [
      Channel.new(
        title: 'Get Social!',
        code: 'social',
        description: {
          'en' => 'Courses to connect, communicate and work with people',
          'de' => 'Kurse zum Netzwerken, Kommunizieren und Zusammenarbeiten',
        }
      ),
      Channel.new(
        title: 'Disease Outbreaks of the day',
        code: 'outbreak',
        description: {
          'en' => 'Stay informed about current disease outbreaks worldwide',
          'de' => 'Aktualitäten zu aktuellen Krankheitsausbrüchen weltweit',
        }
      ),
      Channel.new(
        title: 'GOARN',
        code: 'goarn',
        description: {
          'en' => 'Open resources for data and open government research',
          'de' => 'Offene Ressourcen für Daten- und Open-Government-Forschung',
        }
      ),
      Channel.new(
        title: 'Design Thinking',
        code: 'design',
        description: {
          'en' => 'Learn how to solve problems in a creative way',
          'de' => 'Lerne, wie du Probleme kreativ löst',
        }
      ),
    ]
  end
end
