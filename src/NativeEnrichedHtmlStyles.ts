import { TurboModuleRegistry, type TurboModule } from 'react-native';

export interface Spec extends TurboModule {
  /**
   * Registers a normalized html style, shared by the texts showing it
   *
   * @param style - The normalized style (see `normalizeHtmlStyle`)
   * @returns The id the texts pass instead of the style
   */
  registerHtmlStyle(style: Object): number;
}

// Not on the platforms without the native component
export default TurboModuleRegistry.get<Spec>('EnrichedHtmlStyles');
