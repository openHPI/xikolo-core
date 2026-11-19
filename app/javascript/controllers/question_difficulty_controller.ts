import { Controller } from '@hotwired/stimulus';

const pointsByDifficulty = {
  easy: 1,
  mid: 2,
  hard: 3,
};

type Difficulty = 'easy' | 'mid' | 'hard' | 'not_defined';

/**
 * Find the difficulty key by its points value
 */
const difficultyForPoints = (points: string): Difficulty => {
  for (const [difficulty, difficultyPoints] of Object.entries(
    pointsByDifficulty,
  )) {
    if (difficultyPoints === Number(points)) {
      return difficulty as Difficulty;
    }
  }

  return 'not_defined';
};

/**
 * Only active inside exams, where the question pool is always on. Maps the
 * difficulty picker to the (read-only) points field. Outside exams the
 * difficulty picker is absent so the controller no-ops.
 *
 * The difficulty select is looked up directly (rather than via a Stimulus
 * target) because it is only rendered for exams; Stimulus has no notion of an
 * "optional" target, so a missing one would make a required target throw.
 */
export default class extends Controller {
  static targets = ['points'];

  declare readonly pointsTarget: HTMLInputElement;

  private get difficultySelect(): HTMLSelectElement | null {
    return this.element.querySelector<HTMLSelectElement>(
      '[data-question-difficulty-target="difficulty"]',
    );
  }

  connect() {
    const difficulty = this.difficultySelect;
    if (!difficulty) return;

    difficulty.value = difficultyForPoints(this.pointsTarget.value);
    this.updatePoints();
  }

  updatePoints() {
    const difficulty = this.difficultySelect;
    if (!difficulty) return;

    const points = pointsByDifficulty[difficulty.value];

    if (points === undefined) {
      this.pointsTarget.readOnly = false;
      return;
    }

    this.pointsTarget.value = points.toString();
    this.pointsTarget.readOnly = true;
  }
}
