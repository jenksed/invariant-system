/**
 * Skill = the swappable part of a Capability.
 *
 * Power users may inspect or replace a Skill while the Capability contract
 * stays stable. Skills declare their Qualified Method Record provenance.
 */
import { promises as fs } from 'node:fs';
import path from 'node:path';
import yaml from 'yaml';
import type { QualifiedMethodRecordV0 } from './schemas';
import { QualifiedMethodRecordV0Schema } from './schemas';

export interface SkillDescriptor {
  id: string;
  qmrFixturePath: string;
  procedureEntry: string;
}

export async function loadQmrFixture(
  fixturePath: string,
  repoRoot: string
): Promise<QualifiedMethodRecordV0> {
  const resolved = path.isAbsolute(fixturePath) ? fixturePath : path.join(repoRoot, fixturePath);
  const raw = await fs.readFile(resolved, 'utf8');
  const parsed = yaml.parse(raw);
  return QualifiedMethodRecordV0Schema.parse(parsed);
}

export async function loadSkillDescriptor(skillJsonPath: string): Promise<SkillDescriptor> {
  const raw = await fs.readFile(skillJsonPath, 'utf8');
  const obj = JSON.parse(raw) as SkillDescriptor;
  if (!obj.id || !obj.qmrFixturePath || !obj.procedureEntry) {
    throw new Error(`Invalid skill descriptor at ${skillJsonPath}`);
  }
  return obj;
}
