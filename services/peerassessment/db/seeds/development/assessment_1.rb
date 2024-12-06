# frozen_string_literal: true

assessment = PeerAssessment.new(id: '00000001-5300-4444-9999-000000000001',
  title: 'Full Peer Assessment',
  course_id: '71b53e15-31ca-4e8b-83aa-60aa8a0eea0e',
  # course_id: '00000001-3300-4444-9999-000000000001',
  item_id: 'd236a884-5fed-4c09-9438-a4be41fae492',
  # item_id: '00000003-3100-4444-9999-000000003017',
  allowed_attachments: 2,
  allowed_file_types: '.pdf, .txt, .zip, .png, .jpeg, .jpg',
  max_file_size: 6,
  # attachments: ['00000001-4000-4444-9999-000000000999', '00000001-4000-4444-9999-000000001000'],
  attachments: [],
  instructions: 'Infelix varias, illud et tuentur laboras illi adverso concussit mente haec dis
erat metallis anus Aeas est. Cinyphiumque haec Hiberis honore flammasque [me
canis ad](http://example.com/) mersit flamma, carebat vix.

Crabronum aditus! Primus cum videt, palmite cura, haec, exhausto. Placet ingens,
redde saeva. Pondere dum quod ista conditor, sit una ignesque quae tenuissima
enim. **Mea** illa illa forma, veluti Gorgone sed videt erat.

> Deae has mitia servaverat pudorem urbe iuris tempora et litore. *Dracones
> laudare* quid ova manu regno, tu me dolor.

Praeside in plangoris *pestifera*, patris alis ignibus ossa noctem invocat ab.
Laeva est [dea genitore](http://example.com/) cornibus ut amor.

Unam patuit, nec amor quoniam Alcyone paravi, Letoia parte nimis a parabat
**maduerunt** conceptaque mare. Haud nec et cupio citharae exul: Scylla auro
urnis lacusque. Dixerat horriferum ultima aequore: cepit moly quis robore,
abluit.

Intremuit et consule exclamat. Edaci te dea,
[iter](http://www.example.com/) repertis Helicen dryades. Illic nubes
verbis manu, nascitur, ni laetus. Tamen conprendere omnes letum alii nec
Placatus arma adfata elususque. Puerile et [dura](http://example.com/)!

[dea genitore]: http://example.com/
[dura]: http://example.com/
[harenis]: http://example.com/
[iter]: http://www.example.com/
[me canis ad]: http://example.com/
[primis]: http://www.example.com/',
  grading_hints: 'Lorem markdownum angusta, equorum tantum faciebant ignibus Acmona! Iove idem cum
manus, in illud alitibus Daedalon famae. Toto voluit refert si arma sole pedes
numero, aut. Clarus exitio in memor posuerunt oculi Iris pudorque et aequora
muros [harenis](http://example.com/), retinentibus.

Sed humano sanguis cruento percussa. Senilis odoratas
.com/) longa germanae ait. Cum suam exemplum parte
debes temptare; solent ferunt culpam *vetustas audentem*. Mihi valles blanditur
priorum. Sacerdos legitima mea, vincere nec suprema et talia, quod trepidumque
usque exiguo, tamen unde et Ismenides minimas.',
  usage_disclaimer: 'I also acknowledge the [data usage disclaimer](http://example.com/).')

assessment.attachments_will_change!
assessment.save!

### Steps ###

AssignmentSubmission.create! id: '00000002-5300-4444-9999-000000000001',
  deadline: 1.week.from_now,
  peer_assessment: assessment,
  optional: false,
  position: 1

Training.create! id: '00000002-5300-4444-9999-000000000002',
  deadline: 3.weeks.from_now,
  peer_assessment: assessment,
  optional: false,
  position: 2,
  open: false,
  required_reviews: 3

PeerGrading.create! id: '00000002-5300-4444-9999-000000000003',
  deadline: 3.weeks.from_now,
  peer_assessment: assessment,
  optional: false,
  position: 3,
  required_reviews: 3

SelfAssessment.create! id: '00000002-5300-4444-9999-000000000004',
  deadline: 3.weeks.from_now,
  peer_assessment: assessment,
  optional: false,
  position: 4

Results.create! id: '00000002-5300-4444-9999-000000000005',
  deadline: 4.weeks.from_now,
  peer_assessment: assessment,
  optional: false,
  position: 5

### Rubrics ###

rubrics = []

rubrics << Rubric.create!(peer_assessment: assessment,
  title: 'Target Group Definition',
  hints: 'Is the user(s) of the app clearly defined?',
  position: 1,
  template: false)

rubrics << Rubric.create!(peer_assessment: assessment,
  title: 'Creativity',
  hints: 'How effective were the submitted materials in telling the story of the scenario chosen?',
  position: 2,
  template: false)

rubrics << Rubric.create!(peer_assessment: assessment,
  title: 'Simplicity',
  hints: 'Does the proposed solution follow the philosophy of focusing on what’s important? ',
  position: 4,
  template: false)

### Rubric Options ###

RubricOption.create! rubric: rubrics.first,
  description: 'No, the user(s) is not defined.',
  points: 0

RubricOption.create! rubric: rubrics.first,
  description: 'Yes, the user(s) is defined BUT important user needs relevant for the app design are not highlighted.',
  points: 1

RubricOption.create! rubric: rubrics.first,
  description: 'Yes, the user is defined AND important user needs relevant for the app design are highlighted',
  points: 2

RubricOption.create! rubric: rubrics[1],
  description: 'The story of the scenario is not described at all.',
  points: 0

RubricOption.create! rubric: rubrics[1],
  description: 'The story is described but not fully consistent and/or plausible in the context presented.',
  points: 2

RubricOption.create! rubric: rubrics[1],
  description: 'The story is convincingly described in a consistent and plausible manner.',
  points: 4

RubricOption.create! rubric: rubrics[2],
  description: 'No, a clear focus on important tasks and outcomes is missing.',
  points: 0

RubricOption.create! rubric: rubrics[2],
  description: 'Somewhat, there is a focus on important tasks valuable for the scenario but there are still features related to less important tasks in the app.',
  points: 2

RubricOption.create! rubric: rubrics[2],
  description: 'Yes, there is a clear focus on those tasks and outcomes that are most valuable for the scenario.',
  points: 4

# Simply create a participant object for each seeded user

50.times do |i|
  user_id = format('00000001-3100-4444-9999-0000000%05d', i + 100) # We need deterministic ids to seed other services (file)
  # user_ids << user_id

  participant = Participant.new user_id:, peer_assessment_id: assessment.id
  participant.save
end
