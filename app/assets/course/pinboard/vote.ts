import ready from '../../util/ready';
import fetch from '../../util/fetch';
import triggerTrackEvent from '../../util/track-event';
import handleError from '../../util/error';
import { appendVoteFormData } from './util';
import I18n from '../../i18n/i18n';

type VoteResponseData = {
  response: 'success' | 'server error' | 'already voted';
  votable_type: string;
  votable_id: string;
  votes_sum: string;
};

const setVotesText = (selector: string, text: string) => {
  const element = document.querySelector(selector);
  if (element) {
    element.innerHTML = text;
  }
};

const updateVotes = (data: VoteResponseData) => {
  if (data.response === 'server error') {
    throw new Error(I18n.t('errors.server.generic_message'));
  }

  if (data.response === 'already voted') {
    handleError(I18n.t('pinboard.errors.already_voted'));
    return;
  }

  const selector = `#${data.votable_type}-${data.votable_id}-votes`;
  setVotesText(selector, data.votes_sum);
};

const upvote = async (el: HTMLElement) => {
  const { votableType } = el.dataset;
  const { votableId } = el.dataset;

  const url = `../${votableType}/${votableId}/upvote`;

  const formData = new FormData();
  appendVoteFormData(formData, 'votable_id', votableId!);

  try {
    const response = await fetch(url, {
      method: 'POST',
      body: formData,
    });

    const data = (await response.json()) as VoteResponseData;
    updateVotes(data);
  } catch (error) {
    handleError(I18n.t('errors.server.generic_message'), error);
  }

  triggerTrackEvent('clicked_upvote', votableId, votableType);
};

const downvote = async (el: HTMLElement) => {
  const { votableType } = el.dataset;
  const { votableId } = el.dataset;

  const url = `../${votableType}/${votableId}/downvote`;

  const formData = new FormData();
  appendVoteFormData(formData, 'votable_id', votableId!);

  try {
    const response = await fetch(url, {
      method: 'POST',
      body: formData,
    });

    const data = (await response.json()) as VoteResponseData;
    updateVotes(data);
  } catch (error) {
    handleError(I18n.t('errors.server.generic_message'), error);
  }

  triggerTrackEvent('clicked_downvote', votableId, votableType);
};

ready(() => {
  document
    .querySelectorAll<HTMLElement>('.vote-box > .upvote')
    .forEach((upVoteTrigger) => {
      upVoteTrigger.addEventListener('click', () => upvote(upVoteTrigger));
    });

  document
    .querySelectorAll<HTMLElement>('.vote-box > .downvote')
    .forEach((downVoteTrigger) => {
      downVoteTrigger.addEventListener('click', () =>
        downvote(downVoteTrigger),
      );
    });
});
