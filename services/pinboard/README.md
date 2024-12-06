# Pinboard Service

## Stats für learning room pinboard

im learning room

```ruby
irb(main):002:0>  LearningRoom.where(course_id: 'f0004a80-90b6-48aa-ae41-d5fbf8da78c8').pluck(:id)
```

hier im Service

```ruby
irb(main):002:0> Question.where(learning_room_id: learningrooms).count(:all)
=> 893
question_ids = Question.where(learning_room_id: learningrooms).pluck(:id)
irb(main):010:0>  Answer.where(question_id: question_ids ).count(:all)
=> 147
answer_ids =  Answer.where(question_id: question_ids).pluck(:id)
irb(main):014:0> Comment.where(commentable_id: answer_ids).count(:all)
=> 143
irb(main):015:0> Comment.where(commentable_id: question_ids).count(:all)
=> 125
```
