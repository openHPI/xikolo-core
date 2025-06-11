import ready from '../../util/ready';

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
});
