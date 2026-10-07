/// The current composition contains preview-only session/dispatch adapters.
const driverProductionRequested = bool.fromEnvironment(
  'MOVERA_PRODUCTION',
  defaultValue: false,
);
void validateDriverComposition({required bool production}) {
  if (production) {
    throw StateError(
      'Production Driver composition is unavailable: configure and verify real session, dispatch, realtime and routing adapters first.',
    );
  }
}
