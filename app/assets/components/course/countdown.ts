import ready from '../../util/ready';

type CountdownDataset = {
  remainingSecs: string;
  submitForm: string;
};

const formatTime = (seconds: number, formatWithHours: boolean) => {
  const date = new Date(seconds * 1000).toISOString();
  const formattedTime = formatWithHours
    ? date.slice(11, 19)
    : date.slice(14, 19);
  return formattedTime;
};

const setBarColor = (timePercentage: number, bar: HTMLElement) => {
  if (timePercentage >= 90) {
    bar.classList.add('countdown__time--red');
  } else if (timePercentage > 75) {
    bar.classList.add('countdown__time--yellow');
  } else {
    bar.classList.add('countdown__time--green');
  }
};

const setProgressBar = (
  remainingSecs: number,
  totalSecs: number,
  bar: HTMLElement,
) => {
  const timePercentage = ((totalSecs - remainingSecs) * 100) / totalSecs;

  // eslint-disable-next-line no-param-reassign
  bar.style.width = `${timePercentage}%`;
  setBarColor(timePercentage, bar);
};

const startTimer = (
  remainingSecs: number,
  totalSecs: number,
  label: HTMLElement,
  bar: HTMLElement,
  formSelector?: string,
) => {
  if (remainingSecs <= 0) return;

  let timePassed = totalSecs - remainingSecs;
  let timeLeft = remainingSecs;
  const formatWithHours = totalSecs >= 3600;

  const timerInterval = setInterval(() => {
    timePassed += 1;
    timeLeft = totalSecs - timePassed;

    // eslint-disable-next-line no-param-reassign
    label.innerHTML = formatTime(timeLeft, formatWithHours);

    setProgressBar(timeLeft, totalSecs, bar);

    if (timeLeft <= 0) {
      clearInterval(timerInterval);
      if (formSelector) {
        const form = document.querySelector<HTMLFormElement>(formSelector);
        form?.requestSubmit();
      }
    }
  }, 1000);
};

ready(() => {
  const countdownComponents = document.querySelectorAll<HTMLElement>(
    '[data-remaining-secs]',
  );

  countdownComponents.forEach((countdownComponent) => {
    const { remainingSecs, submitForm } =
      countdownComponent.dataset as CountdownDataset;
    let { totalSecs } = countdownComponent.dataset;
    totalSecs = totalSecs || remainingSecs;

    const timerBar = countdownComponent.querySelector(
      '[data-time-bar]',
    ) as HTMLElement;
    const timerLabel = countdownComponent.querySelector(
      '[data-time-label]',
    ) as HTMLElement;

    setProgressBar(+remainingSecs, +totalSecs, timerBar);
    startTimer(+remainingSecs, +totalSecs, timerLabel, timerBar, submitForm);
  });
});
