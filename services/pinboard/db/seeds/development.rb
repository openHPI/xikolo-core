# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
#

sql_tag = ExplicitTag.create(
  name: 'SQL',
  id: '00000001-3500-4444-9999-000000000001',
  course_id: '00000001-3300-4444-9999-000000000001'
)

db_tag = ExplicitTag.create(
  name: 'Databases',
  id: '00000001-3500-4444-9999-000000000002',
  course_id: '00000001-3300-4444-9999-000000000001'
)

homework_tag = ExplicitTag.create(
  name: 'Hausaufgaben',
  id: '00000001-3500-4444-9999-000000000003',
  course_id: '00000001-3300-4444-9999-000000000001'
)

http_tag = ExplicitTag.create(
  id: '00000001-3500-4444-9999-000000000004',
  name: 'HTTP',
  course_id: '00000001-3300-4444-9999-000000000002'
)

browser_tag = ExplicitTag.create(
  id: '00000001-3500-4444-9999-000000000005',
  name: 'Browser',
  course_id: '00000001-3300-4444-9999-000000000002'
)

german_homework_tag = ExplicitTag.create(
  id: '00000001-3500-4444-9999-000000000006',
  name: 'Hausaufgaben',
  course_id: '00000001-3300-4444-9999-000000000002'
)

rendering_tag = ExplicitTag.create(
  id: '00000001-3500-4444-9999-000000000007',
  name: 'Rendering',
  course_id: '00000001-3300-4444-9999-000000000002'
)

html_tag = ExplicitTag.create(
  id: '00000001-3500-4444-9999-000000000008',
  name: 'HTML',
  course_id: '00000001-3300-4444-9999-000000000002'
)

languages_tag = ExplicitTag.create(
  id: '00000001-3500-4444-9999-000000000009',
  name: 'Programmiersprachen',
  course_id: '00000001-3300-4444-9999-000000000002'
)

ImplicitTag.create(
  id: '00000001-3500-4444-9999-000000000010',
  name: '00000002-3100-4444-9999-000000000001',
  course_id: '00000001-3300-4444-9999-000000000001',
  referenced_resource: 'Xikolo::Course::Section'
)

ImplicitTag.create(
  id: '00000001-3500-4444-9999-000000000011',
  name: '00000002-3100-4444-9999-000000000002',
  course_id: '00000001-3300-4444-9999-000000000001',
  referenced_resource: 'Xikolo::Course::Section'
)

ImplicitTag.create(
  id: '00000001-3500-4444-9999-000000000012',
  name: '00000002-3100-4444-9999-000000000003',
  course_id: '00000001-3300-4444-9999-000000000001',
  referenced_resource: 'Xikolo::Course::Section'
)

ImplicitTag.create(
  id: '00000001-3500-4444-9999-000000000013',
  name: '00000002-3100-4444-9999-000000000004',
  course_id: '00000001-3300-4444-9999-000000000001',
  referenced_resource: 'Xikolo::Course::Section'
)

ImplicitTag.create(
  id: '00000001-3500-4444-9999-000000000014',
  name: '00000002-3100-4444-9999-000000000005',
  course_id: '00000001-3300-4444-9999-000000000001',
  referenced_resource: 'Xikolo::Course::Section'
)

ImplicitTag.create(
  id: '00000001-3500-4444-9999-000000000015',
  name: '00000002-3100-4444-9999-000000000006',
  course_id: '00000001-3300-4444-9999-000000000001',
  referenced_resource: 'Xikolo::Course::Section'
)

implicit_section_tag = ImplicitTag.create(
  id: '00000001-3500-4444-9999-000000000016',
  name: '00000002-3100-4444-9999-000000000007',
  course_id: '00000001-3300-4444-9999-000000000002',
  referenced_resource: 'Xikolo::Course::Section'
)

ImplicitTag.create(
  id: '00000001-3500-4444-9999-000000000017',
  name: '00000002-3100-4444-9999-000000000008',
  course_id: '00000001-3300-4444-9999-000000000002'
)

ImplicitTag.create(
  id: '00000001-3500-4444-9999-000000000018',
  name: '00000003-3100-4444-9999-000000000002',
  course_id: '00000001-3300-4444-9999-000000000001',
  referenced_resource: 'Xikolo::Course::Item'
)

ImplicitTag.create(
  id: '00000001-3500-4444-9999-000000000019',
  name: '00000003-3100-4444-9999-000000000003',
  course_id: '00000001-3300-4444-9999-000000000001',
  referenced_resource: 'Xikolo::Course::Item'
)

ImplicitTag.create(
  id: '00000001-3500-4444-9999-000000000020',
  name: '00000003-3100-4444-9999-000000000007',
  course_id: '00000001-3300-4444-9999-000000000001',
  referenced_resource: 'Xikolo::Course::Item'
)

ImplicitTag.create(
  id: '00000001-3500-4444-9999-000000000022',
  name: '00000003-3100-4444-9999-000000000009',
  course_id: '00000001-3300-4444-9999-000000000002',
  referenced_resource: 'Xikolo::Course::Item'
)

ImplicitTag.create(
  id: '00000001-3500-4444-9999-000000000023',
  name: '00000003-3100-4444-9999-000000000010',
  course_id: '00000001-3300-4444-9999-000000000002',
  referenced_resource: 'Xikolo::Course::Item'
)

ImplicitTag.create(
  id: '00000001-3500-4444-9999-000000000024',
  name: '00000003-3100-4444-9999-000000000011',
  course_id: '00000001-3300-4444-9999-000000000001',
  referenced_resource: 'Xikolo::Course::Item'
)

Question.create(
  id: '00000002-3500-4444-9999-000000000000',
  title: 'Wie lang kann sowas werden?',
  text: 'Gibt es irgendwelche Begrenzungen für Threads?',
  tags: [],
  user_id: '00000001-3100-4444-9999-000000000001',
  course_id: '00000001-3300-4444-9999-000000000001',
  created_at: 8.days.ago
).tap do |question|
  # Add a bulk of questions to trigger pagination
  100.times do |c|
    question.comments.create(
      text: "Test Comment #{c}",
      user_id: '00000001-3100-4444-9999-000000000003'
    )
  end
end

Question.create(
  id: '00000002-3500-4444-9999-000000000001',
  title: 'SQL',
  text: 'Ich verstehe wirklich nicht, was dieses SQL sein soll? Wer hat das denn gebastelt und warum?',
  tags: [sql_tag],
  discussion_flag: false,
  user_id: '00000001-3100-4444-9999-000000000001',
  course_id: '00000001-3300-4444-9999-000000000001',
  created_at: 1.week.ago
).tap do |question|
  Vote.create(
    id: '00000004-3500-4444-9999-000000000001',
    votable: question,
    value: 1,
    user_id: '00000001-3100-4444-9999-000000000001'
  )

  question.answers.create(
    id: '00000003-3500-4444-9999-000000000001',
    text: 'SQL ist eine Anfragesprache für Datenbanken die mit SQL arbeiten! Mit SQL-Anfragen kann man bildlich gesprochen die Inhalte einer Datenbank beliebig gefiltert zum Vorschein bringen :-).',
    user_id: '00000001-3100-4444-9999-000000000002',
    created_at: 6.days.ago
  ).tap do |answer|
    Vote.create(
      id: '00000004-3500-4444-9999-000000000003',
      votable: answer,
      value: -1,
      user_id: '00000001-3100-4444-9999-000000000001'
    )

    answer.comments.create(
      id: '00000005-3500-4444-9999-000000000003',
      text: 'Danke für die Antwort',
      user_id: '00000001-3100-4444-9999-000000000001',
      created_at: 2.days.ago
    )
  end

  # Add a very long post
  question.answers.create(
    text: <<~END_POST.strip,
      Erlaube mir mal, einen langen Text von Wikipedia hier reinzukopieren:

      > SQL ist eine Datenbanksprache zur Definition von Datenstrukturen in relationalen Datenbanken sowie zum Bearbeiten (Einfügen, Verändern, Löschen) und Abfragen von darauf basierenden Datenbeständen.
      >
      > Die Sprache basiert auf der relationalen Algebra, ihre Syntax ist relativ einfach aufgebaut und semantisch an die englische Umgangssprache angelehnt. Ein gemeinsames Gremium von ISO und IEC standardisiert die Sprache unter Mitwirkung nationaler Normungsgremien wie ANSI oder DIN. Fast alle gängigen Datenbanksysteme unterstützen SQL – allerdings in unterschiedlichem Umfang und leicht voneinander abweichenden „Dialekten“. Durch den Einsatz von SQL strebt man die Unabhängigkeit der Anwendungen vom eingesetzten Datenbankmanagementsystem an.
      >
      > Die Bezeichnung SQL (offizielle Aussprache [ɛskjuːˈɛl], oft aber auch [ˈsiːkwəl] nach dem Vorgänger; auf deutsch auch häufig die deutsche Aussprache der Buchstaben) wird im allgemeinen Sprachgebrauch als Abkürzung für „Structured Query Language“ (auf Deutsch: "Strukturierte Abfrage-Sprache") aufgefasst, obwohl sie laut Standard ein eigenständiger Name ist. Die Bezeichnung leitet sich von dem Vorgänger SEQUEL ([ˈsiːkwəl], Structured English Query Language) ab, welche mit Beteiligung von Edgar F. Codd (IBM) in den 1970er Jahren von Donald D. Chamberlin und Raymond F. Boyce entworfen wurde. SEQUEL wurde später in SQL umbenannt, weil SEQUEL ein eingetragenes Warenzeichen der Hawker Siddeley Aircraft Company ist.
    END_POST
    user_id: '00000001-3100-4444-9999-000000000002',
    created_at: 5.days.ago
  ).tap do |answer|
    # And an even longer one
    answer.comments.create(
      text: <<~END_POST.strip,
        Na herzlichen Dank. Wikipedia kopieren kann ich auch selbst, sogar noch umfangreicher:

        Erläuterung:

            DISTINCT gibt an, dass aus der Ergebnisrelation gleiche Ergebnistupel entfernt werden sollen. Es wird also jeder Datensatz nur einmal ausgegeben, auch wenn er mehrfach in der Tabelle vorkommt. Sonst liefert SQL eine Multimenge zurück.
            Auswahlliste bestimmt, welche Spalten der Quelle auszugeben sind ( * für alle) und ob Aggregatfunktionen anzuwenden sind. Wie bei allen anderen Aufzählungen werden die einzelnen Elemente mit Komma voneinander getrennt.
            Quelle gibt an, wo die Daten herkommen. Es können Relationen und Sichten angegeben werden und miteinander als kartesisches Produkt oder als Verbund (JOIN, ab SQL-92) verknüpft werden. Mit der zusätzlichen Angabe eines Namens können Tupelvariablen besetzt werden, also Relationen für die Abfrage umbenannt werden (vgl. Beispiele).
            Where-Klausel bestimmt Bedingungen, auch Filter genannt, unter denen die Daten ausgegeben werden sollen. In SQL ist hier auch die Angabe von Unterabfragen möglich, so dass SQL streng relational vollständig wird.
            Group-by-Attribut legt fest, ob unterschiedliche Werte als einzelne Zeilen ausgegeben werden sollen (GROUP BY = Gruppierung) oder aber die Feldwerte der Zeilen durch Aggregationen wie Addition (SUM), Durchschnitt (AVG), Minimum (MIN), Maximum (MAX) zu einem Ergebniswert zusammengefasst werden, der sich auf die Gruppierung bezieht.
            Having-Klausel ist wie die Where-Klausel, nur dass sich die angegebene Bedingung auf das Ergebnis einer Aggregationsfunktion bezieht, zum Beispiel HAVING SUM (Betrag) > 0.
            Sortierungsattribut: nach ORDER BY werden Attribute angegeben, nach denen sortiert werden soll. Die Standardvoreinstellung ist ASC, das bedeutet aufsteigende Sortierung, DESC ist absteigende Sortierung.

        Mengenoperatoren können auf mehrere SELECT-Abfragen angewandt werden, die gleich viele Attribute haben und bei denen die Datentypen der Attribute übereinstimmen:

            UNION vereinigt die Ergebnismengen. In einigen Implementierungen werden mehrfach vorkommende Ergebnistupel wie bei DISTINCT entfernt, ohne dass „UNION DISTINCT“ geschrieben werden muss bzw. darf.
            UNION ALL vereinigt die Ergebnismengen. Mehrfach vorkommende Ergebnistupel bleiben erhalten. Einige Implementierungen interpretieren aber „UNION“ wie „UNION ALL“ und verstehen das „ALL“ möglicherweise nicht und geben eine Fehlermeldung aus.
            EXCEPT liefert die Tupel, die in einer ersten, jedoch nicht in einer zweiten Ergebnismenge enthalten sind. Mehrfach vorkommende Ergebnistupel werden entfernt.
            MINUS ist ein analoger Operator wie EXCEPT, der von manchen SQL-Dialekten alternativ benutzt wird.
            INTERSECT liefert die Schnittmenge zweier Ergebnismengen. Mehrfach vorkommende Ergebnistupel werden entfernt.

        #### Schlüssel

        Während die Informationen auf viele Tabellen verteilt werden müssen, um Redundanzen zu vermeiden, sind Schlüssel das Mittel, um diese verstreuten Informationen miteinander zu verknüpfen.

        So hat in der Regel jeder Datensatz eine eindeutige Nummer oder ein anderes eindeutiges Feld, um ihn zu identifizieren. Diese Identifikationen werden als Schlüssel bezeichnet.

        Wenn dieser Datensatz in anderen Zusammenhängen benötigt wird, wird lediglich sein Schlüssel angegeben. So werden bei der Erfassung von Vorlesungsteilnehmern nicht deren Namen und Adressen, sondern nur deren jeweilige Matrikelnummer erfasst, aus der sich alle weiteren Personalien ergeben.

        So kann es sein, dass manche Datensätze nur aus Schlüsseln (meist Zahlen) bestehen, die erst in Verbindung mit Verknüpfungen verständlich werden. Der eigene Schlüssel des Datensatzes wird dabei als Primärschlüssel bezeichnet. Andere Schlüssel im Datensatz, die auf die Primärschlüssel anderer Tabellen verweisen, werden als Fremdschlüssel bezeichnet.

        Schlüssel können auch aus einer Kombination mehrerer Angaben bestehen. Z. B. können die Teilnehmer einer Vorlesung durch die eindeutige Kombination von Vorlesungsnummer und Studentennummer identifiziert werden, so dass die doppelte Anmeldung eines Studenten zu einer Vorlesung ausgeschlossen ist.

        #### Referenzielle Integrität

        Referenzielle Integrität bedeutet, dass Datensätze, die von anderen Datensätzen verwendet werden, in der Datenbank auch vollständig vorhanden sind.

        > Im obigen Beispiel bedeutet dies, dass in der Teilnehmertabelle nur Matrikel-Nummern gespeichert sind, die es in der Studenten-Tabelle auch tatsächlich gibt.

        Diese wichtige Funktionalität kann (und sollte) bereits von der Datenbank überwacht werden, so dass z. B.

        * nur vorhandene Matrikelnummern in die Teilnehmertabelle eingetragen werden können,
        * der Versuch, den Datensatz eines Studenten, der schon eine Vorlesung belegt hat, zu löschen, entweder verhindert wird (Fehlermeldung) oder der Datensatz auch gleich aus der Teilnehmertabelle entfernt wird (Löschweitergabe) und
        * der Versuch, die Matrikelnummer eines Studenten, der schon eine Vorlesung belegt hat, zu ändern, entweder verhindert wird (Fehlermeldung) oder der Eintrag in der Teilnehmertabelle gleich mitgeändert wird (Aktualisierungsweitergabe).

        Widersprüchlichkeit von Daten wird allgemein als Dateninkonsistenz bezeichnet. Diese besteht, wenn Daten bspw. die Integritätsbedingungen (z. B. Constraints oder Fremdschlüsselbeziehungen) nicht erfüllen.

        Ursachen für Dateninkonsistenzen können Fehler bei der Analyse des Datenmodells, fehlende Normalisierung des ERM oder Fehler in der Programmierung sein.

        Zum letzteren gehören die Lost-Update-Phänomene sowie die Verarbeitung von zwischenzeitlich veralteten Zwischenergebnissen. Dies tritt vor allem bei der Online-Verarbeitung auf, da dem Nutzer angezeigte Werte nicht in einer Transaktion gekapselt werden können.
      END_POST
      user_id: '00000001-3100-4444-9999-000000000001',
      created_at: 1.day.ago
    )
  end

  question.answers.create(
    text: 'Bitte kein SPAM!!!',
    user_id: '00000001-3100-4444-9999-000000000003',
    created_at: 4.days.ago
  )

  question.answers.create(
    id: '00000005-3500-4444-9999-000000000002',
    text: 'Bitte stelle deine Frage etwas genauer.',
    user_id: '00000001-3100-4444-9999-000000000003',
    created_at: 3.days.ago
  )

  question.answers.create(
    id: '00000005-3500-4444-9999-000000000004',
    text: 'SQL steht übrigens für Structured Query Language',
    user_id: '00000001-3100-4444-9999-000000000002',
    created_at: 1.day.ago
  ).tap do |answer|
    Vote.create(
      votable: answer,
      value: 1,
      user_id: '00000001-3100-4444-9999-000000000101'
    )
    Vote.create(
      votable: answer,
      value: 1,
      user_id: '00000001-3100-4444-9999-000000000102'
    )
    Vote.create(
      votable: answer,
      value: 1,
      user_id: '00000001-3100-4444-9999-000000000103'
    )
    Vote.create(
      votable: answer,
      value: 1,
      user_id: '00000001-3100-4444-9999-000000000104'
    )
    Vote.create(
      votable: answer,
      value: 1,
      user_id: '00000001-3100-4444-9999-000000000105'
    )
  end

  question.answers.create(
    id: '00000003-3500-4444-9999-000000000002',
    text: 'Schau einfach auf Wikipedia nach: http://en.wikipedia.org/wiki/SQL',
    user_id: '00000001-3100-4444-9999-000000000003',
    created_at: 20.hours.ago
  )

  # Add a post that is marked as answer
  question.answers.create(
    text: <<~END_POST.strip,
      Ick fasse dit mal zusammen, wa?

      SQL ist eine Datenbanksprache zur **Definition von Datenstrukturen** in relationalen Datenbanken sowie zum **Bearbeiten (Einfügen, Verändern, Löschen) und Abfragen** von darauf basierenden Datenbeständen.

      So sacht dit jedenfalls diese Wikipedia, und die hat doch ooch immer Recht, ne?
    END_POST
    user_id: '00000001-3100-4444-9999-000000000005',
    created_at: 3.hours.ago
  ).tap do |answer|
    question.update!(accepted_answer_id: answer.id)
  end

  question.subscriptions.create(
    user_id: '00000001-3100-4444-9999-000000000001'
  )
end

Question.create(
  id: '00000002-3500-4444-9999-000000000002',
  title: 'Was ist SQL?',
  text: 'Ist SQL die Anfragesprache für alle Datenbanken auf dieser Welt?',
  tags: [sql_tag, db_tag],
  user_id: '00000001-3100-4444-9999-000000000001',
  course_id: '00000001-3300-4444-9999-000000000001',
  created_at: 3.days.ago
).tap do |question|
  Vote.create(
    id: '00000004-3500-4444-9999-000000000002',
    votable: question,
    value: 1,
    user_id: '00000001-3100-4444-9999-000000000001'
  )

  question.comments.create(
    id: '00000005-3500-4444-9999-000000000001',
    text: 'Google ist dein Freund!',
    user_id: '00000001-3100-4444-9999-000000000002'
  )
end

Question.create(
  id: '00000002-3500-4444-9999-000000000003',
  title: 'Frage zur aktuellen Hausaufgabe',
  text: 'Was haben denn in der Hausaufgabe die SQL statements zu bedeuten? Ist da ein Fehler drin? Ich schaffe es außerdem nicht die Datenbank aufzusetzen, wo bekomme ich da Hilfe?',
  tags: [sql_tag, db_tag, homework_tag],
  user_id: '00000001-3100-4444-9999-000000000002',
  course_id: '00000001-3300-4444-9999-000000000001',
  created_at: 1.day.ago
).tap do |question|
  question.answers.create(
    id: '00000003-3500-4444-9999-000000000003',
    text: 'Nein, da ist kein Fehler drin, die SQL statements sollst du ausführen und die Ergebnisse in einer Textdatei abgeben. Die Anleitung zum Aufsetzen der Datenbank gibts in der Kursübersicht!',
    user_id: '00000001-3100-4444-9999-000000000003'
  ).tap do |answer|
    Vote.create(
      id: '00000004-3500-4444-9999-000000000004',
      votable: answer,
      value: -1,
      user_id: '00000001-3100-4444-9999-000000000002'
    )

    Vote.create(
      id: '00000004-3500-4444-9999-000000000005',
      votable: answer,
      value: 1,
      user_id: '00000001-3100-4444-9999-000000000003'
    )
  end
end

Question.create(
  id: '00000002-3500-4444-9999-000000000004',
  title: 'Wozu HTTP?',
  text: 'Ich verstehe wirklich nicht, warum man zur Übertragung von Text extra ein neues Protokoll erfinden musste. Habe ich etwas übersehen?',
  user_id: '00000001-3100-4444-9999-000000000001',
  tags: [http_tag],
  course_id: '00000001-3300-4444-9999-000000000002',
  created_at: 3.days.ago
).tap do |question|
  question.answers.create(
    id: '00000003-3500-4444-9999-000000000004',
    text: 'HTTP macht ja sehr viel mehr als Text übertragen, schau dir mal in Ruhe diesen Artikel an: http://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol',
    user_id: '00000001-3100-4444-9999-000000000002'
  )
end

Question.create(
  id: '00000002-3500-4444-9999-000000000005',
  title: 'Was ist ein Renderer',
  text: 'Als die Funktion des Browsers erklärt wurde, viel der Begriff \'Renderer\'. Kann mir das jemand übersetzen oder erklären?',
  user_id: '00000001-3100-4444-9999-000000000001',
  tags: [browser_tag, rendering_tag, implicit_section_tag],
  course_id: '00000001-3300-4444-9999-000000000002',
  created_at: 5.days.ago
).tap do |question|
  question.answers.create(
    id: '00000003-3500-4444-9999-000000000005',
    text: 'Rendern bezeichnet die Erzeugung eines Bildes aus Rohdaten. Diese definieren ein virtuelles räumliches Modell, das Objekte und deren Materialeigenschaften, Lichtquellen, sowie die Position und Blickrichtung eines Betrachters beschreibt.',
    user_id: '00000001-3100-4444-9999-000000000003'
  )
end

Question.create(
  id: '00000002-3500-4444-9999-000000000006',
  title: 'Programmiersprache HTML',
  text: 'In der Hausaufgabe habe ich gesagt, das HTML ein Programmiersprache ist. Warum ist das falsch?',
  user_id: '00000001-3100-4444-9999-000000000002',
  tags: [german_homework_tag, html_tag, languages_tag],
  course_id: '00000001-3300-4444-9999-000000000002',
  created_at: 5.days.ago
)

# Add a bulk of questions to trigger pagination
100.times do |c|
  Question.create(
    title: "Test Question #{c}",
    text: 'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua',
    user_id: '00000001-3100-4444-9999-000000000002',
    tags: [http_tag, browser_tag, german_homework_tag, rendering_tag, html_tag, languages_tag].sample(rand(4)), # Randomly generate subset
    course_id: http_tag.course_id,
    created_at: 3.days.ago
  )
end

# Ensure tags and question course ids match
Question.find_each do |question|
  question.tags.each do |tag|
    if question.course_id != tag.course_id
      puts "!!! Question #{question.id} and tag #{tag.id} do not have the same course ID!"
    end
  end
end
