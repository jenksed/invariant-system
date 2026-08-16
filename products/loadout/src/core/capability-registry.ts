/**
 * Capability registry.
 *
 * Resolves a Capability id to its contract and skill. The skill carries
 * the QMR fixture path; the contract carries the stable version.
 */
import { promises as fs } from 'node:fs';
import path from 'node:path';
import type { CapabilityContract } from './capability-contract';
import { parseCapabilityContract } from './capability-contract';
import type { SkillDescriptor } from './skill';
import { loadSkillDescriptor } from './skill';

export interface ResolvedCapability {
  contract: CapabilityContract;
  skill: SkillDescriptor;
  capabilityJsonPath: string;
  skillJsonPath: string;
}

export async function resolveCapability(packRoot: string): Promise<ResolvedCapability> {
  const capabilityJsonPath = path.join(packRoot, 'capability.json');
  const skillJsonPath = path.join(packRoot, 'skill.json');
  const [capRaw, skill] = await Promise.all([
    fs.readFile(capabilityJsonPath, 'utf8'),
    loadSkillDescriptor(skillJsonPath)
  ]);
  const contract = parseCapabilityContract(JSON.parse(capRaw));
  return { contract, skill, capabilityJsonPath, skillJsonPath };
}
