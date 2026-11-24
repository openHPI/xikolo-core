# frozen_string_literal: true

# @label Channel header
# Uses in-memory channel data and the existing unsigned demo streams, without Bunny credentials.
class Home::Channel::HeaderPreview < ViewComponent::Preview
  Channel = Struct.new(:title, :code, :subtitle, :stage_visual_url, :mobile_visual_url, :shorts, keyword_init: true)
  private_constant :Channel

  SUBTITLE = <<~TEXT.squish
    Du willst die Technik von morgen mitgestalten? Schnuppere in die Informatik rein
    und finde heraus, ob ein Studium am HPI dein nächster Schritt ist.
  TEXT
  private_constant :SUBTITLE

  def title_only
    render_header(subtitle: nil)
  end

  def with_subtitle
    render_header
  end

  def with_visual
    render_header(stage_visual_url: image_path('defaults/course.png'), mobile_visual_url: image_path('about/hero.webp'))
  end

  def visual_without_subtitle
    render_header(subtitle: nil, stage_visual_url: image_path('defaults/course.png'))
  end

  def mobile_visual_only
    render_header(mobile_visual_url: image_path('about/hero.webp'))
  end

  def with_one_short
    render_header(shorts: Shorts::DemoMedia.items.first(1))
  end

  def with_two_shorts
    render_header(shorts: Shorts::DemoMedia.items.first(2))
  end

  def with_several_shorts
    render_header(shorts: Shorts::DemoMedia.items)
  end

  # Shorts take precedence over an uploaded visual on the channel page.
  def shorts_with_visual
    render_header(shorts: Shorts::DemoMedia.items, stage_visual_url: image_path('defaults/course.png'))
  end

  def with_long_text
    render_header(
      title: 'Dein Einstieg in die Informatik: Entdecke neue Ideen und finde deinen Weg zum Studium am HPI',
      subtitle: 'Probiere aus, wie man Software entwickelt, Daten auswertet und mit Informatik echte Probleme löst. ' \
                'So findest du heraus, was dir Spaß macht und ob ein Informatikstudium am HPI zu dir passt.',
      stage_visual_url: image_path('defaults/course.png')
    )
  end

  private

  def render_header(**attributes)
    channel = Channel.new(title: 'Informatik studieren am HPI', code: 'study-at-hpi', subtitle: SUBTITLE,
      shorts: [], **attributes)

    render_with_template(template: 'home/channel/header_preview/header', locals: {channel:})
  end

  def image_path(name)
    ActionController::Base.helpers.image_path(name)
  end
end
