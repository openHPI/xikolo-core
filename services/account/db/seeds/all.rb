# frozen_string_literal: true

# == Custom Fields

CustomField.seed! name: 'gender',
  title: 'Gender',
  type: 'CustomSelectField',
  context: 'user',
  values: %w[not_set male female other],
  default_values: ['not_set']

CustomField.seed! name: 'show_birthdate_on_records',
  title: 'Show birthdate on records',
  type: 'CustomSelectField',
  context: 'user',
  values: %w[false true],
  default_values: ['true']

CustomField.seed! name: 'affiliation',
  title: 'Affiliation',
  type: 'CustomTextField',
  context: 'user'

CustomSelectField.seed! name: 'career_status',
  title: 'Career Status',
  values: %w[none student professional academic_researcher teacher other],
  default_values: ['none'],
  context: 'user'

CustomSelectField.seed! name: 'highest_degree',
  title: 'Highest Degree',
  values: %w[none high_student bachelor master diplom magister phd other],
  default_values: ['none'],
  context: 'user'

CustomSelectField.seed! name: 'background_it',
  title: 'Background in IT',
  values: %w[none beginner advanced expert],
  default_values: ['none'],
  context: 'user'

CustomSelectField.seed! name: 'professional_life',
  title: 'Professional Life',
  values: %w[none up_to_5_years up_to_10_years more_than_10_years],
  default_values: ['none'],
  context: 'user'

CustomSelectField.seed! name: 'position',
  title: 'Position',
  values: %w[none intern technician project_manager team_leader department_head],
  default_values: ['none'],
  context: 'user'

CustomSelectField.seed! name: 'country',
  title: 'Country',
  context: 'user',
  values: %w[not_set ad ae af ag ai al am an ao aq ar as at au aw ax az ba bb bd be bf bg bh bi bj bl bm bn bo br bs bt bv bw by bz ca cc cd cf cg ch ci ck cl cm cn co cr cs cu cv cx cy cz de dj dk dm do dz ec ee eg eh er es et fi fj fk fm fo fr ga gb gd ge gf gg gh gi gl gm gn gp gq gr gs gt gu gw gy hk hm hn hr ht hu id ie il im in io iq ir is it je jm jo jp ke kg kh ki km kn kp kr kw ky kz la lb lc li lk lr ls lt lu lv ly ma mc md me mf mg mh mk ml mm mn mo mp mq mr ms mt mu mv mw mx my mz na nc ne nf ng ni nl no np nr nu nz om pa pe pf pg ph pk pl pm pn pr ps pt pw py qa re ro rs ru rw sa sb sc sd se sg sh si sj sk sl sm sn so sr st sv sy sz tc td tf tg th tj tk tl tm tn to tr tt tv tw tz ua ug um us uy uz va vc ve vg vi vn vu wf ws ye yt za zm zw zz],
  default_values: %w[not_set]

CustomField.seed! name: 'city',
  title: 'City',
  type: 'CustomTextField',
  context: 'user'
