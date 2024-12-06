# frozen_string_literal: true

FactoryBot.define do
  factory :news_translation do
    # News factory must not run its own hook adding translations,
    # otherwise are are invalid
    association :news, translations: false

    title  { 'Save the Date: Lorem ipsum' }
    locale { 'en' }

    text do
      <<~TEXT
        Lorem ipsum dolor sit amet, consectetur adipiscing elit.
        Nullam dignissim efficitur nisi sed ultricies.
        Aenean sit amet metus et nisi auctor feugiat vel ut elit.
        Cras semper sed urna non pellentesque.
        Aliquam et velit non libero blandit pharetra vel vitae elit.
        Vestibulum ante ipsum primis in faucibus orci luctus et
        ultrices posuere cubilia curae; Suspendisse potenti.
        In eu diam nec lectus rhoncus vehicula eu sed felis.
        Etiam maximus aliquam cursus. Etiam ac tellus sapien.
        Maecenas vel porttitor elit. Cras et elit ut ipsum
        aliquam pretium ut vel est. Vivamus pharetra arcu
        vitae felis condimentum, eget dictum lectus cursus.
        Aenean lobortis sed nisi sit amet ultricies.
        Nulla a arcu ullamcorper, finibus metus id, luctus mauris.
        Mauris sed justo dui. Nunc facilisis, purus id dictum tristique,
        velit est lacinia purus, vitae luctus enim sapien tincidunt ante.
      TEXT
    end
  end
end
