# frozen_string_literal: true

# include ReviewHelper
#
#
# assessment = PeerAssessment.new(id: '00000001-5300-4444-9999-000000000003',
#                                 title: 'Peer Assessment With Two Optional Steps',
#                                 course_id: '00000001-3300-4444-9999-000000000001',
#                                 item_id: '00000003-3100-4444-9999-000000000018',
#                                 allowed_attachments: 2,
#                                 allowed_file_types: '.pdf, .txt, .zip, .png, .jpeg, .jpg',
#                                 max_file_size: 6,
#                                 attachments: ['00000001-4000-4444-9999-000000000995', '00000001-4000-4444-9999-000000000996'],
#                                 instructions: 'Infelix varias, illud et tuentur laboras illi adverso concussit mente haec dis
# erat metallis anus Aeas est. Cinyphiumque haec Hiberis honore flammasque [me
# canis ad](http://tumblr.com/) mersit flamma, carebat vix.
#
# Crabronum aditus! Primus cum videt, palmite cura, haec, exhausto. Placet ingens,
# redde saeva. Pondere dum quod ista conditor, sit una ignesque quae tenuissima
# enim. **Mea** illa illa forma, veluti Gorgone sed videt erat.
#
# > Deae has mitia servaverat pudorem urbe iuris tempora et litore. *Dracones
# > laudare* quid ova manu regno, tu me dolor.
#
# Praeside in plangoris *pestifera*, patris alis ignibus ossa noctem invocat ab.
# Laeva est [dea genitore](http://zeus.ugent.be/) cornibus ut amor.
#
# Unam patuit, nec amor quoniam Alcyone paravi, Letoia parte nimis a parabat
# **maduerunt** conceptaque mare. Haud nec et cupio citharae exul: Scylla auro
# urnis lacusque. Dixerat horriferum ultima aequore: cepit moly quis robore,
# abluit.
#
# Intremuit et consule exclamat. Edaci te dea,
# [iter](http://www.wedrinkwater.com/) repertis Helicen dryades. Illic nubes
# verbis manu, nascitur, ni laetus. Tamen conprendere omnes letum alii nec
# Placatus arma adfata elususque. Puerile et [dura](http://imgur.com/)!
#
# [dea genitore]: http://zeus.ugent.be/
# [dura]: http://imgur.com/
# [harenis]: http://textfromdog.tumblr.com/
# [iter]: http://www.wedrinkwater.com/
# [me canis ad]: http://tumblr.com/
# [primis]: http://www.lipsum.com/',
#                        resubmissions: 0,
#                        grading_hints: 'Lorem markdownum angusta, equorum tantum faciebant ignibus Acmona! Iove idem cum
# manus, in illud alitibus Daedalon famae. Toto voluit refert si arma sole pedes
# numero, aut. Clarus exitio in memor posuerunt oculi Iris pudorque et aequora
# muros [harenis](http://textfromdog.tumblr.com/), retinentibus.
#
# Sed humano sanguis cruento percussa. Senilis odoratas
# [primis](http://www.lipsum.com/) longa germanae ait. Cum suam exemplum parte
# debes temptare; solent ferunt culpam *vetustas audentem*. Mihi valles blanditur
# priorum. Sacerdos legitima mea, vincere nec suprema et talia, quod trepidumque
# usque exiguo, tamen unde et Ismenides minimas.',
#                        usage_disclaimer: 'I also acknowledge the [data usage disclaimer](http://imgur.com/).'
# )
#
# assessment.attachments_will_change!
# assessment.save!
#
#
# ### Steps ###
#
# AssignmentSubmission.create! id: '00000002-5300-4444-9999-000000000009',
#                              deadline: 1.weeks.from_now,
#                              peer_assessment: assessment,
#                              optional: false,
#                              position: 1
#
# training_step = Training.create! id: '00000002-5300-4444-9999-000000000010',
#                  deadline: 3.weeks.from_now,
#                  peer_assessment: assessment,
#                  optional: true,
#                  position: 2,
#                  open: false,
#                  required_reviews: 3
#
# PeerGrading.create! id: '00000002-5300-4444-9999-000000000011',
#                     deadline: 3.weeks.from_now,
#                     peer_assessment: assessment,
#                     optional: false,
#                     position: 3,
#                     required_reviews: 3,
#                     ai_hints: false
#
# SelfAssessment.create! id: '00000002-5300-4444-9999-000000000012',
#                        deadline: 3.weeks.from_now,
#                        peer_assessment: assessment,
#                        optional: true,
#                        position: 4
#
# ResultDiscussion.create! id: '00000002-5300-4444-9999-000000000013',
#                          deadline: 4.weeks.from_now,
#                          peer_assessment: assessment,
#                          optional: false,
#                          position: 5
#
#
# ### Rubrics ###
#
# rubrics = []
#
# rubrics << Rubric.create!(peer_assessment: assessment,
#                           title: 'Writing Style',
#                           hints: 'How does the vocabulary look like? Is it versatile?',
#                           position: 1,
#                           template: false)
#
# rubrics << Rubric.create!(peer_assessment: assessment,
#                           title: 'Correctness',
#                           hints: 'Be sensitive when it comes to the finer points of the usage of the protocol, like terminology, processes (like handshakes), etc.',
#                           position: 2,
#                           template: false)
#
#
#
# ### Rubric Options ###
#
# RubricOption.create! rubric: rubrics.first,
#                      description: 'Litte or no variation, repetitions',
#                      position: 0
#
# RubricOption.create! rubric: rubrics.first,
#                      description: 'Good usage out of a variety of words, but lacking on-point descriptions by paraphrazing.',
#                      position: 1
#
# RubricOption.create! rubric: rubrics.first,
#                      description: 'Well-rounded vocabulary and concise descriptions.',
#                      position: 2
#
# RubricOption.create! rubric: rubrics[1],
#                      description: 'Missing the essence of the TCP Handshake or severe mistakes with regard to the content',
#                      position: 0
#
# RubricOption.create! rubric: rubrics[1],
#                      description: 'Missing some of the important points (x, y, z), but correctly describing the core ideas.',
#                      position: 1
#
# RubricOption.create! rubric: rubrics[1],
#                      description: 'Comprehensible description of the handshake protocol, including a, b, c.',
#                      position: 2
#
#
#
# ### 50 JohnSmiths UserIDs with user additions ###
# training_pool = ResourcePool.find_by peer_assessment_id: assessment.id, purpose: 'training'
#
# user_ids = []
#
# 50.times do |i|
#   user_id = sprintf('00000001-3100-4444-9999-0000000%05d', i + 200) # We need deterministic ids to seed other services (file)
#   user_ids << user_id
#   ua = UserAddition.new user_id: user_id, coh_ack: true, peer_assessment_id: assessment.id
#   ua.save validate: false
#
#   s = Submission.create! id: sprintf('00000004-5300-4444-9999-0000000%05d', i + 200),
#                          peer_assessment: assessment,
#                          user_id: user_id,
#                          text: SecureRandom.hex,
#                          submitted: true,
#                          attachments: [sprintf('00000001-4000-4444-9999-0000000%05d', i + 200)]
#
#   s.handle_training_pool_entry if s
# end
#
#
# ### Training seeds ###
#
# training_pool = ResourcePool.find_by peer_assessment_id: assessment.id, purpose: 'training'
#
# ta_id = SecureRandom.uuid
#
# # 20 random training sample reviews
# 20.times do |i|
#   # New random sample
#   review = get_sample training_pool, training_step, ta_id
#
#   # Set contents
#   review.submitted = true
#   review.optionIDs_will_change!
#
#   # ...with random grading
#   chosen_options = []
#   rubrics.each do |rubric|
#     option = rubric.rubric_options.sample
#
#     review.optionIDs << option.id
#     chosen_options << option
#   end
#
#   review.text = "#{i}: #{chosen_options.map { |el| el.position }.join ', '}"
#   review.save!
# end
#
# ### Peer Grading Step ###
#
# # Open up the training process
# assessment.training_step.open = true
# assessment.training_step.save validate: false
#
# # Let the 50 users train three samples
# user_ids.each do |user_id|
#   3.times do
#     review = retrieve_student_training_sample(assessment.id, user_id).first
#
#     # Get valid rubrics
#     options = []
#     assessment.rubrics.each do |rubric|
#       options << rubric.rubric_options.sample.id
#     end
#
#     review.optionIDs = options
#     review.submitted = true
#     review.save!
#   end
# end
#
# # Advance all users to the peer grading step
# Submission.where(peer_assessment_id: assessment.id).each do |submission|
#   ua = UserAddition.find_by(user_id: submission.user_id)
#   ua.current_step = assessment.grading_step.id
#   ua.expertise = (1..4).to_a.sample
#   ua.save validate: false
#   submission.handle_grading_pool_entry
# end
