/**
 * Temper Workbench Alpha — screen contract.
 *
 * A Screen is a pure projection of (State, Input) → Frame. The runtime
 * owns the render loop, keypress dispatch, and lifecycle; the screen
 * owns its state and view.
 *
 * Authority rule: a screen never owns a workflow boolean (no
 * approved=true, verified=true, complete=true). It only renders state
 * the WorkbenchConnection has fetched from Kiln.
 */

import type { Frame } from './frame.js';

/** A key the operator pressed. Modeled explicitly so screens do not parse raw bytes. */
export type Key =
  | { kind: 'char'; value: string }
  | { kind: 'enter' }
  | { kind: 'escape' }
  | { kind: 'tab' }
  | { kind: 'backspace' }
  | { kind: 'up' }
  | { kind: 'down' }
  | { kind: 'left' }
  | { kind: 'right' }
  | { kind: 'page_up' }
  | { kind: 'page_down' }
  | { kind: 'home' }
  | { kind: 'end' }
  | { kind: 'ctrl'; value: string }
  | { kind: 'resize'; cols: number; rows: number }
  | { kind: 'paste'; value: string };

/** A message a screen can emit back to the runtime. */
export type ScreenMsg =
  | { kind: 'push'; screen: ScreenSpec }
  | { kind: 'pop' }
  | { kind: 'replace'; screen: ScreenSpec }
  | { kind: 'quit' }
  | { kind: 'submit'; value: string }
  | { kind: 'request_focus'; focus: FocusTarget }
  | { kind: 'no_op' };

export type FocusTarget = 'input' | 'work' | 'changes' | 'state' | 'palette';

export interface ScreenContext {
  cols: number;
  rows: number;
  /** Whether the input box currently has focus. */
  inputFocused: boolean;
}

/** A screen is an immutable description of a renderable state. */
export interface ScreenSpec {
  readonly id: string;
  readonly title: string;
  /** Render the screen to a Frame. Pure function of state + context. */
  readonly view: (state: unknown, ctx: ScreenContext) => Frame;
  /** Update the screen's state given a key press. Returns the new state and any emitted messages. */
  readonly update: (state: unknown, key: Key, ctx: ScreenContext) => { state: unknown; msgs: ScreenMsg[] };
  /** Initial state. */
  readonly init: () => unknown;
  /** Whether the screen is an overlay (rendered on top of the previous screen). */
  readonly overlay?: boolean;
}
