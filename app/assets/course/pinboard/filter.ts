import { TomInput } from 'tom-select/dist/types/types';

import handleError from '../../util/error';
import ready from '../../util/ready';
import fetch from '../../util/fetch';

async function getTagName(id: string) {
  let name;

  try {
    const response = await fetch(
      `/api/v2/pinboard_tags?course=${gon.course_id}`,
    );
    const xmlString = await response.text();
    const tags = JSON.parse(xmlString).pinboard_tags;

    const tag = tags.find((t: { id: string }) => t.id === id);
    name = tag.name;
  } catch (error) {
    name = 'Internal tag';
    handleError(undefined, error, false);
  }
  return name;
}

const removeTagFromUrlSearchParams = (url: URL, id: string) =>
  url.searchParams.delete('tags[]', id);
const addTagToUrlSearchParams = (url: URL, id: string) =>
  url.searchParams.append('tags[]', id);

const handleTagClick = (url: URL, id: string, filteredIds: string[]) => {
  const tagIsAlreadyInFilter: boolean = filteredIds.includes(id);

  if (tagIsAlreadyInFilter) {
    removeTagFromUrlSearchParams(url, id);
  } else {
    addTagToUrlSearchParams(url, id);
  }

  window.location.href = url.href;
};

ready(() => {
  const topicsList = document.querySelector('#pinboard__content');
  if (!topicsList) return;

  const url = new URL(window.location.href);
  const filteredTags = url.searchParams.getAll('tags[]');

  topicsList.addEventListener('click', (e) => {
    const target = e.target as HTMLElement;
    const clickedTagId = target.dataset.tagId;

    if (clickedTagId) {
      handleTagClick(url, clickedTagId, filteredTags);
    }
  });

  const tagsSelect =
    document.querySelector<TomInput>('[name="tags[]"]')?.tomselect;
  filteredTags.forEach(async (tagId) => {
    // The options from the tag select element only include explicit tags. If the clicked tag is
    // not an option we need to manually add it so it appears in the filter.
    if (!Object.hasOwnProperty.call(tagsSelect!.options, tagId)) {
      const name = await getTagName(tagId);

      tagsSelect?.addOption({ text: name, value: tagId });
      tagsSelect?.addItem(tagId, true);
    }
  });
});
