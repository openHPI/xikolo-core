# frozen_string_literal: true

# Platform-wide content

Page.create!(
  name: 'about',
  locale: 'en',
  title: 'About Xikolo',
  text: <<~MD.strip
    # About Xikolo

    Xikolo is the software behind openHPI and other platforms.
    It is being developed in Potsdam, Germany.
  MD
)

poll1 = Poll::Poll.create!(
  question: 'Where did you hear first about our platform?',
  start_at: 2.weeks.ago,
  end_at: 2.weeks.from_now,
  show_intermediate_results: false
)
poll1.options.create!(text: 'From a friend/colleague', position: 1)
poll1.options.create!(text: 'Social Media', position: 2)
poll1.options.create!(text: 'Press', position: 3)
poll1.options.create!(text: 'A very long answer option that needs a line break (to see if the alignment still works)', position: 4)
poll1.options.create!(text: 'Google', position: 5)
poll1.options.create!(text: 'MOOC List', position: 6)

poll2 = Poll::Poll.create!(
  question: 'Which of these course elements do you use regularly?',
  start_at: 1.week.ago,
  end_at: 3.weeks.from_now,
  allow_multiple_choices: true
)
poll2.options.create!(text: 'Videos', position: 1)
poll2.options.create!(text: 'Self-tests', position: 2)
poll2.options.create!(text: 'Discussion forum', position: 3)
poll2.options.create!(text: 'Quiz recap', position: 4)
poll2.options.create!(text: 'Reading material', position: 5)
poll2.options.create!(text: 'Slides', position: 6)

poll3 = Poll::Poll.create!(
  question: 'Who killed Mr. Burns?',
  start_at: 1.week.ago,
  end_at: 3.weeks.from_now
)
poll3.options.create!(text: 'Bart Simpson', position: 1)
poll3.options.create!(text: 'Homer Simpson', position: 2)
poll3.options.create!(text: 'Marge Simpson', position: 3)
poll3.options.create!(text: 'Maggie Simpson', position: 4)
poll3.options.create!(text: 'Barney Gumble', position: 5)
poll3.options.create!(text: 'Whalen Smithers', position: 6)
