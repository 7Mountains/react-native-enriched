#pragma once
#include <ReactNativeEnriched/EnrichedTextInputViewState.h>
#include <jsi/jsi.h>
#include <react/renderer/components/RNEnrichedTextInputViewSpec/EventEmitters.h>
#include <react/renderer/components/RNEnrichedTextInputViewSpec/Props.h>
#include <react/renderer/components/view/ConcreteViewShadowNode.h>
#include <react/renderer/core/LayoutConstraints.h>

#import <UIKit/UIKit.h>

namespace facebook::react {

JSI_EXPORT extern const char EnrichedTextInputViewComponentName[];

/*
 * `ShadowNode` for <EnrichedTextInputView> component.
 */
class EnrichedTextInputViewShadowNode
    : public ConcreteViewShadowNode<
          EnrichedTextInputViewComponentName, EnrichedTextInputViewProps,
          EnrichedTextInputViewEventEmitter, EnrichedTextInputViewState> {

public:
  using ConcreteViewShadowNode::ConcreteViewShadowNode;

  EnrichedTextInputViewShadowNode(const ShadowNodeFragment &fragment,
                                  const ShadowNodeFamily::Shared &family,
                                  ShadowNodeTraits traits);
  EnrichedTextInputViewShadowNode(const ShadowNode &sourceShadowNode,
                                  const ShadowNodeFragment &fragment);
  void dirtyLayoutIfNeeded();

  Size
  measureContent(const LayoutContext &layoutContext,
                 const LayoutConstraints &layoutConstraints) const override;

  static ShadowNodeTraits BaseTraits() {
    auto traits = ConcreteViewShadowNode::BaseTraits();
    traits.set(ShadowNodeTraits::Trait::LeafYogaNode);
    traits.set(ShadowNodeTraits::Trait::MeasurableYogaNode);
    return traits;
  }

private:
  NSAttributedString *getAttributedString() const;
  void createTextStorage() const;
  mutable NSTextStorage *textStorage_ = nil;
  mutable NSLayoutManager *layoutManager_ = nil;
  mutable NSTextContainer *textContainer_ = nil;
  mutable NSAttributedString *prevAttributedText_ = nil;
};

} // namespace facebook::react
