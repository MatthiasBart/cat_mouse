import type { JSX } from "preact/jsx-runtime";

export function renderButton(label: string, onPress: () => void): JSX.Element {
  return <button onClick={onPress}>{label}</button>;
}
