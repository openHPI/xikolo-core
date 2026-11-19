import { turboReady } from '../util/ready';

turboReady(() => {
  const cloneButton =
    document.querySelector<HTMLInputElement>('#clone_course_btn');
  if (!cloneButton) return;

  cloneButton.addEventListener('click', () => {
    const courseCodeInput =
      document.querySelector<HTMLInputElement>('#new_course_code')!;

    if (courseCodeInput.classList.contains('hide')) {
      courseCodeInput.classList.remove('hide');
    } else {
      document.querySelector<HTMLFormElement>('#clone_course_form')!.submit();
    }
  });
});
