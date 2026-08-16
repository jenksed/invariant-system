/**
 * Goal catalogue.
 *
 * A Goal is what the user wants to accomplish. Loadout owns the mapping
 * from Goal -> Capability. Only one Goal exists in LOD-01.
 */
export interface Goal {
  id: string;
  title: string;
  successConditions: string[];
  capabilityId: string;
}

export const GOAL_CATALOGUE: ReadonlyArray<Goal> = [
  {
    id: 'understand-a-repository',
    title: 'Understand this repository',
    successConditions: ['report architecture anchors', 'report observed constraints and unknowns'],
    capabilityId: 'repository-recon'
  },
  {
    id: 'verify-this-change',
    title: 'Verify this change',
    successConditions: [
      'bind verification to the exact observed change',
      'show affected surfaces, claims at risk, proof obligations, selected and skipped verification',
      'report READY only when every required obligation has durable satisfying Evidence'
    ],
    capabilityId: 'verify-change'
  }
];

export function findGoalByTitle(title: string): Goal | undefined {
  return GOAL_CATALOGUE.find((g) => g.title.toLowerCase() === title.toLowerCase());
}

export function findGoalById(id: string): Goal | undefined {
  return GOAL_CATALOGUE.find((g) => g.id === id);
}
