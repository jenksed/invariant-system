/**
 * Capability contract.
 *
 * The Capability contract is the user-level promise. It is independent of
 * the method fixture. Swapping a compatible method fixture must not change
 * the contract (see tests/integration/fixture-substitution.spec.ts).
 */
import type { CapabilityContractV0 } from './schemas';
import { CapabilityContractV0Schema } from './schemas';

export type CapabilityContract = CapabilityContractV0;

export function parseCapabilityContract(raw: unknown): CapabilityContract {
  return CapabilityContractV0Schema.parse(raw);
}
