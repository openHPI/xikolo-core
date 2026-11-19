type VoteFormFields = 'votable_id';

const appendVoteFormData = (
  data: FormData,
  key: VoteFormFields,
  value: string,
) => {
  data.append(key, value);
};

type AnswerFields = 'accepted_answer_id' | 'course_id';

const appendAnswerFormData = (
  data: FormData,
  key: AnswerFields,
  value: string,
) => {
  data.append(key, value);
};

export { appendVoteFormData, appendAnswerFormData };
