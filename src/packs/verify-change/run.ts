import { buildVerificationChange } from '../../core/verification';

/**
 * Producer-side planning procedure. It observes a change and returns the
 * immutable verification projection that is embedded in the Plan. Kiln does
 * not import or invoke this module; it consumes the frozen boundary data.
 */
export async function runVerifyChange(repository: string) {
  return buildVerificationChange({ repository });
}
